import { appendAsyncConstructor } from 'async-constructor'
import _ from 'lodash'
import { v4 as uuidv4 } from 'uuid'
import { SerialExecutionQueue } from '../utils'

/// Throw this exception in process() when you don't want to
/// react to the new input.
class NodeSkipProcess extends Error {
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

/// Any node, especially sources, have to seed their stream with
/// at least one value before the end of init().
export abstract class Node<Output> {
    nodeId: string
    value?: Output
    protected isClosed = false
    private observers = new Map<string, Observer<Output>>()
    private inputsSubscriptions = new Set<Subscription>()
    private executionQueue = new SerialExecutionQueue()

    constructor() {
        this.nodeId = this.constructor.name
    }

    subscribe(observer: Observer<Output>, skipCurrentValue = false): Subscription {
        const subscriptionId = uuidv4()
        this.observers.set(subscriptionId, observer)
        const value = this.value
        if (!_.isNil(value) && !skipCurrentValue)
            observer.next(value)
        return {
            unsubscribe: () => {
                this.observers.delete(subscriptionId)
            }
        }
    }

    unsubscribe(subscriptionId: string) {
        this.observers.delete(subscriptionId)
    }

    emit(value: Output) {
        this.value = value
        this.observers.forEach((observer) =>
            observer.next(value)
        )
    }

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

    protected async processUntyped(inputs: Array<any>): Promise<Output> {
        throw Error("Not implemented")
    }

    protected async close() {
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

    /// Return the next "length" values emited by this node
    async take(length: number): Promise<Array<Output>> {
        return new Promise((resolve) => {
            var emittedValues = new Array<Output>()
            const subscription = this.subscribe({
                next: (data) => {
                    emittedValues.push(data)
                    if (emittedValues.length >= length) {
                        subscription.unsubscribe()
                        resolve(emittedValues)
                    }
                }
            }, true)
        })
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
            await this.setupInputsProcessing([nodeI1])
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
            await this.setupInputsProcessing([nodeI1, nodeI2])
        })
    }

    async processUntyped(inputs: Array<any>): Promise<Output> {
        return this.process(inputs[0] as I1, inputs[1] as I2)
    }

    async process(i1: I1, i2: I2): Promise<Output> {
        throw Error("Not implemented")
    }
}

export abstract class Node3Input<I1, I2, I3, Output> extends Node<Output> {
    nodeI1: Node<I1>
    nodeI2: Node<I2>
    nodeI3: Node<I3>

    constructor(nodeI1: Node<I1>, nodeI2: Node<I2>, nodeI3: Node<I3>) {
        super()
        this.nodeI1 = nodeI1
        this.nodeI2 = nodeI2
        this.nodeI3 = nodeI3
        this.nodeId = `${this.constructor.name}[${nodeI1.nodeId}, ${nodeI2.nodeId}, , ${nodeI3.nodeId}]`
        appendAsyncConstructor(this, async () => {
            this.nodeI1 = await nodeI1
            this.nodeI2 = await nodeI2
            this.nodeI3 = await nodeI3
            await this.setupInputsProcessing([nodeI1, nodeI2, nodeI3])
        })
    }

    async processUntyped(inputs: Array<any>): Promise<Output> {
        return this.process(inputs[0] as I1, inputs[1] as I2, inputs[2] as I3)
    }

    async process(i1: I1, i2: I2, i3: I3): Promise<Output> {
        throw Error("Not implemented")
    }
}



