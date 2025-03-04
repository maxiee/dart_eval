import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/plugin.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/collection.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/date_time.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/iterator.dart';
import 'core/duration.dart';
import 'core/future.dart';
import 'core/print.dart';

class DartCorePlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:core';

  @override
  void configureForCompile(Compiler compiler) {
    configurePrintForCompile(compiler);
    $Iterable.configureForCompile(compiler);
    $Iterator.configureForCompile(compiler);
    $List.configureForCompile(compiler);
    $Future.configureForCompile(compiler);
    $Duration.configureForCompile(compiler);
    $DateTime.configureForCompile(compiler);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    configurePrintForRuntime(runtime);
    $Iterable.configureForRuntime(runtime);
    $Iterator.configureForRuntime(runtime);
    $List.configureForRuntime(runtime);
    $Duration.configureForRuntime(runtime);
    $Future.configureForRuntime(runtime);
    $DateTime.configureForRuntime(runtime);
  }
}
