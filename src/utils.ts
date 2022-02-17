
export async function delayed<T>(ms: number, task: () => T): Promise<T> {
    return new Promise<T>(resolve => setTimeout(
        () => resolve(task())
        , ms))
}