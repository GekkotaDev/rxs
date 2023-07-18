import "package:rxs/src/state.dart";

/// A function that takes in an event (in the form of an [Enum]) on how the
/// [State] should be updated.
typedef Dispatcher<E extends Enum> = void Function(E event);

/// The user defined function that manages the [State] it is paired with. The
/// [Manager] constraints how [State] should be updated, protecting it from
/// arbitrary updates that are not desirable to have.
typedef Manager<T, E extends Enum> = void Function(WritableState<T> state,
    {required E event});

/// A tuple that contains the [State] itself and a [Dispatcher] function.
typedef ManagedState<T, E extends Enum> = (ReadOnlyState<T>, Dispatcher<E>);

/// A hook that allows any given [State] to be programmatically [managed] such
/// that it does not get arbitrarily updated with values that do not follow a
/// given contract as specified by a [Manager] function. This may be used to aid
/// in maing sure the [State] of the [value] falls within a finite number of
/// [State]s.
///
/// The [managed] hook returns a [ManagedState] tuple. The [State] may not be
/// directly updated and instead must be updated through the given [Dispatcher]
/// method from the tuple.
ManagedState<T, E> managed<T, E extends Enum>(
  T value, {
  required Manager<T, E> manager,
}) {
  final writableState = state(value);
  final readOnlyState = ReadOnlyState(writableState);

  void dispatcher(E event) => manager(writableState, event: event);

  return (readOnlyState, dispatcher);
}
