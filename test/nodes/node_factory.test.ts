
import { expect } from 'chai'
import { describe } from 'mocha'
import { DB, NodeFilterOperator } from '../../src'

describe.only("Node Factory", async function () {
    it('Reuse node', async function () {
        const node1 = await DB.table('users').filter({ id: 3 })
        const node2 = await DB.table('users').filter({ id: 3 })
        expect(node1).to.be.eq(node2)

        const parent1 = (node1 as NodeFilterOperator<any>).nodeInput
        const parent2 = (node2 as NodeFilterOperator<any>).nodeInput
        expect(parent1).to.be.eq(parent2)
    })

    it('Don\'t reuse different node', async function () {
        const node1 = await DB.table('users').filter({ id: 3 })
        const node2 = await DB.table('users').filter({ id: 2 })
        expect(node1).to.not.be.eq(node2)

        const parent1 = (node1 as NodeFilterOperator<any>).nodeInput
        const parent2 = (node2 as NodeFilterOperator<any>).nodeInput
        expect(parent1).to.be.eq(parent2)
    })

    it('Don\'t reuse same node that has different parent', async function () {
        const node1 = await DB.table('users').filter({ id: 3 })
        const node2 = await DB.table('places').filter({ id: 3 })
        expect(node1).to.not.be.eq(node2)

        const parent1 = (node1 as NodeFilterOperator<any>).nodeInput
        const parent2 = (node2 as NodeFilterOperator<any>).nodeInput
        expect(parent1).to.not.be.eq(parent2)
    })
})

