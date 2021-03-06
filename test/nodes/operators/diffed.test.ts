import { expect } from 'chai'
import { describe } from 'mocha'
import { Client } from 'pg'
import { Env } from '../../../env'
import { ArraySource, delayed, Diffed, PostgresTableSource } from '../../../src'
import { expectNodeToEmitInOrder } from '../../index.test'

describe("Diffed", async function () {
    beforeEach(async function () {
        this.postgresClient = new Client(Env.postgresUri)
        await this.postgresClient.connect()

        this.usersNode = await new ArraySource<any>()
        this.usersNode.setRows(_users)

        this.diffedNode = await new Diffed(this.usersNode, this.postgresClient)
    })

    afterEach(async function () {
        await this.postgresClient.end()
    })

    it('Get diff when updating source', async function () {
        const userNode = this.usersNode as ArraySource<any>
        const diffedNode = this.diffedNode as Diffed<any>
        delayed(500, function () {
            userNode.insertRow({
                "id": 3, "name": "caramel"
            })
        })
        await expectNodeToEmitInOrder(diffedNode, [{
            "revision": 1,
            "from": 0,
            "diffs": [{
                "op": "add",
                "path": "/0",
                "value": {
                    "id": 0,
                    "name": "fred"
                }
            }, {
                "op": "add",
                "path": "/1",
                "value": {
                    "id": 1,
                    "name": "omar"
                }
            }, {
                "op": "add",
                "path": "/2",
                "value": {
                    "id": 2,
                    "name": "patafouin"
                }
            }]
        }, {
            "revision": 2,
            "from": 1,
            "diffs": [{
                "op": "add",
                "path": "/3",
                "value": {
                    "id": 3,
                    "name": "caramel"
                }
            }]
        }], false)
    })

    it('Get diff from an old version', async function () {
        const userNode = this.usersNode as ArraySource<any>
        const diffedNode = this.diffedNode as Diffed<any>

        const oldVersion = await diffedNode.takeValue()

        userNode.insertRow({
            "id": 3, "name": "caramel"
        })
        userNode.insertRow({
            "id": 4, "name": "maurice"
        })
        userNode.updateRows((row) => {
            if (row["id"] == 2)
                row["name"] = "Jean-Louis"
            return row
        })

        // Let updates propagate
        await delayed(500, () => { })

        const diffs = await diffedNode.diffsFromRevision(oldVersion.revision)
        expect(diffs).to.be.deep.equal({
            "revision": 3,
            "from": 1,
            "diffs": [{
                "op": "add",
                "path": "/0",
                "value": { "id": 0, "name": "fred" }
            }, {
                "op": "add",
                "path": "/1",
                "value": { "id": 1, "name": "omar" }
            }, {
                "op": "add",
                "path": "/2",
                "value": { "id": 2, "name": "Jean-Louis" }
            }, {
                "op": "add",
                "path": "/3",
                "value": { "id": 3, "name": "caramel" }
            }, {
                "op": "add",
                "path": "/4",
                "value": { "id": 4, "name": "maurice" }
            }]
        })
    })

    it('Retrieve postgres client from parent node', async function () {
        await this.postgresClient.query(`
            DROP TABLE IF EXISTS "users";
            CREATE TABLE "public"."users" (
                "id" integer NOT NULL,
                "name" character varying NOT NULL
            ) WITH (oids = false);
        `)
        const users = await new PostgresTableSource(this.postgresClient, 'users')
        const diffedNode = await new Diffed(users)

        expect(diffedNode.parentPostgresClient).to.equals(this.postgresClient)
    })
})

const _users = [
    { "id": 0, "name": "fred" },
    { "id": 1, "name": "omar" },
    { "id": 2, "name": "patafouin" }
]