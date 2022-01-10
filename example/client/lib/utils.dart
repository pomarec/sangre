import 'dart:math';

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();

String randomString([int length = 15]) => String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => _chars.codeUnitAt(
          _rnd.nextInt(_chars.length),
        ),
      ),
    );

extension FoldStream<T> on Stream<T> {
  Stream<S> foldStream<S>(
    S initialValue,
    S Function(S previous, T element) combine,
  ) {
    S lastValue = initialValue;
    return map((T e) {
      lastValue = combine(lastValue, e);
      return lastValue;
    });
  }

  Stream<List<T>> accumulate() {
    final lastValue = List<T>.empty(growable: true);
    return map((T e) {
      lastValue.add(e);
      return List.from(lastValue);
    });
  }
}
