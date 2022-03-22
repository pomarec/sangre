import _ from 'lodash'
import { SerialExecutionQueue } from '../../utils'
import { Node, Subscription } from '../node'

/**
 * Node that ingest input data from other node(s) ouputs.
 */
export abstract class NodeWithInput<Output> extends Node<Output> {
    /** Set of subscriptions this node holds on other nodes. */
    protected inputsSubscriptions = new Set<Subscription>()

    /** 
     * Serial exectution queue of this node's transformations.
     * Makes sure every transformations is done in the same order
     * as inputs changes.
     */
    protected executionQueue = new SerialExecutionQueue()

    /**
     * Plugs input nodes and make sure this.processUntyped() is
     * called each time one of them emit new data.
     */
    protected async setupInputsProcessing(inputNodes: Array<Node<any>>) {
        var inputsLastData = new Array(inputNodes.length)
        inputsLastData.fill(undefined)
        inputNodes.forEach((node, index) =>
            this.inputsSubscriptions.add(
                node.subscribe({
                    next: (data) => {
                        inputsLastData[index] = data
                        if (_.every(inputsLastData, (e) => !_.isNil(e))) {
                            const inputs = _.clone(inputsLastData)
                            this.executionQueue.queue(
                                async () => {
                                    try {
                                        const output = await this.processUntyped(inputs)
                                        this.emit(output)
                                    } catch (e) {
                                        if (!(e instanceof NodeSkipProcess))
                                            throw e
                                    }
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
    abstract processUntyped(inputs: Array<any>): Promise<Output>

    async close() {
        if (!this.isClosed) {
            for (var subscription of this.inputsSubscriptions)
                subscription.unsubscribe()
            this.inputsSubscriptions.clear()
        }
        await super.close()
    }
}

/** 
 * Throw this exception in process() when you want to skip
 * current proccessing of inputs.
 */
export class NodeSkipProcess extends Error {
    constructor(m: string) {
        super(m)
        Object.setPrototypeOf(this, NodeSkipProcess.prototype)
    }
}
