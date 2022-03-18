import * as jsonpatch from 'fast-json-patch'
import _ from "lodash"
import { Client } from "pg"
import { Node, NodeSkipProcess } from "../node"
import { Node1Input } from "../node_input"

type DiffedData = { revision: number, from: number, diffs: Array<jsonpatch.Operation> }

/**
 * Transforms a stream of data to a stream of diffs of this data.
 * 
 * It generates a new revision number on each emission of data of its input.
 * It can also produce a diff from a given previous version.
 * Current diff algorithm is JsonPatch, chosen for its compatibility with dart
 * librairies. Other more efficient algorithms (myers ?) might be used in the future.
 * Snapshots of revisions are stored in postgres, thus the need of a postgresClient 
 * in constructor.
 */
export class Diffed<T> extends Node1Input<T, DiffedData> {
    private postgresClient: Client
    readonly tableName: string
    revision = 0
    lastInput?: T
    historyTableCreated = false

    constructor(nodeI1: Node<T>, postgresClient?: Client) {
        super(nodeI1)
        this.postgresClient = (postgresClient || this.parentPostgresClient) as Client
        this.tableName = `sangre_nodes_diff_history`
        // this.createHistoryTable() is called in this.process()
    }

    get parentPostgresClient(): Client | undefined {
        return this.postgresClient || super.parentPostgresClient
    }

    async process(input: T): Promise<DiffedData> {
        // It used to be in this async constructor but
        // process() is called before (when calling super's constructor)
        if (!this.historyTableCreated)
            await this.createHistoryTable()

        const diffs = jsonpatch.compare(this.lastInput ?? "", input)
        if (diffs.length == 0)
            throw new NodeSkipProcess("Diffed: no diff dectected since last input")
        this.lastInput = input
        this.revision++
        await this.saveCurrentRevision()

        return {
            revision: this.revision,
            from: this.revision - 1,
            diffs
        }
    }

    async diffsFromRevision(previousRevision = 0): Promise<DiffedData> {
        let previousValue = ""
        if (previousRevision > 0) {
            const previousValueQuery = await this.postgresClient.query(`
                SELECT ("snapshot") FROM "${this.tableName}" 
                WHERE id = '${this.nodeId}' AND revision = '${previousRevision}'
            `)
            const snapshot = previousValueQuery.rows[0]
            if (snapshot != null)
                previousValue = snapshot
        }
        const diffs = jsonpatch.compare(previousValue, this.lastInput ?? "")
        return {
            revision: this.revision,
            from: previousRevision,
            diffs
        }
    }

    /**
     * History table is a postgres table used to store
     * snapshots of this node input's data and their revision.
     * This table is mainly used by diffsFromRevision().
     */
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

    /** 
     * Saves snapshots of current input's data in history table.
     */
    private async saveCurrentRevision() {
        if (!_.isNil(this.lastInput))
            await this.postgresClient.query(`
                INSERT INTO "${this.tableName}" ("id", "revision", "snapshot") VALUES
                ('${this.nodeId}',	${this.revision}, '${JSON.stringify(this.lastInput)}');
            `)
    }
}