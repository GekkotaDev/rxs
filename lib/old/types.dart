/// A [Model] is a unit of data, ranging from basic primitives such as [bool]ean
/// values, to complex classes composed of other [Model]s.
///
/// Normally a (wrapper) class does not need to implement the [Model] type unless
/// a union of State objects and any other type are necessary for a function's
/// parameters list.
abstract interface class Model {}

/// A function that may optionally return a value. Core primitive of
/// computations.
typedef Action<T> = T Function();

/// Mark that the state used should not update a computation.
typedef Untracked<T> = Action<T>;

/// The action to perform when a computation is freed.
typedef CleanupAction = Action<void>;

/// An action that re-runs when state inside of it updates. A [ComputeAction] is
/// guaranteed to run at least once during the lifetime of the [ComputeAction].
///
/// They may also optionally provide a [CleanupAction] that gets called when the
/// [ComputeAction] is freed and should no longer run in response to state
/// changes.
typedef ComputeAction<T> = Action<T>;
