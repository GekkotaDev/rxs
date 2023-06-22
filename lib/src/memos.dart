import "package:rxdart/rxdart.dart";

import "effects.dart";
import "signals.dart";

/// The cached values of [Dependencies].
typedef Cache<D> = Set<D>;

/// Signals that a computation is dependent on.
typedef Dependencies<D> = Set<BehaviorSubject<D>>;

/// A [Stream] that encapsulates the result of a computation.
typedef Result<R> = ValueStream<R>;

/// Efficiently create a derived value from a [computation].
///
/// [computedStream] provides a solution to efficiently use a value derived from
/// a composition of [signal]s. It returns a [ValueStream] whose value only gets
/// updated when both its dependencies update and when the result of the
/// [computation] is [notEqual] to the previous value of the [ValueStream].
///
/// [computedStream] should be used to assist in minimizing running expensive
/// [computation]s and not as a way to magically optimize your codebase. In
/// addition to prevent unnecessary UI updates, the value of [ValueStream] only
/// updates when a [computation]'s dependencies update and when the result of
/// the [computation] is [notEqual] to the value of [ValueStream].
///
/// This behaviour is enabled by default but it can be disabled by default by
/// setting [notEqual] to [false]. This makes [computedStream] update the
/// [ValueStream] regardless of the result of the [computation].
Result<R> computedStream<R, D>(R Function() computation,
    {bool notEqual = true}) {
  /// The cached values of the [dependencies].
  final (cached, setCached) = signal<Cache<D>>({});

  /// The signals that the [computation] is dependent on.
  final Dependencies<D> dependencies = {};

  /// Stream that encapsulates the resulting value.
  final stream = BehaviorSubject<R>();

  final (_, :push, :pull) = effects;

  push((dependency) {
    if (dependency is BehaviorSubject<D>) dependencies.add(dependency);

    // Record the current state of the dependencies...
    final Set<D> dependenciesState = {
      for (final dependency in dependencies) dependency.value
    };

    // ... and pass the state to the cache.
    setCached({...dependenciesState});

    // The effect.
    return () {
      final Set<D> dependenciesState = {
        for (final dependency in dependencies) dependency.value
      };

      if (cached() != dependenciesState) {
        final result = computation();

        if (!(notEqual && result == stream.value)) stream.add(result);

        setCached(dependenciesState);
      }
    };
  });

  stream.add(computation());
  pull();

  return stream.stream;
}

/// Efficiently create a derived value from a [computation].
///
/// [computed] provides a solution to efficiently use a value derived from
/// [signal]s. It returns an [Accessor] to the derived value which allows for
/// reactive read-only access to the derived value.
///
/// [computed] presents similar strategies and API to [computedStream] with the
/// difference primarily that [computed] provides the user with an [Accessor]
/// instead of a [ValueStream].
Accessor<R> computed<R, D>(R Function() computation, {bool notEqual = true}) {
  final stream = computedStream(computation, notEqual: notEqual);
  final (result, setResult) = signal(stream.value);

  stream.listen((value) => setResult(value));

  return result;
}
