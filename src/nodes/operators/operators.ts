import _ from "lodash"
import { Node, Node1Input, Node2Input } from "../node"

/** A node operator is a node which process() is based on a operator.
 * 
 * An operator is a pure function.
*/
export class NodeOperator1Input<I1, Output> extends Node1Input<I1, Output> {
    operation: (_: I1) => Promise<Output>

    constructor(
        operation: (_: I1) => Promise<Output>,
        nodeI1: Node<I1>,
    ) {
        super(nodeI1)
        this.operation = operation
    }

    async process(i1: I1): Promise<Output> {
        // console.log("Processing " + i1)
        return await this.operation(i1)
    }
}

export class NodeOperator2Input<I1, I2, Output> extends Node2Input<I1, I2, Output> {
    operation: (i1: I1, i2: I2) => Promise<Output>

    constructor(
        operation: (i1: I1, i2: I2) => Promise<Output>,
        nodeI1: Node<I1>,
        nodeI2: Node<I2>,
    ) {
        super(nodeI1, nodeI2)
        this.operation = operation
    }

    async process(i1: I1, i2: I2): Promise<Output> {
        // console.log("Processing " + i1 + i2)
        return await this.operation(i1, i2)
    }
}


export class NodeOperator1InputInterval<I1, Output> extends NodeOperator1Input<I1, Output> {
    private timer?: NodeJS.Timer
    lastInput?: I1

    constructor(operation: (_: I1) => Promise<Output>, nodeI1: Node<I1>, interval: number = 5000) {
        super(operation, nodeI1)
        this.timer = setInterval(this.tick.bind(this), interval)
    }

    async tick() {
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

    async process(i1: I1, dontMemorize = false): Promise<Output> {
        if (!dontMemorize)
            this.lastInput = i1
        return await super.process(i1)
    }

    async close() {
        if (!_.isNil(this.timer))
            clearInterval(this.timer)
        await super.close()
    }
}

