import "package:test/test.dart";

import "package:rxs/hooks.dart";

void main() {
  group("single state", () {
    test("is set", () {
      final count = state.be(0);
      expect(count(), 0);

      count.set(42);
      expect(count(), 42);
    });

    test("is updated", () {
      final count = state.be(3);
      expect(count(), 3);

      count.update((count) => count * count);
      expect(count(), 9);
    });

    test("is mutated", () {
      final languages = state.be(["rust"]);
      expect(languages(), ["rust"]);

      languages.mutate((languages) => languages.add("dart"));
      expect(languages(), ["rust", "dart"]);
    });
  });

  group("multiple states", () {
    test("are set", () {
      final count = state.be(2);
      final squared = state.from(() => count() * count());
      expect(squared(), 4);

      count.set(3);
      expect(squared(), 9);
    });

    test("are updated", () {
      final count = state.be(2);
      final squared = state.from(() => count() * count());
      expect(squared(), 4);

      count.update((count) => count + 1);
      expect(squared(), 9);
    });

    test("are mutated", () {
      final languages = state.be(["rust"]);
      final webLanguages = state.from(() => [...languages(), "javascript"]);
      expect(webLanguages(), ["rust", "javascript"]);

      languages.mutate((languages) => languages.add("dart"));
      expect(webLanguages(), ["rust", "dart", "javascript"]);
    });

    test("have nested state", () {
      final count = state.be(2);
      final cubed = state.from(() {
        final squared = count() * count();
        final cubed = state.from(() => squared * count());
        return cubed();
      });

      expect(cubed(), 8);

      count.set(3);
      expect(cubed(), 27);

      count.set(4);
      expect(cubed(), 64);
    });

    test("have chained state", () {
      final count = state.be(2);
      final squared = state.from(() => count() * count());
      final cubed = state.from(() => squared() * count());

      expect(cubed(), 8);

      count.set(3);
      expect(cubed(), 27);

      count.set(4);
      expect(cubed(), 64);
    });

    test("run only on new data", () {
      final count = state.be(0);
      final boolean = state.be(false);
      state.from(() {
        boolean();
        state.ref(() => count.update((n) => n + 1));
      }, lazy: false, local: false);
      expect(count(), 1);

      boolean.set(false);
      expect(count(), 1);

      boolean.set(true);
      expect(count(), 2);
    });
  });
}
