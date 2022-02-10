import { appendAsyncConstructor } from 'async-constructor'
import _ from 'lodash'
import { BehaviorSubject, firstValueFrom, Observable, skip } from 'rxjs'
import { asyncMap } from 'rxjs-async-map'

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

    get subject(): BehaviorSubject<Output> {
        return this._subject as BehaviorSubject<Output>
    }
    _subject?: BehaviorSubject<Output>

    constructor(initialValue?: Output) {
        this.nodeId = this.constructor.name
        if (!_.isNil(initialValue))
            this._subject = new BehaviorSubject(initialValue)
    }

    async close() {
        await this.subject.complete()
    }

    protected async inject(observable: Observable<Output>) {
        const firstValue: Output = await firstValueFrom(observable)
        this._subject = new BehaviorSubject(firstValue)
        observable.pipe(skip(1))
            // .handleError((e) { }, test: (e) => e is NodeSkipProcess)
            .subscribe(this.subject.next.bind(this.subject))
        // Close this when 'stream' closes
        // Not using .pipe() allows streamController to receive other
        // events simulteanously
        // .asFuture()
        // .then((_) => close())
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
            await this.inject(
                nodeI1.subject.pipe(
                    asyncMap(this.process.bind(this), 1)
                )
            )
        })
    }

    async process(input: I1): Promise<Output> {
        throw Error("Not implemented")
    }
}