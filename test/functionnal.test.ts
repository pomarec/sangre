
import { RealtimeClient } from '@supabase/realtime-js'
import { expect } from 'chai'
import { randomInt } from 'crypto'
import { describe } from 'mocha'
import { Client } from 'pg'
import { Env } from '../env'
import { DB } from '../src'

describe("Functional", async function () {
    beforeEach(async function () {
        this.postgresClient = new Client(Env.postgresUri)
        await this.postgresClient.connect()
        await this.postgresClient.query(_sql)

        this.realtimeClient = new RealtimeClient(Env.realtimeUri)
        await this.realtimeClient.connect()

        DB.configure(this.postgresClient, this.realtimeClient)
    })

    afterEach(async function () {
        await this.postgresClient.end()
        await this.realtimeClient.disconnect()
    })

    it('Query', async function () {
        var chain =
            await DB.table('users').get({ id: 1 }).joinMany('followed',
                await DB.table('users').joinMany('place',
                    await DB.table('places').forEachEach(
                        (p: any) => p["occupation"] = randomInt(5)
                    ),
                ),
            )

        const data = await chain.take(1, false)
        expect(data[0]["followeds"][1]["places"][0]).to.include({ "id": 1, "name": "La Cuisinerie" })
    })
})

const _sql = `
    DROP TABLE IF EXISTS "users";
    CREATE TABLE "users" (
        "id" integer NOT NULL,
        "name" character varying NOT NULL
    ) WITH (oids = false);
    ALTER TABLE "users" REPLICA IDENTITY FULL;
    INSERT INTO "users" ("id", "name") VALUES
    (0,	'Fred'),
    (1,	'Omar'),
    (2,	'Jean'),
    (4,	'Roland');

    DROP TABLE IF EXISTS "users_followeds";
    CREATE TABLE "users_followeds" (
    "user_id" integer NOT NULL,
    "followed_id" integer NOT NULL
    );
    ALTER TABLE "users_followeds" REPLICA IDENTITY FULL;
    INSERT INTO "users_followeds" ("user_id", "followed_id") VALUES
    (0,	1),
    (1,	2),
    (1,	0),
    (1,	1),
    (2, 1);

    DROP TABLE IF EXISTS "places";
    CREATE TABLE "places" (
        "id" integer NOT NULL,
        "name" character varying NOT NULL
    ) WITH (oids = false);
    ALTER TABLE "places" REPLICA IDENTITY FULL;
    INSERT INTO "places" ("id", "name") VALUES
    (0,	'Looloo Kitchen'),
    (1,	'La Cuisinerie'),
    (2,	'Cosinar Juntos'),
    (3,	'Pachamama'),
    (4,	'Philoo'),
    (5,	'Duropam');

    DROP TABLE IF EXISTS "users_places";
    CREATE TABLE "users_places" (
    "user_id" integer NOT NULL,
    "place_id" integer NOT NULL
    );
    ALTER TABLE "users_places" REPLICA IDENTITY FULL;
    INSERT INTO "users_places" ("user_id", "place_id") VALUES
    (0,	1),
    (1,	2),
    (1,	3),
    (2, 4),
    (0, 5),
    (4, 5),
    (1, 5);
`