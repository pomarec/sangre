
import { expect } from 'chai'
import _, { uniqueId } from 'lodash'
import { describe } from 'mocha'
import { ArraySource, JoinOneToOne } from '../../../src'

describe("Join one to one", async function () {
    it('Join node', async function () {
        const users =
            await new ArraySource<Object>()
        _.times(4, (i) =>
            users.insertRow({
                'id': i,
                'name': uniqueId(),
                'friend': 4 - 1 - i,
            })
        )
        expect(users.lastValue).to.not.be.undefined


        const chain = await new JoinOneToOne(
            users,
            'friend',
            users,
            'id',
        )

        expect(chain.lastValue).to.not.be.undefined
        expect((chain.lastValue as any)[1]['friend']).to.be.equal((users.lastValue as any)[2])
    })


    it('Join node & source change', async function () {
        const users =
            await new ArraySource<Object>()
        _.times(4, (i) =>
            users.insertRow({
                'id': i,
                'name': uniqueId(),
                'friend': 4 - 1 - i,
            })
        )
        const chain = await new JoinOneToOne(
            users,
            'friend',
            users,
            'id',
        )

        users.insertRow({
            'id': 4,
            'name': uniqueId(),
            'friend': 3,
        })

        await chain.take(1)

        expect((chain.lastValue as any)[4]['friend']).to.be.equal((users.lastValue as any)[3])
    })
})
