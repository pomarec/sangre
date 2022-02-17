
import { expect } from 'chai'
import _, { uniqueId } from 'lodash'
import { describe } from 'mocha'
import { JoinOneToOne, ListSource } from '../src/index'

describe("Join one to one", async function () {
    it('Join node', async function () {
        const users =
            await new ListSource<Object>()
        _.times(4, (i) =>
            users.insertRow({
                'id': i,
                'name': uniqueId(),
                'friend': 4 - 1 - i,
            })
        )
        expect(users.value).to.not.be.undefined


        const chain = await new JoinOneToOne(
            users,
            'friend',
            users,
            'id',
        )

        expect(chain.value).to.not.be.undefined
        expect((chain.value as any)[1]['friend']).to.be.equal((users.value as any)[2])
    })


    it('Join node & source change', async function () {
        const users =
            await new ListSource<Object>()
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

        expect((chain.value as any)[4]['friend']).to.be.equal((users.value as any)[3])
    })
})
