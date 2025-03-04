import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/type.dart';

import '../../../dart_eval_bridge.dart';

typedef EvalCallableFunc = $Value? Function(Runtime runtime, $Value? target, List<$Value?> args);

abstract class EvalCallable {
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args);
}

abstract class EvalFunction implements $Instance, EvalCallable {
  const EvalFunction();

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'call':
        return this;
      default:
        throw EvalUnknownPropertyException(identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw EvalUnknownPropertyException(identifier);
  }

  @override
  dynamic get $value => throw UnimplementedError();

  @override
  dynamic get $reified => throw UnimplementedError();
}

class EvalFunctionPtr extends EvalFunction {
  EvalFunctionPtr(this.$prev, this.offset, this.requiredPositionalArgCount, this.positionalArgTypes,
      this.sortedNamedArgs, this.sortedNamedArgTypes);

  final int offset;
  final List<Object?>? $prev;
  final int requiredPositionalArgCount;
  final List<RuntimeType> positionalArgTypes;
  final List<String> sortedNamedArgs;
  final List<RuntimeType> sortedNamedArgTypes;

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    runtime.args = [if ($prev != null) $prev, ...args];
    runtime.bridgeCall(offset);
    return runtime.returnValue as $Value?;
  }

  @override
  int get $runtimeType => RuntimeTypes.functionType;

  @override
  String toString() {
    return 'EvalFunctionPtr{offset: $offset, prev: ${$prev == null ? 'null' : RuntimeException.formatStackSample($prev!, 4)}, '
        'rPAC: $requiredPositionalArgCount, '
        'pAT: $positionalArgTypes, '
        'sNA: $sortedNamedArgs, '
        'sNAT: $sortedNamedArgTypes}';
  }
}

class EvalStaticFunctionPtr extends EvalFunction {
  EvalStaticFunctionPtr(this.$this, this.offset);

  final int offset;
  final $Instance? $this;

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    runtime.args = args;
    runtime.bridgeCall(offset);
    return runtime.returnValue as $Value?;
  }

  @override
  int get $runtimeType => RuntimeTypes.functionType;
}

class $Function extends EvalFunction {
  const $Function(this.func);

  final EvalCallableFunc func;

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return func(runtime, target, args);
  }

  @override
  int get $runtimeType => RuntimeTypes.functionType;
}
