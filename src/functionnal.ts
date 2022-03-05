import { RealtimeClient } from "@supabase/realtime-js"
import { Client } from "pg"
import { JoinManyToMany, NodeGetOperator, NodeOperator1Input, PostgresTableSource } from "."
import { Node } from '../src'

/** This is only syntaxic sugar
 * 
 * The goal is to simplify syntax when creating chains
 * of nodes
 */
export class DB<T> implements Promise<Node<T>> {
    node?: Node<T>
    parent?: DB<any>

    get nodeSure(): Node<T> {
        const node = this.node
        if (node == undefined)
            throw Error("You need to assign a node")
        else
            return node
    }

    static globalPostgresClient: Client
    static globalRealtimeClient: RealtimeClient

    constructor(node: Node<any>, parent?: DB<any>) {
        this.node = node
        this.parent = parent
    }

    static configure(postgresClient: Client, realtimeClient: RealtimeClient) {
        this.globalPostgresClient = postgresClient
        this.globalRealtimeClient = realtimeClient
    }

    static table<O>(tableName: string): DB<Array<O>> {
        return new DB<Array<O>>(
            new PostgresTableSource(DB.globalPostgresClient, tableName, DB.globalRealtimeClient)
        )
    }

    get<O>(match: any): DB<O> {
        return new DB<O>(
            new NodeGetOperator<O>((this.nodeSure as any) as Node<Array<O>>, match),
            this
        )
    }

    joinMany(field: string, joinedTable?: Node<any>): DB<any> {
        const idField = 'id'
        const tableSource = this.findTableSource()
        if (tableSource == undefined)
            throw Error("Can't retrieve table source")
        else {
            const currentTableName = tableSource.tableName
            const currentTableNameWihoutS = currentTableName.substring(0, currentTableName.length - 1)
            const joinTablename = `${currentTableNameWihoutS}s_${field}s`
            const joinTable = new PostgresTableSource(DB.globalPostgresClient, joinTablename, DB.globalRealtimeClient)

            const newNode = new JoinManyToMany<any>(
                this.nodeSure instanceof NodeGetOperator
                    ? new NodeOperator1Input(async (e: any) => [e], this.nodeSure)
                    : this.nodeSure as Node<any>,
                idField,
                joinTable,
                `${currentTableNameWihoutS}_${idField}`,
                `${field}_${idField}`,
                joinedTable || tableSource,
                idField,
                `${field}s`
            )
            return new DB<any>(
                this.nodeSure instanceof NodeGetOperator
                    ? new NodeOperator1Input(async (e: Array<any>) => e[0], newNode)
                    : newNode,
                this
            )
        }
    }

    private findTableSource(): PostgresTableSource | undefined {
        if (this.nodeSure instanceof PostgresTableSource)
            return this.nodeSure
        else if (this.parent != undefined)
            return this.parent.findTableSource()
        return undefined
    }

    // TODO : clean implementation of promise (and types)

    async then<TResult1 = Node<any>, TResult2 = never>(
        onfulfilled?: ((value: Node<any>) => TResult1 | PromiseLike<TResult1>) | undefined | null,
        onrejected?: ((reason: any) => TResult2 | PromiseLike<TResult2>) | undefined | null
    ): Promise<TResult1 | TResult2> {
        const node = await this.nodeSure
        const resp = onfulfilled && onfulfilled(node)
        if (resp != undefined)
            return resp
        else
            return (onrejected && onrejected("Node must be defined before awaiting DB"))!
    }

    catch<TResult = never>(
        onrejected?: ((reason: any) => TResult | PromiseLike<TResult>) | undefined | null
    ): Promise<Node<any> | TResult> {
        return new Promise(() => { })
    }

    finally(onfinally?: () => void): Promise<Node<any>> {
        return new Promise(() => { })
    }
    get [Symbol.toStringTag]() {
        return 'DB string'
    }
}


