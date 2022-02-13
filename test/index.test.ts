
import { expect } from 'chai'
import { firstValueFrom, Observable, take, toArray } from 'rxjs'

export async function expectObservableToEmit<T>(observable: Observable<T>, value: T) {
    return expectObservableToEmitInOrder(observable, [value])
}

export async function expectObservableToEmitInOrder<T>(observable: Observable<T>, values: Array<T>) {
    const nthValues = observable.pipe(take(values.length), toArray())
    const valuesEmitted = await firstValueFrom(nthValues)
    return expect(valuesEmitted).to.deep.equal(values)
}

export async function delayed<T>(ms: number, value: T): Promise<T> {
    return new Promise<T>(resolve => setTimeout(
        () => resolve(value)
        , ms))
}