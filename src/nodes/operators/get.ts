import _ from "lodash"
import { Node } from "../node"
import { NodeOperator1Input } from "./operators"

export class NodeGetOperator<T> extends NodeOperator1Input<Array<T>, T> {
    constructor(nodeI1: Node<Array<T>>, match: any) {
        super(
            (users: Array<any>) => _.find(users,
                (u) => _.every(_.map(_.keys(match),
                    (k) => _.isEqual(match[k], u[k])
                )))
            , nodeI1
        )
    }
}

