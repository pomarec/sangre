import _ from "lodash"

export async function delayed<T>(ms: number, task: () => T): Promise<T> {
    return new Promise<T>(resolve => setTimeout(
        () => resolve(task())
        , ms))
}

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