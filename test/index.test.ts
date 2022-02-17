
import { expect } from 'chai'
import { Node } from '../src'


export async function expectNodeToEmit<T>(node: Node<T>, value: T) {
    return expectNodeToEmitInOrder(node, [value])
}

export function expectNodeToEmitInOrder<T>(node: Node<T>, values: Array<T>): Promise<void> {
    return new Promise((resolve, reject) => {
        var emittedValues = new Array<T>()
        const subscription = node.subscribe({
            next: (data) => {
                emittedValues.push(data)
                if (emittedValues.length >= values.length) {
                    subscription.unsubscribe()
                    try {
                        expect(emittedValues).to.be.deep.equals(values)
                        resolve()
                    } catch (e) {
                        reject(e)
                    }
                }
            }
        })
    })
}
