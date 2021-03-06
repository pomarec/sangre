import { Node } from "../node"
import { Node1Input } from '../node_with_input/node_1_input'
import { Node2Input } from '../node_with_input/node_2_input'

/** 
 * A node operator is a node which process() is based on a operator.
 * 
 * An operator is a pure function.
 */
export class NodeOperator1Input<I1, Output> extends Node1Input<I1, Output> {
    operation: (_: I1) => Promise<Output>

    constructor(
        operation: (_: I1) => Promise<Output>,
        nodeI1: Node<I1>,
    ) {
        super(nodeI1)
        this.operation = operation
    }

    async process(i1: I1): Promise<Output> {
        return await this.operation(i1)
    }
}

/** 
 * A node operator is a node which process() is based on a operator.
 * 
 * An operator is a pure function.
 */
export class NodeOperator2Input<I1, I2, Output> extends Node2Input<I1, I2, Output> {
    operation: (i1: I1, i2: I2) => Promise<Output>

    constructor(
        operation: (i1: I1, i2: I2) => Promise<Output>,
        nodeI1: Node<I1>,
        nodeI2: Node<I2>,
    ) {
        super(nodeI1, nodeI2)
        this.operation = operation
    }

    async process(i1: I1, i2: I2): Promise<Output> {
        return await this.operation(i1, i2)
    }
}

