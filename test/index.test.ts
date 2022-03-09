
import chai, { expect } from 'chai'
import chaiHttp from 'chai-http'
import { Node } from '../src'

chai.use(chaiHttp)

export async function expectNodeToEmit<T, V extends T>(node: Node<T>, value: V) {
    return expectNodeToEmitInOrder(node, [value])
}

export async function expectNodeToEmitInOrder<T, V extends T>(node: Node<T>, values: Array<V>, skipCurrentValue = true): Promise<void> {
    const results = await node.take(values.length, skipCurrentValue)
    expect(results).to.be.deep.equals(values)
}
