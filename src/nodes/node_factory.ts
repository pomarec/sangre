import _ from 'lodash'
import { Node } from './node'

export class NodeFactory {
    static nodes = new Array<Node<any>>()

    static factorizeClass<T extends Node<any>>(
        target: {
            new(...args: Array<any>): T,
            compareForNew(node: T, ...args: Array<any>): boolean
        }
    ) {
        const original = target
        var newConstructor: any = function (...args: Array<any>) {
            const existing = _.find(NodeFactory.nodes,
                n => original.compareForNew(n as T, ...args)
            )
            if (existing)
                return existing
            const instance = new original(...args)
            NodeFactory.nodes.push(instance)
            return instance
        }
        newConstructor.prototype = original.prototype
        return newConstructor
    }
}

