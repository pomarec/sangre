
import { describe, it } from 'mocha'
import { GrowingArraySource } from '../../../src/index'
import { expectNodeToEmitInOrder } from '../../index.test'

describe("Growling array source", async function () {
    it('nominal', async function () {
        const source = await new GrowingArraySource(3)
        await expectNodeToEmitInOrder(source, [
            [0],
            [0, 1],
            [0, 1, 2],
        ])
    })
})