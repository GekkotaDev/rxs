import "package:rxs/src/types.dart";

/// The [Computations] namespace manages the stack of the currently running
/// [Computation]s. The [Computations] namespace exposes a small API to read and
/// write to this stack, although this is preferably not used outside of the
/// core APIs of `rxs`.
class Computations {
  static final List<Computation> _computations = [];

  /// Pop the [Computation] from the stack.
  static List<Computation> pop() {
    if (_computations.isNotEmpty) _computations.removeLast();
    return List.unmodifiable(_computations);
  }

  /// Push a [Computation] into the stack.
  static List<Computation> push(Computation computation) {
    _computations.add(computation);
    return List.unmodifiable(_computations);
  }
}

/// A [Computation] describes a live action that automatically runs in response
/// to when state inside the [Computation] updates. These can be thought of as
/// side effects that occur when state objects update their data.
///
/// They may optionally provide a [CleanupAction] that runs when the effect is
/// marked for manual cleanup.
class Computation {
  final ComputeAction _action;

  bool _cleanup = false;
  CleanupAction? _onCleanup;

  /// A [ComputeAction] to wrap.
  Computation(this._action);

  /// A marker if the [Computation] should be freed from memory.
  get cleanup => _cleanup;

  /// Run the [Computation].
  call() {
    Computations.push(this);
    final result = _action();
    Computations.pop();

    if (result is CleanupAction) _onCleanup = result;
  }

  /// Mark the [Computation] for cleanup. Note that the [Computation] will not
  /// be immediately [dispose]d of, instead only eventually cleaned up when the
  /// references to them inside state objects have been dropped.
  void dispose() {
    _cleanup = true;
    _onCleanup!();
  }
}

/// The currently running [Computation].
Computation? get parentComputation => Computations._computations.lastOrNull;
