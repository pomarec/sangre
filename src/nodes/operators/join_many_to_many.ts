import _ from 'lodash'
import { Node, Node3Input } from '../node'

export class JoinManyToMany<T>
    extends Node3Input<Array<T>, Array<T>, Array<T>, Array<T>> {
    /// Key of input1 items to match items from input2
    /// Can be a string or a Function(item of input1)
    readonly joinKey: string | ((item: T) => string)

    /// Key of input3 items to match with input1 joinKey
    /// Can be a string or a Function(item of input3)
    readonly matchingKey: string | ((item: T) => string)

    /// Key of input1 items to populate with matches from input3
    /// Can be a string or a Function(item of input1, matching items of input3)
    readonly joinedKey: string | ((item: T, matching: Array<T>) => void)

    /// Key of input2 items to match items from input1
    /// Can be a string or a Function(item of input2)
    readonly jtJoinKey: string | ((item: T) => string)

    /// Value of input2 items to match items from input3
    /// Can be a string or a Function(item of input2)
    readonly jtValueKey: string | ((item: T) => string)

    /// node1 is the base data
    /// node2 is the joining table (jt) or pivot
    /// node3 is the joined data
    constructor(nodeI1: Node<Array<T>>,
        joinKey: string | ((item: T) => any),
        nodeI2: Node<Array<T>>,
        jtJoinKey: string | ((item: T) => string),
        jtValueKey: string | ((item: T) => string),
        nodeI3: Node<Array<T>>,
        matchingKey: string | ((item: T) => any),
        joinedKey?: string | ((item: T, matching: Array<T>) => void),
    ) {
        super(nodeI1, nodeI2, nodeI3)
        this.joinKey = joinKey
        this.jtJoinKey = jtJoinKey
        this.jtValueKey = jtValueKey
        this.matchingKey = matchingKey
        this.joinedKey = joinedKey || joinKey
    }

    async process(input1: Array<T>, input2: Array<T>, input3: Array<T>): Promise<Array<T>> {
        return _.cloneDeep(input1).map((input1Element) => {
            const i1Value =
                _.isString(this.joinKey)
                    ? (input1Element as any)[this.joinKey]
                    : (this.joinKey as ((item: T) => any))(input1Element)
            const jtJoinedItems = _.filter(input2, (input2Element) => {
                const i2Key =
                    _.isString(this.jtJoinKey)
                        ? (input2Element as any)[this.jtJoinKey]
                        : (this.jtJoinKey as ((item: T) => any))(input2Element)
                return i2Key === i1Value
            })
            const matchingItems = _.cloneDeep(_.map(jtJoinedItems, (jtJoinedItem) => {
                const jtJoinedItemValue =
                    _.isString(this.jtValueKey)
                        ? (jtJoinedItem as any)[this.jtValueKey]
                        : (this.jtValueKey as ((item: T) => any))(jtJoinedItem)
                return _.find(input3, (input3Element) => {
                    const input3ElementKey =
                        _.isString(this.matchingKey)
                            ? (input3Element as any)[this.matchingKey]
                            : (this.matchingKey as ((item: T) => any))(input3Element)
                    return input3ElementKey === jtJoinedItemValue
                }) as T
            }))

            if (_.isString(this.joinedKey))
                (input1Element as any)[this.joinedKey] = matchingItems
            else
                (this.joinedKey as ((item: T, matching: Array<T>) => void))(input1Element, matchingItems)

            return input1Element
        })
    }
}