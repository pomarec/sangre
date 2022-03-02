
import chai, { expect } from 'chai'
import chaiHttp from 'chai-http'
import { Node } from '../src'

chai.use(chaiHttp)

export async function expectNodeToEmit<T>(node: Node<T>, value: T) {
    return expectNodeToEmitInOrder(node, [value])
}

export async function expectNodeToEmitInOrder<T>(node: Node<T>, values: Array<T>): Promise<void> {
    const results = await node.take(values.length)
    expect(results).to.be.deep.equals(values)
}
