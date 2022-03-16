import _ from "lodash"

/**
 * Wrapper around Promise to execute `task` in `ms` milliseconds.
 */
export async function delayed<T>(ms: number, task: () => T): Promise<T> {
    return new Promise<T>(resolve => setTimeout(
        () => resolve(task())
        , ms))
}

/**
 * Makes sure each `task` queued (`this.queue()`) are executed serially
 * in the same order as `this.queue()` was called. `task`s can be async,
 * `this` makes sure a task is done before starting the next one.
 */
export class SerialExecutionQueue {
    private remainingExecutions = new Array<() => Promise<void>>()
    private isUnqueing = false

    async queue(task: () => Promise<void>) {
        this.remainingExecutions.push(task)
        this.unqueue()
    }

    private async unqueue() {
        if (!this.isUnqueing && !_.isEmpty(this.remainingExecutions)) {
            this.isUnqueing = true
            const task = this.remainingExecutions.shift()
            if (task != undefined)
                await task()
            this.isUnqueing = false
            this.unqueue()
        }
    }
}