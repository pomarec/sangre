import _ from 'lodash'
import { Node } from '../node'

export class ListSource<Row> extends Node<Array<Row>> {
    insertRow(row: Row) {
        // console.log("ListSource.insertRow " + JSON.stringify(row))
        this.setRows([...(this.value || []), row])
    }

    updateRows(map: ((_: Row) => Row | undefined)) {
        this.setRows(
            ([...(this.value || [])].map(map) as Array<Row | undefined>).filter(
                (e) => !_.isNil(e)
            ) as Array<Row>
        )
    }

    setRows(rows: Array<Row>) {
        // console.log("ListSource.setRows " + JSON.stringify(rows))
        this.emit([...rows])
    }
}
