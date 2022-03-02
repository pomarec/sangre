import { appendAsyncConstructor } from "async-constructor"
import { diff as jsondiff } from "json8-patch"
import _ from "lodash"
import { Client } from "pg"
import { Node, Node1Input } from "../node"

export class Diffed<T> extends Node1Input<T, Object> {
    private postgresClient: Client
    readonly tableName: string
    revision = 0
    lastInput?: T

    constructor(nodeI1: Node<T>, postgresClient: Client) {
        super(nodeI1)
        this.postgresClient = postgresClient
        this.tableName = "sangre_nodes_diff_history"
        appendAsyncConstructor(this, this.createHistoryTable)
    }

    async process(input: T): Promise<Object> {
        const diffs = jsondiff(this.lastInput ?? "", input)
        this.lastInput = input
        this.revision++
        await this.saveCurrentRevision()
        return { revision: this.revision, diffs }
    }

    private async createHistoryTable() {
        await this.postgresClient.query(`
            DROP TABLE IF EXISTS "${this.tableName}";

            CREATE TABLE "${this.tableName}" (
                "id" VARCHAR(255) NOT NULL,
                "revision" integer NOT NULL,
                "snapshot" jsonb
            );

            ALTER TABLE "${this.tableName}" REPLICA IDENTITY FULL;
        `)
    }

    private async saveCurrentRevision() {
        if (!_.isNil(this.lastInput))
            await this.postgresClient.query(`
                INSERT INTO "${this.tableName}" ("id", "revision", "snapshot") VALUES
                ('${this.nodeId}',	${this.revision}, '${JSON.stringify(this.lastInput)}');
            `)
    }
}