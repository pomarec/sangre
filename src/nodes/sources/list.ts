import _ from 'lodash'
import { Node } from '../node'

export class ListSource<Row> extends Node<Array<Row>> {
    insertRow(row: Row) {
        // console.log("Inserting " + row)
        this.setRows([...(this.value || []), row])
    }

    setRows(rows: Array<Row>) {
        // console.log("set " + rows)
        this.emit([...rows])
    }

    updateRows(map: ((_: Row) => Row | undefined)) {
        this.setRows(
            [...(this.value || [])].filter(map).filter(
                (e) => !_.isNil(e)
            )
        )
    }
}
