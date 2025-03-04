[![Build status](https://img.shields.io/github/actions/workflow/status/ethanblake4/dart_eval/dart.yml?branch=master)](https://github.com/ethanblake4/dart_eval/actions/workflows/dart.yml)
[![Star on Github](https://img.shields.io/github/stars/ethanblake4/dart_eval?logo=github&colorB=orange&label=stars)](https://github.com/ethanblake4/dart_eval)
[![License: BSD-3](https://img.shields.io/badge/license-BSD3-purple.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![Web example](https://img.shields.io/badge/web-example-blue.svg)](https://ethanblake.xyz/evalpad)

`dart_eval` is an extensible bytecode compiler and interpreter for the Dart language, 
written in Dart, enabling dynamic codepush for Flutter and Dart AOT.

| dart_eval    | [![pub package](https://img.shields.io/pub/v/dart_eval.svg?label=dart_eval&color=teal)](https://pub.dev/packages/dart_eval)          |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| flutter_eval | [![pub package](https://img.shields.io/pub/v/flutter_eval.svg?label=flutter_eval&color=blue)](https://pub.dev/packages/flutter_eval) |

The primary aspect of `dart_eval`'s goal is to be interoperable with real 
Dart code. Classes created in 'real Dart' can be used inside the interpreter 
with a wrapper, and classes created in the interpreter can be used outside it 
by creating an interface and bridge class.

dart_eval's compiler is powered under the hood by the Dart 
[analyzer](https://pub.dev/packages/analyzer), so it achieves 100% correct and 
up-to-date parsing (although compilation and evaluation aren't quite there yet.)

Currently dart_eval implements a decent amount of the Dart spec, but there 
are still missing features like generators, Sets and extension methods.
In addition, much of the standard library hasn't been implemented.
## Usage

A basic usage example of the `eval` method, which is a simple shorthand to
execute Dart code at runtime:

```dart
import 'package:dart_eval/dart_eval.dart';

void main() {
  print(eval('2 + 2')); // -> 4
  
  final program = '''
      class Cat {
        Cat(this.name);
        final String name;
        String speak() {
          return name;
        }
      }
      String main() {
        final cat = Cat('Fluffy');
        return cat.speak();
      }
  ''';
  
  print(eval(program, function: 'main')); // -> 'Fluffy'
}
```

## Compiling to a file

For most use-cases, it's recommended to pre-compile your Dart code to EVC bytecode,
to avoid runtime compilation overhead. (This is still runtime code execution, it's
just executing a more efficient code format.)

This also allows you to compile multiple files into a single bytecode block.

```dart
import 'dart:io';
import 'package:dart_eval/dart_eval.dart';

void main() {
  final compiler = Compiler();
  
  final program = compiler.compile({'my_package': {
    'main.dart': '''
      int main() {
        var count = 0;
        for (var i = 0; i < 1000; i = i + 1) {
          count = count + i;
        }
        return count;
      }
    '''
  }});
  
  final bytecode = program.write();
  
  final file = File('program.evc');
  file.writeAsBytesSync(bytecode);
}
```

You can then load and execute the program later:

```dart
import 'dart:io';
import 'package:dart_eval/dart_eval.dart';

void main() {
  final file = File('program.evc');
  final bytecode = file
      .readAsBytesSync()
      .buffer
      .asByteData();
  
  final runtime = Runtime(bytecode);
  runtime.setup();
  print(runtime.executeLib('package:my_package/main.dart', 'main')); // -> 499500
}
```

## Using the CLI
The dart_eval CLI allows you to compile existing Dart projects to EVC bytecode,
as well as run and inspect EVC bytecode files.

To enable the CLI globally, run:

`dart pub global activate dart_eval`

### Compiling a project

The CLI supports compiling standard Dart projects, although installed packages
in `pubspec.yaml` are not currently supported. To compile a project, run:

```bash
cd my_project
dart_eval compile -o program.evc
```

This will generate an EVC file in the current directory called `program.evc`.

The compiler also supports compiling with JSON-encoded bridge bindings. To add
these, create a folder in your project root called `.dart_eval`, add a
`bindings` subfolder, and place JSON binding files there. The compiler will
automatically load these bindings and make them available to your project.

### Running a program

To run the generated EVC file, use:

`dart_eval run program.evc -p package:my_package/main.dart -f main`

Note that the run command does *not* support bindings, so any file compiled
with bindings will need to be run in a specialized runner that includes the
necessary runtime bindings.

### Inspecting an EVC file

You can dump the op codes of an EVC file using:

`dart_eval dump program.evc`

## Return values

In most cases, dart_eval will return a subclass of `$Value` such as `$int`
or `$String`. These 'boxed types' have information about what they are and 
how to modify them, and like all `$Value`s you can access their underlying
value with the `$value` property. 

However, when working with primitive value types  (int, string etc.) you may find 
that dart_eval returns the underlying primitive directly. This is due to an 
internal performance optimization. If you don't like the inconsistency, you can
change the return type on the function signature to `dynamic` which will force 
dart_eval to always box the value before it's returned.

## Interop

Interop is a general term for methods in which we can access, use, and modify data
from dart_eval in Dart. Enabling this access is a high priority for dart_eval.

There are three main levels of interop:
* Value interop
* Wrapper interop
* Bridge interop

### Value interop

Value interop is the most basic form, and happens automatically whenever the Eval
environment is working with an object backed by a real Dart value. (Therefore, an
int and a string are value interop enabled, but a class created inside Eval isn't.)
To access the backing object of an `$Value`, use its `$value` property. If the
value is a collection like a Map or a List, you can use its `$reified` property
to resolve the values it contains.

To support value interop, a class need simply to implement `$Value`, or extend
`$Value<T>`.

### Wrapper interop

Using a wrapper enables the Eval environment to access the functions and fields on
a class created outside Eval. It's much more powerful than value interop, and
simpler than bridge interop, making it a great choice for certain use cases. To use
wrapper interop, create a class that implements `$Instance`. Then, override 
`$getProperty` / `$setProperty` to define your fields and methods.

### Bridge interop

Bridge interop enables the most functionality: Not only can Eval access the fields
of an object, but it can also be extended, allowing you to create subclasses within Eval
and use them outside of Eval. For example, bridge interop is used by 
Flightstream to enable the creation of custom Flutter widgets. 

However, it is also somewhat difficult to use, and it can't be used to wrap existing 
objects created in code you don't control. (For utmost flexibility at the expense of 
simplicity, you can use both bridge and wrapper interop.) Since Bridge interop requires
a lot of boilerplate code, in the future I will be creating a solution for 
code-generation of that boilerplate.

Bridge interop also requires that the class definitions be available at both compile-time 
and runtime. (If you're just using the `eval` method, you don't have to worry about
this.)

An example featuring bridge interop is available in the `example` directory.

## Plugins

To configure interop for compilation and runtime, it's recommended to create an
`EvalPlugin` which enables reuse of Compiler instances. Basic example:
  
```dart
class MyAppPlugin implements EvalPlugin {
  @override
  String get identifier => 'package:myapp';

  @override
  void configureForCompile(Compiler compiler) {
    compiler.defineBridgeTopLevelFunction(BridgeFunctionDeclaration(
      'package:myapp/functions.dart',
      'loadData',
      BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.objectType)), params: [])
    ));
    compiler.defineBridgeClass($CoolWidget.$declaration);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc('package:myapp/functions.dart', 'loadData', 
        (runtime, target, args) => $Object(loadData()));
    runtime.registerBridgeFunc('package:myapp/classes.dart', 'CoolWidget.', $CoolWidget.$new);
  }
}
```

You can then use this plugin with `Compiler.addPlugin` and `Runtime.addPlugin`.
## Contributing

See [Contributing](https://github.com/ethanblake4/dart_eval/blob/master/CONTRIBUTING.md).

## FAQ

### How does it work?

`dart_eval` is a fully Dart-based implementation of a bytecode compiler and runtime. 
First, the Dart analyzer is used to parse the code into an AST (abstract syntax tree). 
Then, the compiler looks at each of the declarations in turn, and recursively compiles
to a linear bytecode format.

For evaluation dart_eval uses Dart's optimized dynamic dispatch. This means each bytecode
is actually a class implementing `EvcOp` and we call its `run()` method to execute it.
Bytecodes can do things like push and pop values on the stack, add numbers, and jump to 
other places in the program, as well as more complex Dart-specific operations like 
create a class.

### Does it support Flutter?

Yes! Check out [flutter_eval](https://pub.dev/packages/flutter_eval).

### How fast is it?

Preliminary testing shows that, for simple code, `dart_eval` running in AOT-compiled Dart 
is around 12x slower than standard AOT Dart and is approximately on par with a language like 
Ruby.
For many use cases this actually doesn't matter too much, e.g. in the case of Flutter 
where the app spends 99% of its performance budget in the Flutter framework itself.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/ethanblake4/dart_eval/issues
