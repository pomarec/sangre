import 'dart:io' show Platform;

final postgresServerAddress =
    Platform.environment['POSTGRES_SERVER'] ?? '127.0.0.1';
final realtimeServerAddress =
    Platform.environment['REALTIME_SERVER'] ?? '127.0.0.1';
