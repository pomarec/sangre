
import _ from 'lodash'
import { timer } from 'rxjs'
import { ListSource } from './list'

export class GrowingListSource extends ListSource<number> {
    readonly limit: number
    readonly intervalInMs: number = 100

    constructor(limit = 5, autoClose = false) {
        super([0])
        this.limit = limit

        _.times(this.limit - 1, (i) => {
            timer((i + 1) * this.intervalInMs).subscribe(() => {
                this.insertRow(i + 1)
            })
        })
        if (autoClose)
            timer((this.limit) * this.intervalInMs).subscribe(
                this.close.bind(this)
            )
    }
}
