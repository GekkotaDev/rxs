import "package:meta/meta.dart";
import "package:rxdart/rxdart.dart";

import "events.dart";

/// A composition of multiple child states.
typedef Composite<Value> = Value Function();

/// Callback function that returns a [Value].
typedef StateGetter<Value> = Value Function();

/// Callback function that accepts the given [value] and returns a new [Value].
typedef StateUpdater<Value> = Value Function(Value value);

/// Callback function that mutates the given [value].
typedef StateMutator<Value> = void Function(Value value);

/// Default [SubscriptionContext].
final defaultContext = SubscriptionContext(stack: []);

/// Provides [State]s with [SubscriptionContext].
///
/// The [SubscriptionContext] provides a parent [State] with the context that it
/// needs about the child [State]s that want to subscribe to it.
final class SubscriptionContext {
  /// A stack of [SubscriptionContext]s.
  final List<StateReference> stack;

  /// The current child [SubscriptionContext].
  StateReference? get current => stack.lastOrNull;

  /// Push [State] into the subscription [stack].
  void push(StateReference state) => stack.add(state);

  /// Pull [State] from the subscription [stack].
  StateReference? pull() => stack.isNotEmpty ? stack.removeLast() : null;

  /// Provides [State]s with [SubscriptionContext].
  ///
  /// Pass a [List] to the constructor to be used as a stack. This allows the
  /// parent [State]s to know which child [State]s are currently subscribing to
  /// them.
  const SubscriptionContext({
    required this.stack,
  });
}

/// The context for the current status of the [State]ful [Value].
///
/// The [StateContext] encapsulates the properties of the [State] so that it may
/// provide consumers including itself the necessary data to assess its current
/// status and act accordingly.
final class StateContext<Value> {
  /// A handle to the raw underlying stream.
  final BehaviorSubject<Value> $;

  /// A set of subscribers to this state.
  final Set<StateReference<State>> children;

  /// A handle to the [SubscriptionContext].
  SubscriptionContext subscriber = defaultContext;

  /// The context for the current status of the [State]ful [Value].
  ///
  /// Pass the context a [BehaviorSubject] and a [Set] of child states. They may
  /// be completely new objects or extracted from a previous instance of a
  /// [StateContext].
  StateContext({
    required this.$,
    required this.children,
  });

  /// Add the [state] as a child/subscriber of this parent state.
  void addChild(StateReference state) => children.add(state);

  /// [notify] all children of this [StateContext] that the parent [State] has
  /// been updated with a new value.
  void notify(StateNotification notification) {
    for (final child in children) {
      final state = child();

      switch (state) {
        case null:
          child.onDereference!();
          children.remove(child);

        case State():
          state.notify(notification);
      }
    }
  }
}

/// [State] is data that (1) exists throughout the lifetime of the application
/// and (2) is subject to changes over time. Additionally any given state within
/// this library must cause other states using it to react accordingly to any
/// changes to it, and may cascade down a graph or chain of states.
///
/// [State] within this library may expose lifecycle hooks either directly or
/// through higher level abstractions, but no guarantees are made that a state
/// object **will** expose lifecycle hooks.
abstract interface class State<Value> {
  /// A handle to the [StateContext].
  final ctx = StateContext<Value>(
    $: BehaviorSubject(),
    children: {},
  );

  /// Event received from a parent state.
  StateNotification? notification;

  /// The current value of the state.
  @protected
  Value get state;

  /// Retrieve the current value of the state. If called within a derived state
  /// it will add the state as its child.
  Value call();

  /// Notify this [State] that it should be updated and react accordingly to the
  /// [StateNotification] sent to it.
  void notify(StateNotification notification);
}

/// A nullable reference to a [State] object.
///
/// The [StateReference] is implemented to provide implementors of [State] type
/// a mechanism to manage how long their [State] subtype should live. Out of the
/// box this library provides the [StrongStateReference] and the
/// [WeakStateReference]
abstract interface class StateReference<Child extends State> {
  /// A lifecycle hook called when the [State] is dereferenced.
  void Function()? get onDereference;

  /// A handle that may or may not return the [State].
  Child? call();
}

/// A reference to a [State] object.
///
/// [StrongStateReference] are functionally the same as providing a direct
/// reference to the [State] itself.
final class StrongStateReference<T, Child extends State<T>>
    implements StateReference<Child> {
  /// A handle to the [State].
  @protected
  final Child state;

  @protected
  final void Function()? onDereference;

  /// A reference to a [State] object.
  ///
  /// Pass the [state] to the [StrongStateReference].
  const StrongStateReference({
    required this.state,
    this.onDereference,
  });

  call() => state;
}

/// A weak reference to a [State] object.
///
/// [WeakStateReference]s are functionally the same as providing the [State]
/// wrapped in a [WeakReference].
final class WeakStateReference<T, Child extends State<T>>
    implements StateReference<Child> {
  /// A handle to the [State].
  @protected
  late final WeakReference<Child> state;

  @protected
  final void Function()? onDereference;

  /// A weak reference to a [State] object.
  ///
  /// Pass the [state] to the [WeakStateReference].
  WeakStateReference({
    required Child state,
    this.onDereference,
  }) {
    this.state = WeakReference(state);
  }

  call() => state.target;
}
