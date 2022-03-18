
import { RealtimeClient } from '@supabase/realtime-js'
// @ts-ignore
import { expect, request } from 'chai'
import express from 'express'
import expressWs from 'express-ws'
import { describe } from 'mocha'
import { Client } from 'pg'
import ws from 'ws'
import { Env } from '../env'
import { delayed, expressSangre } from '../src'
import { PostgresTableSource } from '../src/nodes/sources/postgres_table'

describe("Express api server", async function () {
    beforeEach(async function () {
        this.postgresClient = new Client(Env.postgresUri)
        await this.postgresClient.connect()
        await this.postgresClient.query(`
            DROP TABLE IF EXISTS "users";
            CREATE TABLE "public"."users" (
                "id" integer NOT NULL,
                "name" character varying NOT NULL
            ) WITH (oids = false);

            ALTER TABLE "users" REPLICA IDENTITY FULL;

            INSERT INTO "users" ("id", "name") VALUES
            (0,	'fred'),
            (1,	'omar');
        `)

        this.realtimeClient = new RealtimeClient(Env.realtimeUri)
        await this.realtimeClient.connect()

        const usersNode = await new PostgresTableSource(this.postgresClient, 'users', this.realtimeClient)

        const app = expressWs(express()).app

        await expressSangre(app, '/users', usersNode)

        app.get('/addUser', async (req, res) => {
            const name = req.query['name']
            await this.postgresClient.query(`
                INSERT INTO "users" ("id", "name") VALUES
                (${usersNode.lastValue!.length}, '${name ?? 'John'}');
            `)
            res.end()
        })

        this.server = await new Promise((resolve) => {
            const server = app.listen(30000,
                () => resolve(server)
            )
        })
    })

    afterEach(function (done) {
        const t = this
        this.server.close(async function () {
            await t.postgresClient.end()
            await t.realtimeClient.disconnect()
            done()
        })
    })

    it('Get node data', async function () {
        const { text: resp } = await request(this.server).keepOpen().get('/users')
        expect(JSON.parse(resp)).to.be.deep.eq(_users)
    })

    it('Get node stream', async function () {
        const wsc = new ws.WebSocket(`ws://localhost:${this.server.address().port}/ws/users`)
        const req = request(this.server).keepOpen()
        delayed(500, () =>
            req.get('/addUser?name=Bruno')
        )
        const users = await _takeFromWS(wsc, 2)
        expect(users).to.be.deep.eq([_users,
            _users.concat([{
                'id': 2,
                'name': 'Bruno',
            }])
        ])
    })


    it('Get node diffed stream', async function () {
        const wsc = new ws.WebSocket(`ws://localhost:${this.server.address().port}/ws/users-diffed`)
        const req = request(this.server).keepOpen()
        delayed(500, () =>
            req.get('/addUser?name=Bruno')
        )
        const diffs = await _takeFromWS(wsc, 2)
        expect(diffs).to.be.deep.eq([{
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
            }]
        }, {
            "revision": 2,
            "from": 1,
            "diffs": [{
                "op": "add",
                "path": "/2",
                "value": {
                    "id": 2,
                    "name": "Bruno"
                }
            }]
        }])
    })
})

function _takeFromWS(wsc: ws, count: number): Promise<Array<string>> {
    return new Promise((resolve, reject) => {
        let resp = <any>[]
        wsc.on('message', function (data) {
            const message = JSON.parse(data.toString())
            resp.push(message)
            if (resp.length >= count) {
                wsc.close()
                resolve(resp)
            }
        })
        wsc.on('error', reject)
    })
}

const _users = [
    { "id": 0, "name": "fred" },
    { "id": 1, "name": "omar" }
]