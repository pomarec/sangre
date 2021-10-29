import 'dart:async';

import 'operators/operator.dart';
import 'sources/source.dart';

class Vena<SourceT, Output> {
  final StreamController<Output> egressController = StreamController();
  Stream<Output> get egress => egressController.stream;

  final List<Operator> operators;
  final Source<SourceT> source;

  Vena(this.source, this.operators) {
    Stream flow = source.egress;
    for (Operator o in operators) {
      flow = flow.map(o.process);
    }
    flow.pipe(egressController);
  }
}
