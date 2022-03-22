import { appendAsyncConstructor } from 'async-constructor'
import { Client } from 'pg'
import { Node } from '../node'
import { NodeWithInput } from './node_with_input'

/**
 * Node that takes one node as input.
 */
export abstract class Node1Input<Input1, Output> extends NodeWithInput<Output> {
    nodeInput: Node<Input1>

    /**
     * This is the implementation of the transformation made
     * on input data to produce the current node's output.
     */
    abstract process(input: Input1): Promise<Output>

    get parentPostgresClient(): Client | undefined {
        return this.nodeInput.parentPostgresClient
    }

    constructor(nodeInput: Node<Input1>) {
        super()
        this.nodeInput = nodeInput
        this.nodeId = `N1I[${nodeInput.nodeId}]`
        appendAsyncConstructor(this, async () => {
            await this.setupInputsProcessing([nodeInput])
        })
    }

    processUntyped(inputs: Array<any>): Promise<Output> {
        return this.process(inputs[0] as Input1)
    }
}
