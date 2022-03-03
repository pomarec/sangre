
import _ from 'lodash'
import { delayed } from '../..'
import { ListSource } from './list'

export class GrowingListSource extends ListSource<number> {
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
