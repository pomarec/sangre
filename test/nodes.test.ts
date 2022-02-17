
import _ from 'lodash'
import { describe, it } from 'mocha'
import { delayed, GrowingListSource, NodeOperator1Input, NodeOperator2Input } from '../src/index'
import { expectNodeToEmitInOrder } from './index.test'

describe("Sources", async function () {
    it('Growling list source', async function () {
        const source = await new GrowingListSource(3)
        await expectNodeToEmitInOrder(source, [
            [0],
            [0, 1],
            [0, 1, 2],
        ])
    })
})


describe("Operators", async function () {
    it('Combine growing list source with count operator', async function () {
        const chain = await new NodeOperator1Input(
            async (values) => values.length,
            new GrowingListSource(3),
        )
        await expectNodeToEmitInOrder(chain, [1, 2, 3])
    })

    it('Combine growing list source with count operator (with await)', async function () {
        const chain = await new NodeOperator1Input(
            async (values) => values.length,
            await new GrowingListSource(3),
        )
        await expectNodeToEmitInOrder(chain, [1, 2, 3])
    })

    it('Combine fast growing list source with an async operator', async function () {
        const chain = await new NodeOperator1Input(
            async (a) => await delayed(50, () => a.length * 2),
            new GrowingListSource(3),
        )
        await expectNodeToEmitInOrder(chain, [2, 4, 6])
    })

    it('Combine slow growing list source with an async operator', async function () {
        const chain = await new NodeOperator1Input(
            async (a) => await delayed(1500, () => a.length * 2),
            new GrowingListSource(3),
        )
        await expectNodeToEmitInOrder(chain, [2, 4, 6])
    })

    it('Combine two growing list source with count operator', async function () {
        const chain = await new NodeOperator2Input(
            async (a, b) => a.length + b.length,
            new GrowingListSource(3),
            new GrowingListSource(4),
        )
        await expectNodeToEmitInOrder(
            chain,
            [2, 3, 4, 5, 6, 7]
        )
    })

    it('React properly to source change', async function () {
        const source = await new GrowingListSource(3)
        const chain = await new NodeOperator1Input(
            async (a) => _.sum(a),
            source,
        )

        delayed(source.intervalInMs * 5, () => source.insertRow.bind(source)(5))
        await expectNodeToEmitInOrder(chain, [0, 1, 3, 8])
    })
})
