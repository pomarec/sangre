import { AsyncConstructor } from 'async-constructor'
import _ from 'lodash'
import { v4 as uuidv4 } from 'uuid'
import { SerialExecutionQueue } from '../utils'

/** 
 * A node is the main concept of sangre. Each node is a transformation
 * of data (aggregates, filter, mutates, etc.). Data flows from sources
 * (ndes that emits data by themselves) through nodes forming an acyclic
 * directed graph.
 */
export abstract class Node<Output> extends AsyncConstructor {
    nodeId: string

    /** Stores the last value (output) emited */
    lastValue?: Output

    /** see: this.close() */
    protected isClosed = false

    /** 
     * Collection of observers who listen to data emitted
     * by this node.
     */
    private observers = new Map<string, Observer<Output>>()

    /** Set of subscriptions this node holds on other nodes. */
    private inputsSubscriptions = new Set<Subscription>()

    /** 
     * Serial exectution queue of this node's transformations.
     * Makes sure every transformations is done in the same order
     * as inputs changes.
     */
    protected executionQueue = new SerialExecutionQueue()

    constructor() {
        super(async () => { })
        this.nodeId = this.nodeBaseName
    }

    /**
     * Override this methods when you want a more readable
     * node name than its class name.
    */
    get nodeBaseName() {
        return this.constructor.name
    }

    /**
     * Registers a subscriber to this node output changes.
     * 
     * @param skipLastValue if false (and lastValue is not nil), `subsciber.next()`
     * is called with lastValue before emitting changes.
     */
    subscribe(observer: Observer<Output>, skipLastValue = false): Subscription {
        const subscriptionId = uuidv4()
        this.observers.set(subscriptionId, observer)
        const lastValue = this.lastValue
        if (!_.isNil(lastValue) && !skipLastValue)
            observer.next(lastValue)
        return {
            unsubscribe: () => {
                this.observers.delete(subscriptionId)
            }
        }
    }

    emit(value: Output) {
        this.lastValue = value
        this.observers.forEach((observer) =>
            observer.next(value)
        )
    }

    /**
     * In case of this node subscribing ot other nodes as inputs.
     * This methods plug them and make sure this.processUntyped() is
     * called each time one of its inputs emit new data.
     */
    protected async setupInputsProcessing(inputNodes: Array<Node<any>>) {
        var inputsLastData = new Array(inputNodes.length)
        inputsLastData.fill(undefined)
        inputNodes.forEach((node, index) =>
            this.inputsSubscriptions.add(
                inputNodes[index].subscribe({
                    next: (data) => {
                        inputsLastData[index] = data
                        if (_.every(inputsLastData, (e) => !_.isNil(e))) {
                            const inputs = _.clone(inputsLastData)
                            this.executionQueue.queue(
                                async () => {
                                    const output = await this.processUntyped(inputs)
                                    this.emit(output)
                                }
                            )
                        }
                    }
                })
            )
        )
    }

    /**
     * Must be overwritten if this node subscribes to other nodes.
     * @param inputs array of data emitted by nodes setup in 
     * this.setupInputsProcessing()
     */
    protected async processUntyped(inputs: Array<any>): Promise<Output> {
        throw Error("Not implemented")
    }


    /**
     * Closes any dependancies of this node.
     * 
     * Eg: closing subscriptions to input nodes.
     */
    async close() {
        if (this.isClosed)
            throw Error("Can't close node twice")
        else {
            this.isClosed = true
            for (var subscription of this.inputsSubscriptions)
                subscription.unsubscribe()
            this.inputsSubscriptions.clear()
        }
    }

    // Utils

    /** 
     * Get the next "length" values emited by this node.
     */
    take(length: number, skipCurrentValue = true): Promise<Array<Output>> {
        return new Promise((resolve) => {
            if (length == 1 && this.lastValue != undefined && !skipCurrentValue)
                resolve([this.lastValue])
            else {
                var emittedValues = new Array<Output>()
                const subscription = this.subscribe({
                    next: (data) => {
                        emittedValues.push(data)
                        if (emittedValues.length >= length) {
                            subscription.unsubscribe()
                            resolve(emittedValues)
                        }
                    }
                }, skipCurrentValue)
            }
        })
    }

    /** Shortcut to take(1) **/
    async takeValue(skipCurrentValue?: boolean): Promise<Output> {
        return (await this.take(1, skipCurrentValue))[0]
    }
}

/** 
 * Throw this exception in process() when you don't want to
 * react to the new input.
 */
export class NodeSkipProcess extends Error {
    constructor(m: string) {
        super(m)
        Object.setPrototypeOf(this, NodeSkipProcess.prototype)
    }
}

interface Observer<T> {
    next(value: T): void
}

interface Subscription {
    unsubscribe(): void
}