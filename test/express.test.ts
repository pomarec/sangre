
import { RealtimeClient } from '@supabase/realtime-js'
// @ts-ignore
import { expect, request } from 'chai'
import express from 'express'
import expressWs from 'express-ws'
import { describe } from 'mocha'
import { Client } from 'pg'
import ws from 'ws'
import { delayed, expressSangre } from '../src'
import { PostgresTableSource } from '../src/nodes/sources/postgres_table'

describe("Express api server", async function () {
    beforeEach(async function () {
        const postgresClient = new Client('postgresql://postgres:example@localhost:5432/postgres')
        await postgresClient.connect()
        await postgresClient.query(`
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

        const realtimeClient = new RealtimeClient('ws://localhost:4000/socket')
        await realtimeClient.connect()

        const usersNode = await new PostgresTableSource(postgresClient, 'users', realtimeClient)

        const app = expressWs(express()).app

        await expressSangre(app, '/users', usersNode, postgresClient)

        app.get('/addUser', async (req, res) => {
            const name = req.query['name']
            await postgresClient.query(`
                INSERT INTO "users" ("id", "name") VALUES
                (${usersNode.value!.length}, '${name ?? 'John'}');
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
        this.server.close(done)
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
        expect(JSON.parse(users[0])).to.be.deep.eq(_users)
        expect(JSON.parse(users[1])).to.be.deep.eq(_users.concat([{
            'id': 2,
            'name': 'Bruno',
        }]))
    })

    it('Get node diffed stream', async function () {
        const wsc = new ws.WebSocket(`ws://localhost:${this.server.address().port}/ws/users-diffed`)
        const req = request(this.server).keepOpen()
        delayed(500, () =>
            req.get('/addUser?name=Bruno')
        )
        const diffs = await _takeFromWS(wsc, 2)
        expect(JSON.parse(diffs[0])).to.be.deep.eq({
            "revision": 1,
            "diffs": [{
                "op": "replace",
                "path": "",
                "value": [
                    { "id": 0, "name": "fred" },
                    { "id": 1, "name": "omar" }
                ]
            }]
        })
        expect(JSON.parse(diffs[1])).to.be.deep.eq({
            "revision": 2,
            "diffs": [{
                "op": "replace",
                "path": "",
                "value": [
                    { "id": 0, "name": "fred" },
                    { "id": 1, "name": "omar" },
                    { "id": 2, "name": "Bruno" }
                ]
            }]
        })
    })
})

function _takeFromWS(wsc: ws, count: number): Promise<Array<string>> {
    return new Promise((resolve, reject) => {
        let resp = <any>[]
        wsc.on('message', function (data) {
            const message = data.toString()
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