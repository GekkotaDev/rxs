import "package:rxs/src/types.dart";
import "stack.dart";

/// No operation. Used internally by [ref].
final noop = Computation(() {});

/// Immediately [compute]s the provided [action]. The [action] is a plain Dart
/// function that `rxs` will automatically treat as "live", where it will be
/// eagerly re[compute]d whenever any of its stateful dependencies is updated.
///
/// Any stateful data that has not been read from within the [action] will not
/// be considered as a dependency until it has been read, for example if the
/// stateful data is within a conditional branch.
///
/// Optionally the [action] may return a [CleanupAction] that runs when it is
/// disposed.
Computation compute(ComputeAction action) {
  final computation = Computation(action);
  computation();

  return computation;
}

/// Create a plain reference to the given [data] within a computation. A [ref]
/// informs any [compute] functions that they should not depend on the [data]
/// wrapped within the [ref].
T ref<T>(T Function() data) {
  Computations.push(noop);
  final value = data();
  Computations.pop();

  return value;
}

/// A utlity function to explicitly declare the [dependencies] of the given
/// [action]. State used within the [action] that are not part of the [action]'s
/// [dependencies] will not trigger a re[compute] since the [action] has been
/// wrapped within a [ref].
S on<S, D>(D dependencies, S Function(D dependencies) action) =>
    ref<S>(() => action(dependencies));
