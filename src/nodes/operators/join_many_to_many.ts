import _ from 'lodash'
import { Node } from '../node'
import { Node3Input } from '../node_input'

/**
 * Acts like an SQL many-to-many join, based on a pivot table.
 * 
 * First input is the data to populate.
 * Second input is the "pivot table" or joining table (jt).
 * Third input is the data used for population or joined table.
 */
export class JoinManyToMany<I1, I2, I3>
    extends Node3Input<Array<I1>, Array<I2>, Array<I3>, Array<I1>> {
    /** 
     * Key of first input's items to match items from second input.
    */
    readonly joinKey: string | ((item: I1) => string)

    /**  
     * Key of third input's items to match with first input's joinKey.
     */
    readonly matchingKey: string | ((item: I3) => string)

    /**  
     * Key of first input's items to populate with matches from third input.
     */
    readonly joinedKey: string | ((item: I1, matchingItems: Array<I3>) => void)

    /** 
     * Key of second input's items to match items from first input.
     */
    readonly jtJoinKey: string | ((item: I2) => string)

    /**  
     * Value of second input's items to match items from third input.
     */
    readonly jtValueKey: string | ((item: I2) => string)

    constructor(nodeI1: Node<Array<I1>>,
        joinKey: string | ((item: I1) => any),
        nodeI2: Node<Array<I2>>,
        jtJoinKey: string | ((item: I2) => string),
        jtValueKey: string | ((item: I2) => string),
        nodeI3: Node<Array<I3>>,
        matchingKey: string | ((item: I3) => any),
        joinedKey?: string | ((item: I1, matching: Array<I3>) => void),
    ) {
        super(nodeI1, nodeI2, nodeI3)
        this.joinKey = joinKey
        this.jtJoinKey = jtJoinKey
        this.jtValueKey = jtValueKey
        this.matchingKey = matchingKey
        this.joinedKey = joinedKey || joinKey
    }

    async process(input1: Array<I1>, input2: Array<I2>, input3: Array<I3>): Promise<Array<I1>> {
        return _.cloneDeep(input1).map((input1Element) => {
            const i1Value =
                _.isString(this.joinKey)
                    ? (input1Element as any)[this.joinKey]
                    : (this.joinKey as ((item: I1) => any))(input1Element)
            const jtJoinedItems = _.filter(input2, (input2Element) => {
                const i2Key =
                    _.isString(this.jtJoinKey)
                        ? (input2Element as any)[this.jtJoinKey]
                        : (this.jtJoinKey as ((item: I2) => any))(input2Element)
                return i2Key === i1Value
            })
            const matchingItems = _.cloneDeep(_.map(jtJoinedItems, (jtJoinedItem) => {
                const jtJoinedItemValue =
                    _.isString(this.jtValueKey)
                        ? (jtJoinedItem as any)[this.jtValueKey]
                        : (this.jtValueKey as ((item: I2) => any))(jtJoinedItem)
                return _.find(input3, (input3Element) => {
                    const input3ElementKey =
                        _.isString(this.matchingKey)
                            ? (input3Element as any)[this.matchingKey]
                            : (this.matchingKey as ((item: I3) => any))(input3Element)
                    return input3ElementKey === jtJoinedItemValue
                }) as I3
            }))

            if (_.isString(this.joinedKey))
                (input1Element as any)[this.joinedKey] = matchingItems
            else
                (this.joinedKey as ((item: I1, matching: Array<I3>) => void))(input1Element, matchingItems)

            return input1Element
        })
    }
}