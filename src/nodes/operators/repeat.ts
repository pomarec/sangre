
import _ from "lodash"
import { Node } from "../node"
import { Node1Input } from '../node_with_input/node_1_input'

/**
 * Repeats the last data of its input
 */
export class NodeRepeat<T> extends Node1Input<T, T> {
    private timer?: NodeJS.Timer
    readonly intervalInMs: number
    lastInput?: T

    constructor(nodeI1: Node<T>, intervalInMs: number = 5000) {
        super(nodeI1)
        this.intervalInMs = intervalInMs
        this.resetTimer()
    }

    resetTimer(stop = false) {
        if (!_.isNil(this.timer))
            clearInterval(this.timer)
        if (!stop)
            this.timer = setInterval(this.tick.bind(this), this.intervalInMs)
    }

    private async tick() {
        const t = this
        this.executionQueue.queue(
            async () => {
                const inputs = _.clone(t.lastInput)
                if (!_.isNil(inputs)) {
                    const output = await t.process(inputs, true)
                    t.emit(output)
                }
            }
        )
    }

    async process(input: T, dontMemorize = false): Promise<T> {
        if (!dontMemorize)
            this.lastInput = input
        return input
    }

    async close() {
        this.resetTimer(true)
        await super.close()
    }

    /** See NodeFactory.factorizeClass */
    static compareForNew(
        node: NodeRepeat<any>,
        nodeI1: Node<any>,
        intervalInMs: number = 5000,
        ...args: Array<any>
    ): boolean {
        return super.compareForNew(node, nodeI1)
            && _.isEqual(intervalInMs, node.intervalInMs)
    }
}

