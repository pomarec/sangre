import { RealtimeClient, RealtimeSubscription } from "@supabase/realtime-js"
import { convertChangeData } from "@supabase/realtime-js/dist/main/lib/transformers"
import { appendAsyncConstructor } from "async-constructor"
import _ from "lodash"
import { Client } from 'pg'
import { delayed } from "../../utils"
import { ArraySource } from "./array"

/**
 * Ouputs the rows of a postgres table.
 * 
 * This data is eventually up to date as data changes in the table.
 * Each time some data is added, modified or deleted from the table
 * this node re-emits the up-to-date rows.
 * One of two mechanism can be used, polling (every second) or realtime (needs
 * a supabase-realtime client connected to a supabse-realtime server).
 */
export class PostgresTableSource extends ArraySource<Object> {
    readonly postgresClient: Client
    readonly realtimeClient?: RealtimeClient
    readonly tableName: string
    private realtimeChannel?: RealtimeSubscription

    constructor(postgresClient: Client, tableName: string, realtimeClient?: RealtimeClient) {
        super()
        this.postgresClient = postgresClient
        this.tableName = tableName
        this.realtimeClient = realtimeClient
        this.nodeId = `${this.nodeId}(${this.tableName})`
        appendAsyncConstructor(this, async () => {
            await this.fetchResults()
            if (_.isNil(this.realtimeClient))
                this.setupPolling()
            else
                await this.setupRealtime()
        })
    }

    async close() {
        this.realtimeChannel?.unsubscribe()
        await super.close()
    }

    private async fetchResults() {
        const { rows } = await this.postgresClient.query(
            `SELECT * FROM ${this.tableName}`,
        )
        this.setRows(rows)
    }

    private setupPolling() {
        const timer = setInterval(() => {
            if (this.isClosed)
                clearInterval(timer)
            else
                this.fetchResults()
        }, 1000)
    }

    private async setupRealtime() {
        if (_.isNil(this.realtimeClient))
            throw Error("Can't setup realtime without a realtime client")

        const channel = this.realtimeClient.channel(`realtime:public:${this.tableName}`)
        channel.on(
            'INSERT',
            ({ columns, record }: { columns: any, record: any }) =>
                this.insertRow(
                    convertChangeData(columns, record)
                ),
        )
        channel.on(
            'UPDATE',
            ({ columns, record, old_record }: { columns: any, record: any, old_record: any }) => {
                const typedNewRecord = convertChangeData(columns, record)
                const typedOldRecord = convertChangeData(columns, old_record)
                this.updateRows((row: any) =>
                    _.isEqual(row, typedOldRecord) ? typedNewRecord : row,
                )
            },
        )
        channel.on(
            'DELETE',
            ({ columns, old_record }: { columns: any, record: any, old_record: any }) => {
                const typedOldRecord = convertChangeData(columns, old_record)
                let hasDeletedARow = false
                this.updateRows((row: any) => {
                    if (!hasDeletedARow && _.isEqual(typedOldRecord, row)) {
                        hasDeletedARow = true
                        return null
                    } else
                        return row
                })
            },
        )
        channel.subscribe()
        this.realtimeChannel = channel

        // Wait for channel to be joined
        let maxRetries = 10
        while (!channel.isJoined() && maxRetries-- > 0)
            await delayed(50, () => { })
    }
}