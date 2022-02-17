
import { expect } from 'chai'
import { describe } from 'mocha'
import { JoinManyToMany, ListSource } from '../src/index'

describe("Join many to many", async function () {
    it('Join M2M node', async function () {
        const users = await new ListSource<Object>()
        users.setRows(_users)

        const followed = await new ListSource<Object>()
        followed.setRows(_followed)


        const chain = await new JoinManyToMany(
            users,
            'id',
            followed,
            'user_id',
            'followed_id',
            users,
            'id',
            'followed'
        )

        expect(chain.value).to.not.be.undefined
        expect((chain.value as any)[1]['followed'][0])
            .to.be.deep.equal((users.value as any)[2])
    })


    it('Join M2M node & source change', async function () {
        const users = await new ListSource<Object>()
        users.setRows(_users)

        const followed = await new ListSource<Object>()
        followed.setRows(_followed)


        const chain = await new JoinManyToMany(
            users,
            'id',
            followed,
            'user_id',
            'followed_id',
            users,
            'id',
            'followed'
        )

        expect(chain.value).to.not.be.undefined

        followed.insertRow({
            'user_id': 4,
            'followed_id': 1,
        })

        await chain.take(1)

        expect((chain.value as any)[4]['followed'][1])
            .to.be.deep.equal((users.value as any)[1])
    })
})


const _users = [
    {
        'id': 0,
        'name': 'kiko',
    },
    {
        'id': 1,
        'name': 'alfred',
    },
    {
        'id': 2,
        'name': 'maurice',
    },
    {
        'id': 3,
        'name': 'oliv',
    },
    {
        'id': 4,
        'name': 'josianne',
    },
]

const _followed = [
    {
        'user_id': 0,
        'followed_id': 1,
    },
    {
        'user_id': 2,
        'followed_id': 1,
    },
    {
        'user_id': 1,
        'followed_id': 2,
    },
    {
        'user_id': 3,
        'followed_id': 1,
    },
    {
        'user_id': 4,
        'followed_id': 3,
    },
    {
        'user_id': 3,
        'followed_id': 4,
    },
]
