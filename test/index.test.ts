
import { expect } from 'chai'
import { firstValueFrom, Observable, take, toArray } from 'rxjs'

export async function expectObservableToEmit<T>(observable: Observable<T>, value: T) {
    return expectObservableToEmitInOrder(observable, [value])
}

export async function expectObservableToEmitInOrder<T>(observable: Observable<T>, values: Array<T>) {
    var valuesEmitted = await firstValueFrom(
        observable.pipe(take(values.length), toArray())
    )
    return expect(valuesEmitted).to.deep.equal(values)
}

