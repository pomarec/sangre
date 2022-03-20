
import { describe } from 'mocha'
import { ArraySource, NodeFilterOperator } from '../../../src'
import { expectNodeToEmitInOrder } from '../../index.test'

describe("Filter", async function () {
    it('Equality', async function () {
        const users = await new ArraySource()
        users.setRows([
            { "name": "Jaques", "points": 200 },
            { "name": "Phil", "points": 1400 },
            { "name": "Kasper", "points": 200 },
        ])

        const filtered = await new NodeFilterOperator(users, { 'points': 200 })
        expectNodeToEmitInOrder(filtered, <any>[
            { "name": "Jaques", "points": 200 },
            { "name": "Kasper", "points": 200 },
        ])
    })


    it('None matching', async function () {
        const users = await new ArraySource()
        users.setRows([
            { "name": "Jaques", "points": 200 },
            { "name": "Phil", "points": 1400 },
            { "name": "Kasper", "points": 200 },
        ])

        const filtered = await new NodeFilterOperator(users, { 'points': 1 })
        expectNodeToEmitInOrder(filtered, <any>[])
    })
})
