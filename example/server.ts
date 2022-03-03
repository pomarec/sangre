
import { RealtimeClient } from '@supabase/realtime-js'
import { randomInt } from 'crypto'
import express from 'express'
import expressWs from 'express-ws'
import _ from 'lodash'
import { Client } from 'pg'
import { expressSangre, JoinManyToMany, NodeGetOperator, NodeOperator1InputInterval } from '../src'
import { PostgresTableSource } from '../src/nodes/sources/postgres_table'

async function main() {
    const postgresClient = new Client('postgresql://postgres:example@localhost:5432/postgres')
    await postgresClient.connect()
    await postgresClient.query(_sql)

    const realtimeClient = new RealtimeClient('ws://localhost:4000/socket')
    await realtimeClient.connect()

    // final followedSource = await DBNode('users').get('id', 1).joinMany(
    //     'followeds',
    //     fromNode: DBNode('users').joinMany(
    //       'places',
    //       fromNode: PlacesOccupationFetcherNode(DBNode('places')),
    //     ),
    //   );


    const usersNode = await new PostgresTableSource(postgresClient, 'users', realtimeClient)
    const followedsNode = await new PostgresTableSource(postgresClient, 'users_followeds', realtimeClient)
    const placesNode = await new PostgresTableSource(postgresClient, 'places', realtimeClient)
    const placesFollowedsNode = await new PostgresTableSource(postgresClient, 'users_places', realtimeClient)

    const chain = await new NodeGetOperator(
        await new JoinManyToMany(
            usersNode,
            'id',
            followedsNode,
            'user_id',
            'followed_id',
            await new JoinManyToMany(
                usersNode,
                'id',
                placesFollowedsNode,
                'user_id',
                'place_id',
                await new NodeOperator1InputInterval(
                    async (places: Array<any>) => _.map(places, (p) => {
                        p["occupation"] = randomInt(5)
                        return p
                    }),
                    placesNode,
                ),
                'id',
                'places'

            ),
            'id',
            'followeds'
        ),
        { id: 1 }
    )

    const app = expressWs(express()).app

    await expressSangre(app, '/followeds', chain, postgresClient)

    app.get('/unfollow', async (req, res) => {
        const id = req.query['id']
        await postgresClient.query(`
          DELETE FROM "users_followeds" WHERE "followed_id" = ${id};
        `)
        res.end()
    })

    const server = app.listen(3000, () => {
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