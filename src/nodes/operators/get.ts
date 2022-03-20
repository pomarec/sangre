import _ from "lodash"
import { Node } from "../node"
import { NodeOperator1Input } from "./operators"

/** 
 * Extracts an item of it's input. 
 * Its input data must be an array.
 */
export class NodeGetOperator<T> extends NodeOperator1Input<Array<T>, T> {

    /** 
     * @param match is a map of (possibly multiple) key-values that will filter the input
     * to extract the desired result.
     * 
     * Eg: if match is `{id: 1}` then the result will be the first item of
     * input that has a field `id` whose value is `1`
     */
    constructor(nodeI1: Node<Array<T>>, match: any) {
        super(
            (input: Array<any>) =>
                _.find(input,
                    (u) => _.every(_.map(_.keys(match),
                        (k) => _.isEqual(match[k], u[k])
                    ))
                )
            , nodeI1
        )
    }
}

