
import _ from 'lodash'
import { delayed } from '../..'
import { ArraySource } from './array'

/**
 * This is a dummy node that generates data.
 */
export class GrowingArraySource extends ArraySource<number> {
    readonly limit: number
    readonly intervalInMs: number = 100

    constructor(limit = 5, autoClose = false) {
        super()
        this.limit = limit

        _.times(this.limit, (i) => {
            delayed(i * this.intervalInMs, () => {
                this.insertRow(i)
            })
        })
        if (autoClose)
            delayed((this.limit) * this.intervalInMs, this.close.bind(this))
    }
}
