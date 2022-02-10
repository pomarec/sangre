
import _ from 'lodash'
import { timer } from 'rxjs'
import { ListSource } from './list'

export class GrowingListSource extends ListSource<number> {
    readonly limit: number

    constructor(limit = 5) {
        super([0])
        this.limit = limit

        _.times(this.limit - 1, (i) => {
            timer((i + 1) * 100).subscribe(() => {
                this.insertRow(i + 1)
            })
        })
        timer((this.limit) * 3000).subscribe(() => this.close())
    }
}
