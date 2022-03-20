import { Node } from "../node"
import { NodeOperator1Input } from "./operators"

/** 
 * Logs input data to console and output this data.
 */
export class Logger<T> extends NodeOperator1Input<T, T> {
    constructor(nodeI1: Node<T>) {
        super(async (i) => {
            console.log(`${this.nodeId} :`)
            console.log(i)
            return i
        }, nodeI1)
    }
}