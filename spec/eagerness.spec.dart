import "package:test/test.dart";

import "package:rxs/hooks.dart";

void main() {
  test("lazy states", () {
    final squared = state.be(0);
    final count = state.be(2);

    final _ = state.from(() {
      final result = count() * count();
      state.ref(() => squared.set(result));
    }, lazy: true, local: false);
    expect(squared(), 4);

    count.set(3);
    expect(squared(), 4);

    count.set(4);
    _();
    expect(squared(), 16);
  });

  test("eager states", () {
    final squared = state.be(0);
    final count = state.be(2);

    state.from(() {
      final result = count() * count();
      state.ref(() => squared.set(result));
    }, lazy: false, local: false);
    expect(squared(), 4);

    count.set(3);
    expect(squared(), 9);

    count.set(4);
    expect(squared(), 16);
  });
}
