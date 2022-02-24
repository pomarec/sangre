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
            //   channel.on(
            //     'UPDATE',
            //     (payload, {ref}) {
            //       final typedOldRow = convertChangeData(
            //         (payload['columns'] as List).cast<Map<String, dynamic>>(),
            //         payload['old_record'],
            //       );
            //       final typedNewRow = convertChangeData(
            //         (payload['columns'] as List).cast<Map<String, dynamic>>(),
            //         payload['record'],
            //       );
            //       updateRows(
            //         (row) => row['id'] == typedOldRow['id'] ? typedNewRow : row,
            //       );
            //     },
            //   );
            //   channel.on(
            //     'DELETE',
            //     (payload, {ref}) {
            //       final typedRow = convertChangeData(
            //         (payload['columns'] as List).cast<Map<String, dynamic>>(),
            //         payload['old_record'],
            //       );

            //       // Avoid removing every rows that look like the deleted one
            //       var hasDeletedARow = false;
            //       updateRows((row) {
            //         if (!hasDeletedARow &&
            //             row.entries.every((e) => typedRow[e.key] == e.value)) {
            //           hasDeletedARow = true;
            //           return null;
            //         } else
            //           return row;
            //       });
            //     },
            //   );
            channel.subscribe()

            // Wait for channel to be joined
            let maxRetries = 5
            while (!channel.isJoined() && maxRetries-- > 0)
                await delayed(50, () => { })
        }
    }
}