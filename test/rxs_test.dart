import "package:test/test.dart";

import "package:rxs/core.dart";

void main() {
  test("sets state", () {
    final count = state(0);
    expect(count(), 0);

    count.set(42);
    expect(count(), 42);
  });

  test("updates state", () {
    final array = state(["apple"]);
    expect(array(), ["apple"]);

    array.update((array) => array + ["banana"]);
    expect(array(), ["apple", "banana"]);
  });

  test("mutates state", () {
    final array = state([]);
    expect(array(), []);

    array.mutate((array) => array.add("dart"));
    expect(array(), ["dart"]);
  });

  group("computes ", () {
    test("once", () {
      final addend = state(0);
      final augend = state(0);
      final sum = state<int>();

      compute(() => sum.set(addend() + augend()));

      expect(sum(), 0);
      addend.set(6);
      expect(sum(), 6);
      augend.set(4);
      expect(sum(), 10);
    });

    test("with a reference", () {
      final addend = state(0);
      final augend = state(0);
      final sum = state<int>();

      compute(() => sum.set(addend() + ref(augend)));

      expect(sum(), 0);
      augend.set(4);
      expect(sum(), 0);
      addend.set(6);
      expect(sum(), 10);
    });

    test("with explicit dependencies", () {
      final addend = state(0);
      final augend = state(0);
      final sum = state<int>();

      compute(() => sum.set(on(
            (addend: addend(), augend: augend()),
            (dependencies) => dependencies.addend + dependencies.augend,
          )));

      expect(sum(), 0);
      addend.set(6);
      expect(sum(), 6);
      augend.set(4);
      expect(sum(), 10);
    });

    test("and cleans up", () {
      final clean = state(false);
      final count = state(0);

      final counter = compute(() {
        while (count() < 10) {
          count.update((count) => count + 1);
        }

        return () => clean.set(true);
      });

      expect(count(), 10);
      expect(clean(), false);

      count.set(5);
      expect(count(), 10);

      counter.dispose();

      count.set(5);
      expect(count(), 5);
      expect(clean(), true);
    });
  });
}
