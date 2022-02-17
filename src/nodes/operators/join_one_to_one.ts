import _ from 'lodash'
import { Node, Node2Input } from '../node'

export class JoinOneToOne<T extends {}>
    extends Node2Input<Array<T>, Array<T>, Array<T>> {
    /// Key of input1 items to match items from input2
    /// Can be a string or a Function(item of input1)
    readonly joinKey: string | ((item: T) => string)

    /// Key of input2 items to match with input1 joinKey
    /// Can be a string or a Function(item of input2)
    readonly matchingKey: string | ((item: T) => string)

    /// Key of input1 items to populate with matches from input2
    /// Can be a string or a Function(item of input1, matching item of input2)
    readonly joinedKey: string | ((item: T, matching: T) => void)

    constructor(nodeI1: Node<Array<T>>,
        joinKey: string | ((item: T) => any),
        nodeI2: Node<Array<T>>,
        matchingKey: string | ((item: T) => any),
        joinedKey?: string | ((item: T, matching: T) => any)
    ) {
        super(nodeI1, nodeI2)
        this.joinKey = joinKey
        this.matchingKey = matchingKey
        this.joinedKey = joinedKey || joinKey
    }

    async process(input1: Array<T>, input2: Array<T>): Promise<Array<T>> {
        return _.cloneDeep(input1).map((input1Element) => {
            const joinValue = _.isString(this.joinKey)
                ? (input1Element as any)[this.joinKey]
                : (this.joinKey as ((item: T) => any))(input1Element)
            if (!_.isNil(joinValue))
                for (var input2Element of input2) {
                    const matchingValue = _.isString(this.matchingKey)
                        ? (input2Element as any)[this.matchingKey]
                        : (this.matchingKey as ((item: T) => any))(input2Element)
                    if (matchingValue == joinValue) {
                        if (_.isString(this.joinedKey))
                            (input1Element as any)[this.joinedKey] = input2Element
                        else
                            (this.joinedKey as ((item: T, matching: T) => void))(input1Element, input2Element)
                    }

                }
            return input1Element
        })
    }
}