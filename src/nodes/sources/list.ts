import _ from 'lodash'
import { Node } from '../node'

export class ListSource<Row> extends Node<Array<Row>> {
    private state: Array<Row>

    constructor(initialValue: Array<Row> = []) {
        super(initialValue)
        this.state = initialValue
    }

    insertRow(row: Row) {
        console.log("Inserting " + row)
        this.setRows([...this.state, row])
    }

    setRows(rows: Array<Row>) {
        this.state = [...rows]
        this.subject$.next(this.state)
    }

    updateRows(map: ((_: Row) => Row | undefined)) {
        this.setRows(
            [...this.state].filter(map).filter(
                (e) => !_.isNil(e)
            )
        )
    }
}
