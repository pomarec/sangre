import 'dart:async';
import 'dart:math';

import 'package:meta/meta.dart';

mixin AsyncInitMixin<T extends Future> implements Future {
  bool? _isReady;

  Future<T>? _onReady;

  bool get isReady => _isReady ?? false;

  Future<T> get onReady => _onReady ??= _init();

  Future<T> _init() async {
    await init();
    _isReady = true;
    return this as T;
  }

  @override
  Stream<T> asStream() => onReady.asStream();

  @override
  Future<T> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) =>
      onReady.catchError(onError, test: test);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) =>
      onReady.then(onValue, onError: onError);

  @override
  Future<T> timeout(
    Duration timeLimit, {
    FutureOr Function()? onTimeout,
  }) =>
      onReady.timeout(
        timeLimit,
        onTimeout: onTimeout as FutureOr<T> Function(),
      );

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) =>
      onReady.whenComplete(action);

  @protected
  Future init() async {}
}

class _Example with AsyncInitMixin {
  String? data;

  _Example({this.data});

  @override
  Future<void> init() async {
    print('init: A ${DateTime.now()}, now data is $data');
    await Future.delayed(Duration(seconds: 1));
    data = '${Random().nextInt(99999999)}';
    print('init: B ${DateTime.now()}, new data is $data');
  }
}
