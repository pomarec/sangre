import { Request } from 'express'
import expressWs from 'express-ws'
import { Client } from 'pg'
import ws from 'ws'
import { Node } from './nodes/node'
import { Diffed } from './nodes/operators/diffed'

export async function expressSangre<T>(
    app: expressWs.Application,
    path: string,
    node: Node<T>,
    postgresClient: Client): Promise<expressWs.Application> {

    app.get(`${path}`, async function (req, res) {
        res.send(JSON.stringify(node.value))
    })
    app.ws(`/ws${path}`, function (ws: ws, req: Request) {
        const subscription = node.subscribe({
            next: (data) =>
                ws.send(JSON.stringify(data))
        })
        ws.on('close', subscription.unsubscribe)
    })
    const usersDiffed = await new Diffed(node, postgresClient)
    app.ws(`/ws${path}-diffed`, function (ws: ws, req: Request) {
        const subscription = usersDiffed.subscribe({
            next: (data) =>
                ws.send(JSON.stringify(data))
        })
        ws.on('close', subscription.unsubscribe)
    })

    return app
}