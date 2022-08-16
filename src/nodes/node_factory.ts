import _ from 'lodash'
import { Node } from './node'

export class NodeFactory {
    static nodes = new Array<Node<any>>()

    /**
     * Provides a factory pattern to existing classes.
     * Current implementation caches objects that positively `compareForNew()`
     * 
     * /!\ : NodeFactory forces classes and their children to share the same first
     *  args in their constructor and compareForNew()
     */
    static factorizeClass<T extends Node<any>>(
        target: {
            new(...args: Array<any>): T,
            /**
             * Returns true if `node` is considered as beeing the same node
             * that would be constructed with `args` as constructor parameters.
             */
            compareForNew(node: T, ...args: Array<any>): boolean
        }
    ) {
        const originalConstructor = target
        var newConstructor: any = function (...args: Array<any>) {
            const existing = _.find(NodeFactory.nodes,
                n => originalConstructor.compareForNew(n as T, ...args)
            )
            if (existing)
                return existing
            const instance = new originalConstructor(...args)
            NodeFactory.nodes.push(instance)
            return instance
        }
        newConstructor.prototype = originalConstructor.prototype
        return newConstructor
    }
}

