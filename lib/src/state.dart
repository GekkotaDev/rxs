import "package:rxdart/rxdart.dart";

import "effects.dart";

/// Unsafe write with a [Setter].
class EffectWriteError {
  EffectWriteError(Effect effect) {
    throw Exception("""
A signal is being written to within the effect ${effect.toString()} but the
signal was declared with the setting EffectMutation.error. It is unsafe to write
to this signal inside an effect.
""");
  }
}

/// Mark if a signal is allowed to write in an [effect] or disallowed.
enum EffectMutation {
  /// Allow this state to be written in an [effect]. This is the default
  /// setting as [signal] assumes that the user is responsible enough to
  /// avoid infinite loops by mutating data the effect is dependent on.
  yes,

  /// Prevent this state to be written to in an [effect]. Select this option if
  /// it is safe to assume continued operation when an attempt to write to
  /// this state is made by ignoring any writes to it in an [effect].
  no,

  /// Prevent this state to be written to in an [effect]. Select this option if
  /// it is **un**safe to assume continued operation when this state is written
  /// to in an [effect].
  error,
}

/// Derives the next value from the previous value.
typedef DeriveValue<T> = T Function(T previousValue);

/// Access the current state of the [signal].
typedef Accessor<T> = T Function();

/// Set the state of the [signal].
typedef Setter<T> = void Function(T value);

/// A [signal].
typedef Signal<T> = (Accessor<T>, Setter<T>);

/// Mark a [value] as reactive.
///
/// Mark the given [value] as reactive to explicitly allow it to be observed by
/// [effect]s. This returns a [Record] of type [Signal] which exposes an
/// [Accessor] that returns the [value] itself and a [Setter] that reactively
/// updates the state and any side effects.
Signal<S> signal<S>(S value,
    {bool forceUpdates = false,
    EffectMutation effectMutation = EffectMutation.yes}) {
  final state = BehaviorSubject<S>.seeded(value);
  final Set<Function()> dependents = {};

  S getState() {
    final effect = owner;

    if (effect != null) dependents.add(effect(state));

    return state.value;
  }

  void setState(S value) {
    switch (effectMutation) {
      // Allow this state to be written in an effect. This is the default
      // setting as [signal] assumes that the user is responsible enough to
      // avoid infinite loops by mutating data the effect is dependent on.
      case EffectMutation.yes:
        null;
        break;

      // Prevent this state to be written to in an effect. Select this option if
      // it is safe to assume continued operation when an attempt to write to
      // this state is made by ignoring any writes to it in an effect.
      case EffectMutation.no:
        final effect = owner;
        if (effect != null) return;

      // Prevent this state to be written to in an effect. Select this option if
      // it is unsafe to assume continued operation when this state is written
      // to in an effect.
      case EffectMutation.error:
        // TODO: Dedicated error type for writing to effects.
        final effect = owner;
        if (effect != null) throw EffectWriteError(effect);

      // The options .no and .error are typically selected as a way to prevent
      // an infinite loop from occuring.
    }

    switch (forceUpdates) {
      case true:
        state.add(value);
      case false:
        (value == state.value) ? null : state.add(value);
    }

    // ignore: avoid_function_literals_in_foreach_calls
    dependents.forEach((sideEffect) => sideEffect());
  }

  return (getState, setState);
}

/// Derive the next value of a [Signal] from the previous value.
///
/// Set the next value of a [Signal] by reusing the previous value of the given
/// [Signal], giving [derive] a reference to the [signal] and a function that
/// calculates on how to get the [derivedValue]. This may be used when updating
/// a [signal] that keeps track of a mutable object as its state for example.
derive<S>(Signal<S> signal, DeriveValue<S> derivedValue) {
  final (getter, setter) = signal;
  setter(derivedValue(getter()));
}
