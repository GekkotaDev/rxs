import "package:test/test.dart";

import "package:rxs/hooks.dart";

enum CountInstruction {
  increment,
  decrement,
  reset,
}

void main() {
  test("uses reducer", () {
    final count = reducer<CountInstruction, int>(
        (action, state) => switch (action) {
              CountInstruction.increment => state + 1,
              CountInstruction.decrement => state - 1,
              CountInstruction.reset => 0,
            },
        0);
    final squared = state.from(() => count() * count());

    expect(squared(), 0);

    count.dispatch(CountInstruction.increment);
    expect(squared(), 1);

    count.dispatch(CountInstruction.increment);
    expect(squared(), 4);

    count.dispatch(CountInstruction.increment);
    expect(squared(), 9);

    count.dispatch(CountInstruction.decrement);
    expect(squared(), 4);

    count.dispatch(CountInstruction.reset);
    expect(squared(), 0);
  });
}
