import "package:rxdart/rxdart.dart";
import "package:rxs/types.dart";

/// A factory for [State] objects.
class StateFactory {
  /// The default [SubscriptionContext].
  late final SubscriptionContext parentContext;

  /// Constructs a [StateFactory] with the default [SubscriptionContext].
  StateFactory() {
    parentContext = defaultContext;
  }

  /// Constructs a [StateFactory] with the provided [SubscriptionContext].
  StateFactory.from({required this.parentContext});

  /// Creates reactive state.
  WritableState<Value> be<Value>(Value value) {
    final state = WritableState(value);
    state.ctx.subscriber = parentContext;
    return state;
  }

  /// Create reactive state derived from parent states. The user may declare
  /// lifecycle hooks and set options.
  ///
  /// - If [lazy], the [composite] will not compute the next state only until
  /// the state object has been read. Otherwise it will be eagerly computed as
  /// soon as it receives a notification.
  ///
  /// - If [local], the state may be dereferenced as soon as it goes out of
  /// scope, otherwise it will stay alive for as long as its parent states are
  /// alive. Note that the [WeakReference] based implementation means that this
  /// option should not be seen as reliable.
  ///
  /// - The [onAccess] lifecycle hook will run whenever the state has been read
  /// regardless if it has been updated or not. It may be made aware if the
  /// state has received a notification.
  ///
  /// - The [onCreate] lifecycle hook will run on the creation of the state but
  /// before it has been initialized. If computationally expensive code is ran
  /// in the [composite] this hook runs before its initial run.
  ///
  /// - The [onDereference] lifecycle hook will run when the state has been
  /// dereferenced. Note that there are no guarantees that the state will be
  /// reliably dereferenced.
  ///
  /// - The [onInit] lifecycle hook will run after the creation **and**
  /// initialization of the state. This hook runs after the initial run of the
  /// [composite].
  ///
  /// - The [onNotify] lifecycle hook will run after the state receives a
  /// notification. This hook may be made aware of the current state.
  ReadOnlyState<Value> from<Value>(
    Composite<Value> composite, {
    bool lazy = true,
    bool local = true,
    OnAccess onAccess,
    void Function()? onCreate,
    void Function()? onDereference,
    void Function()? onInit,
    OnNotify onNotify,
  }) {
    final context = StateContext<Value>(
      $: BehaviorSubject(),
      children: {},
    );
    context.subscriber = parentContext;

    final state = ReadOnlyState(
      context,
      composite,
      lazy: lazy,
      local: local,
      onAccess: onAccess,
      onCreate: onCreate,
      onDestroy: onDereference,
      onInit: onInit,
      onNotify: onNotify,
    );
    return state;
  }

  /// Create an empty state whose state only narrows down to the given generic.
  WritableState<Value> typeOf<Value>() {
    final state = WritableState<Value>();
    state.ctx.subscriber = parentContext;
    return state;
  }

  /// Wraps the [getter] within a non-tracking/non-reactive scope.
  Value ref<Value>(StateGetter<Value> getter) {
    final context = StateContext<Value>(
      $: BehaviorSubject(),
      children: {},
    );
    context.subscriber = parentContext;

    parentContext
        .push(WeakStateReference(state: ReadOnlyState(context, () => null)));
    final value = getter();
    parentContext.pull();
    return value;
  }
}

/// The default [StateFactory]
final state = StateFactory();
