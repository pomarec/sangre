import { appendAsyncConstructor } from 'async-constructor'
import { Client } from 'pg'
import { Node } from '../node'
import { NodeWithInput } from './node_with_input'

/**
 * Node that takes two nodes as inputs.
 */
export abstract class Node2Input<Input1, Input2, Output> extends NodeWithInput<Output> {
    nodeInput1: Node<Input1>
    nodeInput2: Node<Input2>

    /**
     * This is the implementation of the transformation made
     * on input data to produce the current node's output.
     */
    abstract process(i1: Input1, i2: Input2): Promise<Output>

    get parentPostgresClient(): Client | undefined {
        return this.nodeInput1.parentPostgresClient
    }

    constructor(nodeInput1: Node<Input1>, nodeInput2: Node<Input2>) {
        super()
        this.nodeInput1 = nodeInput1
        this.nodeInput2 = nodeInput2
        this.nodeId = `N2I[${nodeInput1.nodeId}, ${nodeInput2.nodeId}]`
        appendAsyncConstructor(this, async () => {
            await this.setupInputsProcessing([nodeInput1, nodeInput2])
        })
    }

    processUntyped(inputs: Array<any>): Promise<Output> {
        return this.process(inputs[0] as Input1, inputs[1] as Input2)
    }
}