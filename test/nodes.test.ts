
import { describe, it } from 'mocha'
import { Observable } from 'rxjs'
import { GrowingListSource, NodeOperator1Input } from '../src/index'
import { expectObservableToEmitInOrder } from './index.test'

describe("Sources", () => {
    it('Growling list source', async () => {
        const source = await new GrowingListSource(3)
        await expectObservableToEmitInOrder(source.subject as Observable<Array<number>>, [
            [0],
            [0, 1],
            [0, 1, 2],
        ])
    })
})


describe("Operators", () => {
    it('Combine growing list source with count operator', async () => {
        const chain = await new NodeOperator1Input(
            async (values) => values.length,
            new GrowingListSource(3),
        )
        await expectObservableToEmitInOrder(chain.subject, [1, 2, 3])
    })
})