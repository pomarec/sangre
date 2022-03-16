import { Request } from 'express'
import expressWs from 'express-ws'
import _ from 'lodash'
import { Client } from 'pg'
import ws from 'ws'
import { Node } from './nodes/node'
import { Diffed } from './nodes/operators/diffed'

/**
 * Adds an express route exposing a node through
 * a `websocket` endpoint and a `GET` endpoint.
 */
export async function expressSangre<T>(
    app: expressWs.Application,
    path: string,
    node: Node<T>,
    postgresClient?: Client): Promise<expressWs.Application> {

    app.get(`${path}`, async function (req, res) {
        res.send(JSON.stringify(await node.takeValue(false)))
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
    fromRevisionOpt?: number) {

    const route = `/ws${path}-diffed` + (_.isNil(fromRevisionOpt) ? '' : `-${fromRevisionOpt}`)
    const fromRevision = fromRevisionOpt || 0
    app.ws(route, async function (ws: ws, req: Request) {
        if (nodeDiffed.revision > fromRevision) {
            const diffsFromLastRevision = await nodeDiffed.diffsFromRevision(fromRevision)
            ws.send(JSON.stringify(diffsFromLastRevision))
        }
        const subscription = nodeDiffed.subscribe({
            next: (data) => {
                if (data.revision > fromRevision)
                    ws.send(JSON.stringify(data))
            }
        }, true)
        ws.on('close', subscription.unsubscribe)
    })
}