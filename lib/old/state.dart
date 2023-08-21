import "package:rxdart/rxdart.dart";

import "compute.dart";
import "types.dart";

/// [State] represents any data that should be remembered during the lifetime of
/// the application's runtime, the [State] classes themselves functioning as a
/// container that enables `rxs` to perform its magic. The value of the wrapped
/// data is subject to change over time, but will not change its type over time
/// unless specified as dynamically typed.
///
/// The data being represented can be of any type and of any complexity. It can
/// be as atomic as a [bool]ean value, or as coarse as a complex class. To read
/// this data, the [State] object must be called.
sealed class State<T> implements Model {
  /// Read the value of the data.
  T call();

  /// The value of the data to remember.
  T get state;
}

/// Data that only provides the user direct access to reading its value; it does
/// not provide the user direct access to writing its value.
final class ReadOnlyState<T> implements State {
  final WritableState<T> _state;

  /// Wrap any [WritableState] as a [ReadOnlyState].
  const ReadOnlyState(WritableState<T> this._state);

  @override
  T call() => state;

  @override
  T get state {
    return _state.state;
  }
}

/// Data that allows the user both direct read and write accesss to its value.
final class WritableState<T> implements State {
  final _state = BehaviorSubject<T>();
  final Set<Computation> _dependents = {};

  /// The value of the data as a [ValueStream].
  late final $ = _state.stream;

  /// The initial value of the data.
  WritableState([T? value]) {
    if (value != null) _state.add(value);
  }

  @override
  T call() => state;

  @override
  T get state {
    final computation = parentComputation;

    if (computation != null) _dependents.add(computation);

    return _state.value;
  }

  /// Update the value of the data.
  set state(T value) {
    _state.add(value);
    _updateDependents();
  }

  /// Inform the computations that they should re-run with the new dependencies'
  /// values.
  void _updateDependents() {
    /*
      We keep a copy of the current dependents that represents the next state of
      the dependents. We do this to simplify the mental model of iterating over
      the current dependents whose length may vary (such as through the removal
      of a dependent).
     */
    final nextDependents = {..._dependents};

    _dependents.forEach((computation) {
      if (computation.cleanup) {
        nextDependents.remove(computation);
        return;
      }

      computation();
    });

    if (_dependents.length != nextDependents.length) {
      _dependents.clear();
      _dependents.addAll(nextDependents);
    }
  }

  /// Set the value of the data. The new [value] must be of the same type as the
  /// previous [value].
  void set(T value) => state = value;

  /// [update] the data with a new value by deriving it from the previous value.
  /// The new value of the data is considered to be a different object compared
  /// to the previous value; if it is important that both of them must stay as
  /// the same object, consider to [mutate] the value instead.
  void update(T Function(T) derivation) => state = derivation(state);

  /// Change the value of the data without replacing the previous state with the
  /// new state. This method must not be used for data that is immutable such as
  /// primitive data types (for example: [String]s, [num]s, [bool]s, etc.).
  void mutate(void Function(T) mutator) {
    mutator(state);
    _updateDependents();
  }
}

/// Declare the given [data] as [State]ful.
WritableState<T> state<T>([T? data]) => WritableState<T>(data);
