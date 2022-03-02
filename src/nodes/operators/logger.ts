import { Node } from "../node"
import { NodeOperator1Input } from "./operators"

export class Logger<T> extends NodeOperator1Input<T, T> {
    constructor(nodeI1: Node<T>) {
        super(async (i) => {
            console.log("Logger node:")
            console.log(i)
            return i
        }, nodeI1)
    }
}