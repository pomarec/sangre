import { appendAsyncConstructor } from 'async-constructor'
import _ from 'lodash'
import { v4 as uuidv4 } from 'uuid'


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
    private observers = new Map<String, Observer<Output>>()
    private inputsSubscriptions = new Set<Subscription>()
    private executionQueue = new SerialExecutionQueue()

    constructor() {
        this.nodeId = this.constructor.name
    }

    subscribe(observer: Observer<Output>): Subscription {
        const subscriptionId = uuidv4()
        this.observers.set(subscriptionId, observer)
        return {
            unsubscribe: () => {
                this.observers.delete(subscriptionId)
            }
        }
    }

    unsubscribe(subscriptionId: String) {
        this.observers.delete(subscriptionId)
    }

    emit(value: Output) {
        this.value = value
        for (var [_, observer] of this.observers)
            observer.next(value)
    }

    protected async setupInputsProcessing(inputNodes: Array<Node<any>>) {
        var inputsLastData = new Array(inputNodes.length)
        for (var inputNodeIndex in inputNodes)
            this.inputsSubscriptions.add(
                inputNodes[inputNodeIndex].subscribe({
                    next: (data) => {
                        inputsLastData[inputNodeIndex] = data
                        if (_.every(inputsLastData, (e) => !_.isNull(e))) {
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
    }

    protected async processUntyped(inputs: Array<any>): Promise<Output> {
        throw Error("Not implemented")
    }

    protected async close() {
        for (var subscription of this.inputsSubscriptions)
            subscription.unsubscribe()
        this.inputsSubscriptions.clear()
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

export class SerialExecutionQueue {
    private remainingExecutions = new Array<() => Promise<void>>()
    private isUnqueing = false

    async queue(task: () => Promise<void>) {
        this.remainingExecutions.push(task)
        this.unqueue()
    }

    private async unqueue() {
        if (!this.isUnqueing && !_.isEmpty(this.remainingExecutions)) {
            this.isUnqueing = true
            const task = this.remainingExecutions.shift()
            if (task != undefined)
                await task()
            this.isUnqueing = false
            this.unqueue()
        }
    }
}

