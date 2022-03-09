
import { RealtimeClient } from '@supabase/realtime-js'
import { expect } from 'chai'
import _ from 'lodash'
import { describe } from 'mocha'
import { Client } from 'pg'
import { Env } from '../env'
import { PostgresTableSource } from '../src/index'
import { expectNodeToEmit } from './index.test'

const _initialUsers = [
    { 'id': 0, 'name': 'fred' },
    { 'id': 1, 'name': 'omar' }
]

describe("Postgres table", async function () {
    beforeEach(async function () {
        this.postgresClient = new Client(Env.postgresUri)
        await this.postgresClient.connect()
        const sql = `
            DROP TABLE IF EXISTS "users";
            CREATE TABLE "public"."users" (
                "id" integer NOT NULL,
                "name" character varying NOT NULL
            ) WITH (oids = false);

            ALTER TABLE "users" REPLICA IDENTITY FULL;

            INSERT INTO "users" ("id", "name") VALUES
            (0,	'fred'),
            (1,	'omar');
        `
        await this.postgresClient.query(sql)

        this.realtimeClient = new RealtimeClient(Env.realtimeUri)
        await this.realtimeClient.connect()
    })

    afterEach(async function () {
        await this.postgresClient.end()
        await this.realtimeClient.disconnect()
    })

    it('Initial data fetch', async function () {
        const users = await new PostgresTableSource(this.postgresClient, 'users')
        expect(users.lastValue).to.be.deep.equal(_initialUsers)
        await users.close()
    })

    it('Data insert', async function () {
        const users = await new PostgresTableSource(this.postgresClient, 'users', this.realtimeClient)
        await this.postgresClient.query(`
            INSERT INTO "users" ("id", "name") VALUES
            (2,	'patafouin');
        `)
        await expectNodeToEmit(users,
            _initialUsers.concat([{
                'id': 2,
                'name': 'patafouin',
            }])
        )
    })

    it('Data insert (polling)', async function () {
        const users = await new PostgresTableSource(this.postgresClient, 'users')
        await this.postgresClient.query(`
            INSERT INTO "users" ("id", "name") VALUES
            (2,	'patafouin');
        `)
        try {
            await expectNodeToEmit(users,
                _initialUsers.concat([{
                    'id': 2,
                    'name': 'patafouin',
                }])
            )
        } finally {
            await users.close()
        }
    })

    it('Data update', async function () {
        const users = await new PostgresTableSource(this.postgresClient, 'users', this.realtimeClient)
        await this.postgresClient.query(`
            UPDATE "users"
            SET "name" = 'omarys'
            WHERE "id" = 1;
        `)
        let updatedUsers = _.cloneDeep(_initialUsers)
        updatedUsers[1]["name"] = 'omarys'
        await expectNodeToEmit(users, updatedUsers)
    })

    it('Data deletion', async function () {
        const users = await new PostgresTableSource(this.postgresClient, 'users', this.realtimeClient)
        await this.postgresClient.query(`
            DELETE FROM "users"
            WHERE "id" = 1;
        `)
        let updatedUsers: Array<any> = _.cloneDeep(_initialUsers)
        _.pullAt(updatedUsers, [1])
        await expectNodeToEmit(users, updatedUsers)
    })
})