import _ from "lodash"
import { Node } from "../node"
import { NodeOperator1Input } from "./operators"

/** 
 * Filters items of it's input. 
 * Its input data must be an array.
 */
export class NodeFilterOperator<T> extends NodeOperator1Input<Array<T>, Array<T>> {

    /** 
     * @param match is a map of (possibly multiple) key-values that will filter the input
     * to extract the desired result.
     * 
     * Eg: if match is `{price: 100}` then the result will a sub-array of
     * input with every item that has a field `price` whose value is `100`
     */
    constructor(nodeI1: Node<Array<T>>, match: any) {
        super(
            async (input) =>
                _.filter(input,
                    (u) => _.every(_.map(_.keys(match),
                        (k) => _.isEqual(match[k], u[k])
                    ))
                )
            , nodeI1
        )
    }
}

