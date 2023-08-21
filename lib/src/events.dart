/// A type that notifies consumers with additional data from its parent.
class StateNotification {}

/// Notify the child state to update its value.
final class StateUpdate implements StateNotification {}
