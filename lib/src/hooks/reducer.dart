import "factory.dart";

/// Reduces the current state + event down to the next state.
typedef ReducerFunction<Actions, Value> = Value Function(
    Actions action, Value state);

/// Implements a reducer for state management.
class Reducer<Actions, Value> {
  late final _state = state.typeOf<Value>();

  /// The reducer function.
  final ReducerFunction<Actions, Value> reducer;

  /// Pass a reducer function and the initial state.
  Reducer(this.reducer, Value state) {
    _state.set(state);
  }

  /// Retrieves the state.
  Value call() => _state();

  /// Dispatches an [action] to compute the next state.
  void dispatch(Actions action) => _state.set(reducer(action, _state()));
}

/// Implements a reducer function to manage the state.
Reducer<Actions, Value> reducer<Actions, Value>(
        ReducerFunction<Actions, Value> reducer, Value initialState) =>
    Reducer(reducer, initialState);
