import 'operator.dart';

class CountOperator extends Operator<Iterable, int> {
  @override
  int process(Iterable input) {
    return input.length;
  }
}
