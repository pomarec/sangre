import { RealtimeClient, RealtimeSubscription } from "@supabase/realtime-js"
import { convertChangeData } from "@supabase/realtime-js/dist/main/lib/transformers"
import { appendAsyncConstructor } from "async-constructor"
import _ from "lodash"
import { Client } from 'pg'
import { delayed } from "../../utils"
import { ListSource } from "./list"

export class PostgresTableSource extends ListSource<Object> {
    readonly postgresClient: Client
    readonly realtimeClient: RealtimeClient
    readonly tableName: string
    private realtimeChannel?: RealtimeSubscription

    constructor(postgresClient: Client, tableName: string, realtimeClient?: any) {
        super()
        this.postgresClient = postgresClient
        this.tableName = tableName
        this.realtimeClient = realtimeClient
        appendAsyncConstructor(this, async () => {
            await this.fetchResults()
            if (_.isNil(this.realtimeClient))
                this.setupPolling()
            else
                await this.setupRealtime()
        })
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
        if (!_.isNil(this.realtimeClient)) {
            const channel = this.realtimeClient.channel(`realtime:public:${this.tableName}`)
            this.realtimeChannel = channel
            channel.on(
                'INSERT',
                ({ columns, record }: { columns: any, record: any }) => this.insertRow(
                    convertChangeData(columns, record)
                ),
            )
            channel.on(
                'UPDATE',
                ({ columns, record, old_record }: { columns: any, record: any, old_record: any }) => {
                    const typedNewRecord = convertChangeData(columns, record)
                    const typedOldRecord = convertChangeData(columns, old_record)
                    this.updateRows((row: any) =>
                        row['id'] === typedOldRecord['id'] ? typedNewRecord : row,
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

            // Wait for channel to be joined
            let maxRetries = 5
            while (!channel.isJoined() && maxRetries-- > 0)
                await delayed(50, () => { })
        }
    }
}