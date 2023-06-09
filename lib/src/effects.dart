import "package:rxdart/rxdart.dart";

/// A side effect of state change.
typedef Effect = Function() Function(dynamic);

/// A list of [Effect]s.
typedef Effects = List<Effect>;

/// The methods for accessing the [effect] stack
typedef EffectsMethods = (Effects, {Push push, Pull pull});

/// A [Filter] that either allows or prevents an [effect] onto the stack
typedef Filter = bool Function(Function);

/// A [List] of filters
typedef Filters = List<Filter>;

/// Push an [effect] onto the stack.
typedef Push = void Function(Effect);

/// Remove an [effect] from the stack.
typedef Pull = void Function();

/// A [List] of [Filter]s that either allow or prevent certain [effect]s from
/// being pushed onto the effects stack.
final Filters filters = [];
final Effects _effects = [];

/// Methods to access the stack of [effects]. This returns an immutable copy of
/// the stack, a push method and a pull method.
EffectsMethods get effects {
  void pull() => (_effects.isNotEmpty) ? _effects.removeLast() : null;
  void push(Effect effect) {
    for (final filter in filters) {
      if (filter(effect)) return;
    }

    _effects.add(effect);
  }

  return (
    List.unmodifiable(_effects),
    push: push,
    pull: pull,
  );
}

/// Create a side effect that runs whenever its dependencies update.
///
/// Declare a [sideEffect] that will re-run whenever any of its dependencies
/// update their state. Any signals that are referenced within the [effect] will
/// be automatically tracked without an explicit dependency [List] declared.
///
/// An [effect] must only be run once as it will automatically re-run by itself
/// whenever any of its dependencies update. The [sideEffect] must not directly
/// write to any of its dependencies to avoid an infinite loop; as a rule of
/// thumb, a signal's getter and setter methods must not be used within the
/// [effect] at the same time.
void effect(void Function() sideEffect) {
  final (_, :push, :pull) = effects;

  push((_) => () => sideEffect());
  sideEffect();
  pull();
}

/// Explicitly mark the dependencies of a given computation within an [effect].
S on<S, D>(D dependencies, S Function(D dependencies) computation) {
  return untracked<S>(() => computation(dependencies));
}

/// The current [effect] that owns this context.
Effect? get owner {
  final (sideEffects, push: _, pull: _) = effects;
  return sideEffects.lastOrNull;
}

/// Create a [stream] that is derived from a [computation].
///
/// Declare a [computation] whose derived value is used within a [ValueStream].
/// This allows signals to be used where [Stream]s are expected instead, such as
/// with the StreamBuilder widget. In addition this may be used for composition
/// without the use of an [effect].
ValueStream<S> stream<S>(S Function() computation) {
  final derived = BehaviorSubject<S>();

  effect(() => derived.add(computation()));

  return derived.stream;
}

/// Mark a dependency as not tracked by an [effect].
///
/// Mark a dependency to not be tracked by an [effect]. The wrapped dependency
/// will not re-run the [effect] when its value changes but will still return
/// an updated value if the [effect] re-runs and the [untracked] signal has
/// changed its value.
S untracked<S>(S Function() computation) {
  final (_, :push, :pull) = effects;

  push((_) => _noop);
  final result = computation();
  pull();

  return result;
}

/// No operation.
void _noop() {}
