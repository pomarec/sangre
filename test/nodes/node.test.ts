
import { expect } from 'chai'
import { describe } from 'mocha'
import { delayed, Node } from '../../src'
import { expectNodeToEmitInOrder } from '../index.test'

describe("Node", async function () {
    describe('Subscription', async function () {
        it('skip current value', async function () {
            const node = await new Node<string>()
            node.emit('pif')
            delayed(20, () => {
                node.emit("tralala")
            })

            delayed(30, () => {
                node.emit("tralalalilou")
            })

            await expectNodeToEmitInOrder(node, ["tralala", "tralalalilou"])
        })

        it('don\'t skip current value', async function () {
            const node = await new Node<string>()
            node.emit("pif")
            delayed(100, () => {
                node.emit("tralala")
            })

            delayed(220, () => {
                node.emit("tralalalilou")
            })

            await expectNodeToEmitInOrder(node, ["pif", "tralala", "tralalalilou"], false)
        })

        it('Multiple subscribers', async function () {
            const node = await new Node<string>()
            var emitted = new Array<string>()
            const subscription1 = node.subscribe({
                next: (d) => emitted.push(d)
            })
            const subscription2 = node.subscribe({
                next: (d) => emitted.push(d)
            })

            node.emit("pif")

            subscription1.unsubscribe()
            subscription2.unsubscribe()

            expect(emitted).to.be.deep.eq(["pif", "pif"])
        })

        it('Unsibscribe', async function () {
            const node = await new Node<string>()
            var emitted = new Array<string>()
            const subscription = node.subscribe({
                next: (d) => emitted.push(d)
            })

            node.emit("pif")
            subscription.unsubscribe()
            node.emit("paf")

            expect(emitted).to.be.deep.eq(["pif"])
        })

        it('take()', async function () {
            const node = await new Node<string>()
            const takePromise = node.take(2)

            node.emit("pif")
            node.emit("paf")

            expect(await takePromise).to.be.deep.eq(["pif", "paf"])
        })
    })
})

