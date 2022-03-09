import _ from 'lodash'
import { Node } from '../node'

/**
 * Node emiting an array of data.
 * Simple helper with few helping methods.
 */
export class ArraySource<Row> extends Node<Array<Row>> {
    insertRow(row: Row) {
        // console.log("ArraySource.insertRow " + JSON.stringify(row))
        this.setRows([...(this.lastValue || []), row])
    }

    /**
     * @param map pure function to apply to each row. It must return a row.
     * If it returns undefined for a row, the row will be deleted.
     */
    updateRows(map: ((_: Row) => Row | undefined)) {
        this.setRows(
            ([...(this.lastValue || [])].map(map) as Array<Row | undefined>).filter(
                (e) => !_.isNil(e)
            ) as Array<Row>
        )
    }

    setRows(rows: Array<Row>) {
        // console.log("ArraySource.setRows " + JSON.stringify(rows))
        this.emit([...rows])
    }
}
