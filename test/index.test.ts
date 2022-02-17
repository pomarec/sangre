
import { expect } from 'chai'
import { Node } from '../src'


export async function expectNodeToEmit<T>(node: Node<T>, value: T) {
    return expectNodeToEmitInOrder(node, [value])
}

export async function expectNodeToEmitInOrder<T>(node: Node<T>, values: Array<T>): Promise<void> {
    expect(await node.take(values.length)).to.be.deep.equals(values)
}
