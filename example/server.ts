
import { RealtimeClient } from '@supabase/realtime-js'
import { randomInt } from 'crypto'
import express from 'express'
import expressWs from 'express-ws'
import { Client } from 'pg'
import { Env } from '../env'
import { expressSangre } from '../src'
import { DB } from '../src/functionnal'

async function main() {
    const { app, postgresClient } = await setupApp()

    const users = await DB.table('users').get({ id: 1 }).joinMany('followed',
        await DB.table('users').joinMany('place',
            await DB.table('places').forEachEach(
                (p: any) => p["occupation"] = randomInt(5)
            )
        )
    )

    await expressSangre(app, '/followeds', users)

    app.get('/unfollow', async (req, res) => {
        const id = req.query['id']
        await postgresClient.query(`
          DELETE FROM "users_followeds" WHERE "followed_id" = ${id};
        `)
        res.end()
    })

    app.listen(3000, () => {
        console.log(`Server listening on port 3000`)
    })
}

main().catch((e) => console.error(e))

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

async function setupApp() {
    const postgresClient = new Client(Env.postgresUri)
    await postgresClient.connect()
    await postgresClient.query(_sql)

    const realtimeClient = new RealtimeClient(Env.realtimeUri)
    await realtimeClient.connect()

    DB.configure(postgresClient, realtimeClient)

    const app = expressWs(express()).app

    return { app, postgresClient }
}
