import _ from "lodash"
import { Node } from "../node"
import { NodeFactory } from "../node_factory"
import { NodeOperator1Input } from "./operators"

/** 
 * Filters items of it's input. 
 * Its input data must be an array.
 */
@NodeFactory.factorizeClass
export class NodeFilterOperator<T> extends NodeOperator1Input<Array<T>, Array<T>> {
    readonly match: any

    /** 
     * @param match is a map of (possibly multiple) key-values that will filter the input
     * to extract the desired result.
     * 
     * Eg: if match is `{price: 100}` then the result will a sub-array of
     * input with every item that has a field `price` whose value is `100`
     */
    constructor(nodeInput: Node<Array<T>>, match: any) {
        super(
            async (input: Array<T>) =>
                _.filter(input,
                    (u: T) => _.every(_.map(_.keys(match),
                        (k: string) => _.isEqual(match[k], (u as any)[k])
                    ))
                )
            , nodeInput
        )
        this.match = match
    }

    static compareForNew<T>(node: NodeFilterOperator<T>, nodeInput: Node<Array<T>>, match: any): boolean {
        const a = node.nodeInput == nodeInput
        const b = _.isEqual(match, node.match)
        return a && b
    }
}

