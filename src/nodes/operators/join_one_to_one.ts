import _ from 'lodash'
import { Node } from '../node'
import { Node2Input } from '../node_with_input/node_2_input'

/**
 * Acts like an SQL one-to-one join.
 * 
 * First input is the data to populate, containing a join key.
 * Second input is the data used for population or joined table.
 */
export class JoinOneToOne<I1, I2>
    extends Node2Input<Array<I1>, Array<I2>, Array<I1>> {
    /**
     * Join key of first input's items.
     */
    readonly joinKey: string | ((item: I1) => string)

    /**
     * Key of second input's items to match with `joinKey`.
     */
    readonly matchingKey: string | ((item: I2) => string)

    /**
     * Key of first input's items to populate with matches from seconde input's items.
     */
    readonly joinedKey: string | ((item: I1, matching: I2) => void)

    constructor(nodeI1: Node<Array<I1>>,
        joinKey: string | ((item: I1) => any),
        nodeI2: Node<Array<I2>>,
        matchingKey: string | ((item: I2) => any),
        joinedKey?: string | ((item: I1, matching: I2) => any)
    ) {
        super(nodeI1, nodeI2)
        this.joinKey = joinKey
        this.matchingKey = matchingKey
        this.joinedKey = joinedKey || joinKey
    }

    async process(input1: Array<I1>, input2: Array<I2>): Promise<Array<I1>> {
        return _.cloneDeep(input1).map((input1Element) => {
            const joinValue = _.isString(this.joinKey)
                ? (input1Element as any)[this.joinKey]
                : (this.joinKey as ((item: I1) => any))(input1Element)
            if (!_.isNil(joinValue))
                for (var input2Element of input2) {
                    const matchingValue = _.isString(this.matchingKey)
                        ? (input2Element as any)[this.matchingKey]
                        : (this.matchingKey as ((item: I2) => any))(input2Element)
                    if (matchingValue === joinValue) {
                        if (_.isString(this.joinedKey))
                            (input1Element as any)[this.joinedKey] = input2Element
                        else
                            (this.joinedKey as ((item: I1, matching: I2) => void))(input1Element, input2Element)
                    }

                }
            return input1Element
        })
    }
}