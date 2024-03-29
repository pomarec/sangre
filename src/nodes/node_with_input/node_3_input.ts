import { appendAsyncConstructor } from 'async-constructor'
import { Client } from 'pg'
import { Node } from '../node'
import { NodeWithInput } from './node_with_input'

/**
 * Node that takes three nodes as inputs.
 */
export abstract class Node3Input<Input1, Input2, Input3, Output> extends NodeWithInput<Output> {
    nodeInput1: Node<Input1>
    nodeInput2: Node<Input2>
    nodeInput3: Node<Input3>

    /**
     * This is the implementation of the transformation made
     * on input data to produce the current node's output.
     */
    abstract process(i1: Input1, i2: Input2, i3: Input3): Promise<Output>

    get parentPostgresClient(): Client | undefined {
        return this.nodeInput1.parentPostgresClient
    }

    constructor(nodeInput1: Node<Input1>, nodeInput2: Node<Input2>, nodeInput3: Node<Input3>) {
        super()
        this.nodeInput1 = nodeInput1
        this.nodeInput2 = nodeInput2
        this.nodeInput3 = nodeInput3
        this.nodeId = `N3I[${nodeInput1.nodeId}, ${nodeInput2.nodeId}, , ${nodeInput3.nodeId}]`
        appendAsyncConstructor(this, async () => {
            await this.setupInputsProcessing([nodeInput1, nodeInput2, nodeInput3])
        })
    }

    processUntyped(inputs: Array<any>): Promise<Output> {
        return this.process(inputs[0] as Input1, inputs[1] as Input2, inputs[2] as Input3)
    }


    /** See NodeFactory.factorizeClass */
    static compareForNew(node: Node3Input<any, any, any, any>, nodeInput1: Node<any>, nodeInput2: Node<any>, nodeInput3: Node<any>, ...args: Array<any>): boolean {
        return node.nodeInput1 == nodeInput1 && node.nodeInput2 == nodeInput2 && node.nodeInput3 == nodeInput3
    }
}

