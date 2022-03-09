import { Request } from 'express'
import expressWs from 'express-ws'
import _ from 'lodash'
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
        res.send(JSON.stringify(node.lastValue))
    })
    app.ws(`/ws${path}`, function (ws: ws, req: Request) {
        const subscription = node.subscribe({
            next: (data) =>
                ws.send(JSON.stringify(data))
        })
        ws.on('close', subscription.unsubscribe)
    })

    const nodeDiffed = await new Diffed(node, postgresClient)
    _.times(20, (i) => _plugDiffed(app, path, nodeDiffed, i))
    _plugDiffed(app, path, nodeDiffed, undefined)

    return app
}

// Regex don't work in app.ws()
function _plugDiffed<T>(
    app: expressWs.Application,
    path: string,
    nodeDiffed: Diffed<T>,
    fromRevision?: number) {

    const route = `/ws${path}-diffed` + (_.isNil(fromRevision) ? '' : `-${fromRevision}`)
    app.ws(route, async function (ws: ws, req: Request) {
        const diffsFromLastRevision = await nodeDiffed.diffsFromRevision(fromRevision || 0)
        ws.send(JSON.stringify(diffsFromLastRevision))
        const subscription = nodeDiffed.subscribe({
            next: (data) =>
                ws.send(JSON.stringify(data))
        }, true)
        ws.on('close', subscription.unsubscribe)
    })
}