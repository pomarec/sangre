import { appendAsyncConstructor } from 'async-constructor'
import _ from 'lodash'
import { combineLatest, merge, Observable, of, Subject, Subscription } from 'rxjs'

/// Throw this exception in process() when you don't want to
/// react to the new input.
class NodeSkipProcess extends Error {
    constructor(m: string) {
        super(m)
        Object.setPrototypeOf(this, NodeSkipProcess.prototype)
    }
}

/// Any node, especially sources, have to seed their stream with
/// at least one value before the end of init().
export abstract class Node<Output> {
    /// This should be set at initialization once and never touched then
    nodeId: string = "Uninitialized"
    readonly subject$ = new Subject<Output>();

    protected value?: Output
    private _valueSubscription?: Subscription
    get subjectWithLastValue$() {
        return _.isNil(this.value) ? this.subject$ : merge(of(this.value), this.subject$)
    }

    constructor(initialValue?: Output) {
        this.nodeId = this.constructor.name
        this._valueSubscription = this.subject$.subscribe((v) => this.value = v)
        if (!_.isNil(initialValue))
            this.subject$.next(initialValue)
    }

    async close() {
        this._valueSubscription?.unsubscribe()
        await this.subject$.complete()
    }

    protected async setupProcessing(nodes: Array<Node<any>>) {
        const output$: Observable<Output> =
            asyncMap<Array<any>, Output>(
                combineLatest(nodes.map((n) => n.subjectWithLastValue$)),
                (subjects: Array<any>): Promise<Output> => this.processUntyped.bind(this)(subjects),
            )
        output$
            // .handleError((e) { }, test: (e) => e is NodeSkipProcess)
            .subscribe((e) => {
                console.log("emitting " + e)
                this.subject$.next.bind(this.subject$)(e)
            })
        // Close this when 'stream' closes
        // Not using .pipe() allows streamController to receive other
        // events simulteanously
        // .asFuture()
        // .then((_) => close())
    }

    protected async processUntyped(inputs: Array<any>): Promise<Output> {
        throw Error("Not implemented")
    }
}

export abstract class Node1Input<I1, Output> extends Node<Output> {
    nodeI1: Node<I1>

    constructor(nodeI1: Node<I1>) {
        super()
        this.nodeI1 = nodeI1
        this.nodeId = `${this.constructor.name}[${nodeI1.nodeId}]`
        appendAsyncConstructor(this, async () => {
            this.nodeI1 = await nodeI1
            await this.setupProcessing([nodeI1])
        })
    }

    async processUntyped(inputs: Array<any>): Promise<Output> {
        return this.process(inputs[0] as I1)
    }

    async process(input: I1): Promise<Output> {
        throw Error("Not implemented")
    }
}


export abstract class Node2Input<I1, I2, Output> extends Node<Output> {
    nodeI1: Node<I1>
    nodeI2: Node<I2>

    constructor(nodeI1: Node<I1>, nodeI2: Node<I2>) {
        super()
        this.nodeI1 = nodeI1
        this.nodeI2 = nodeI2
        this.nodeId = `${this.constructor.name}[${nodeI1.nodeId}, ${nodeI2.nodeId}]`
        appendAsyncConstructor(this, async () => {
            this.nodeI1 = await nodeI1
            this.nodeI2 = await nodeI2
            await this.setupProcessing([nodeI1, nodeI2])
        })
    }

    async processUntyped(inputs: Array<any>): Promise<Output> {
        return this.process(inputs[0] as I1, inputs[1] as I2)
    }

    async process(i1: I1, i2: I2): Promise<Output> {
        throw Error("Not implemented")
    }
}

function asyncMap<I, O>(input$: Observable<I>, map: (_: I) => Promise<O>): Observable<O> {
    return new Observable<O>(function subscribe(subscriber) {
        const inputQueue = new Array<I>()
        var isUnqueing = false

        const unqueue = async () => {
            if (!isUnqueing && !_.isEmpty(inputQueue)) {
                isUnqueing = true
                const input: I = inputQueue.shift() as I
                const output = await map(input)
                subscriber.next(output)
                isUnqueing = false
                unqueue()
            }
        }

        input$.subscribe((value) => {
            inputQueue.push(value)
            unqueue()
        })
    })
}