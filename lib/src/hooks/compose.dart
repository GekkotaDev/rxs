import "package:rxs/core.dart";

/// A [Composite] of multiple parent [State]s.
class Composite<T> {
  final Computation _computation;
  final ReadOnlyState<T> _state;

  /// The [ReadOnlyState] and [Computation].
  const Composite(this._state, this._computation);

  /// The value of the [Composite].
  T call() => _state();

  /// Mark the [Composite] as no longer needed. It assumes that the value of the
  /// [Composite] will never be used again.
  void dispose() => _computation.dispose();
}

/// A hook to efficiently create a read-only [Composite]d [State] from the
/// [composition] of one or multiple parent states. For more simpler use cases,
/// calling the [composition] as is should be sufficient.
Composite<T> compose<T>(Action<T> composition) {
  final WritableState<T> internalState = state();
  final publicState = ReadOnlyState(internalState);

  final computation = compute(() => internalState.set(composition()));

  return Composite(publicState, computation);
}
