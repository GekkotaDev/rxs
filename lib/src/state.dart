import "package:meta/meta.dart";
import "package:rxdart/rxdart.dart";

import "events.dart";
import "context.dart";

/// Lifecycle hook when state is read.
typedef OnAccess = void Function(StateNotification? notification)?;

/// Lifecycle hook when state is notified.
typedef OnNotify<Value> = void Function(
    StateNotification notification, Value state,
    {required bool lazy})?;

/// [State] with read *and* write access.
class WritableState<Value> implements State<Value> {
  /// A handle to the [StateContext].
  final StateContext<Value> ctx = StateContext(
    $: BehaviorSubject(),
    children: {},
  );

  /// Event received from a parent state.
  @protected
  var notification = null;

  /// [State] with read *and* write access.
  ///
  /// Optionally pass the initial [value] of the state.
  WritableState([Value? value]) {
    if (value is Value) ctx.$.add(value);
  }

  @protected
  get state {
    final currentSubscriber = ctx.subscriber.current;
    if (currentSubscriber != null) ctx.addChild(currentSubscriber);

    return ctx.$.value;
  }

  /// The value of the state.
  @protected
  set state(Value value) {
    if (value == ctx.$.valueOrNull) return;

    ctx.$.add(value);
    ctx.notify(StateUpdate());
  }

  call() => state;

  @protected
  void notify(StateNotification notification) {}

  /// Directly set the new [value]. Must be of the same type
  void set(Value value) => state = value;

  /// Update the state based on the current state. A [setter] must be provided.
  void update(StateUpdater<Value> setter) => state = setter(state);

  /// Mutate the state in place. A [mutator] must be provided.
  void mutate(StateMutator<Value> mutator) {
    mutator(state);
    ctx.notify(StateUpdate());
  }
}

/// [State] with read only access.
class ReadOnlyState<Value> implements State<Value> {
  /// A handle to the [StateContext].
  final StateContext<Value> ctx;

  /// A composite of multiple composed states.
  @protected
  late final Composite<Value> composite;

  /// Flag to indicate if state should be updated lazily.
  @protected
  final bool lazy;

  /// Flag to determine to lifespan of this [ReadOnlyState].
  ///
  /// If it's local then the state will only last as long as the scope it was
  /// defined in, otherwise it will last for as long as its parent states are
  /// alive.
  @protected
  final bool local;

  /// Event received from a parent state.
  StateNotification? notification;

  /// Callback function when state is accessed.
  final OnAccess onAccess;

  /// Callback function when state is notified.
  final OnNotify onNotify;

  /// [State] with read only access.
  ///
  /// Pass the [composite].
  ReadOnlyState(
    this.ctx,
    this.composite, {
    this.lazy = true,
    this.local = true,
    this.onAccess,
    this.onNotify,
    void Function()? onInit,
    void Function()? onCreate,
    void Function()? onDestroy,
  }) {
    if (onCreate != null) onCreate();

    final StateReference self = switch (local) {
      true => WeakStateReference(
          state: this,
          onDereference: onDestroy,
        ),
      false => StrongStateReference(
          state: this,
          onDereference: onDestroy,
        ),
    };

    ctx.subscriber.push(self);
    ctx.$.add(composite());
    ctx.subscriber.pull();

    if (onInit != null) onInit();
  }

  @protected
  get state {
    final onAccess = this.onAccess;

    if (onAccess != null) onAccess(notification);

    final currentSubscriber = ctx.subscriber.current;
    if (currentSubscriber != null) ctx.addChild(currentSubscriber);

    switch (notification) {
      case StateUpdate():
        ctx.$.add(composite());
        notification = null;
      case null:
      case _:
        null;
    }

    return ctx.$.value;
  }

  call() => state;

  notify(StateNotification notification) {
    final onNotify = this.onNotify;

    if (lazy) {
      this.notification = notification;
      if (onNotify != null) onNotify(notification, ctx.$.value, lazy: true);
      return;
    }

    ctx.$.add(composite());
    this.notification = null;
    if (onNotify != null) onNotify(notification, ctx.$.value, lazy: false);
  }
}
