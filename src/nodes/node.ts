import { AsyncConstructor } from 'async-constructor'
import _ from 'lodash'
import { Client } from 'pg'
import { v4 as uuidv4 } from 'uuid'
import { NodeFactory } from './node_factory'

export interface Observer<T> {
    next(value: T): void
}

export interface Subscription {
    unsubscribe(): void
}

/** 
 * A node is the main concept of sangre. Each node is a transformation
 * of data (aggregates, filter, mutates, etc.). Data flows from sources
 * (nodes that emits data by themselves) through nodes forming an acyclic
 * directed graph.
 */
@NodeFactory.factorizeClass
export class Node<Output> extends AsyncConstructor {
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

    constructor() {
        super(async () => { })
        this.nodeId = this.constructor.name
    }

    /** Helper to retrieve the first postgres `Client` in
     * parent node hierarchy.
     */
    get parentPostgresClient(): Client | undefined {
        return undefined
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
     * Closes any dependancies of this node.
     * Equivalent of class destructor.
     */
    async close() {
        if (this.isClosed)
            throw Error("Can't close node twice")
        else {
            this.isClosed = true
        }
    }

    // Utils

    /** See NodeFactory.factorizeClass */
    static compareForNew(node: Node<any>, ...args: Array<any>): boolean {
        return false
    }

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
