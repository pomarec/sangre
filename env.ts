export class Env {
    static readonly postgresAddress = process.env['POSTGRES_SERVER'] || 'localhost'
    static readonly postgresUri = `postgresql://postgres:example@${this.postgresAddress}:5432/postgres`

    static readonly realtimeAddress = process.env['REALTIME_SERVER'] || 'localhost'
    static readonly realtimeUri = `ws://${this.realtimeAddress}:4000/socket`
}