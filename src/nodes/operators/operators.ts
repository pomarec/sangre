import { Node, Node1Input } from "../node"

/// A node operator is a node which process() is based on a operator
/// An operator is a pure function.

export class NodeOperator1Input<I1, Output> extends Node1Input<I1, Output> {
    operation: (_: I1) => Promise<Output>

    constructor(
        operation: (_: I1) => Promise<Output>,
        nodeI1: Node<I1>,
    ) {
        super(nodeI1)
        this.operation = operation
    }

    async process(input: I1): Promise<Output> {
        return this.operation(input)
    }
}
