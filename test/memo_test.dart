import "package:test/test.dart";
import "package:rxs/rxs.dart";

void main() {
  group("derived state ", () {
    final (countA, _) = signal(2);
    final (countB, setCountB) = signal(2);
    final (countC, setCountC) = signal(0);

    result() {
      setCountC(countC() + 1);
      return countA() + countB();
    }

    test("called once", () {
      assert(result() == 4);
    });

    test("increments countC once", () {
      assert(countC() == 1);
    });

    test("called twice", () {
      assert(result() == 4);
    });

    test("increments countC twice", () {
      assert(countC() == 2);
      setCountB(countB() + 1);
    });

    test("called thrice (with countB updated prior)", () {
      assert(result() == 5);
    });

    test("increments countC thrice", () {
      assert(countC() == 3);
    });
  });

  group("computed derived state ", () {
    final (countA, _) = signal(2);
    final (countB, setCountB) = signal(2);
    final (countC, setCountC) = signal(0);

    final result = computed(() {
      setCountC(untracked(() => countC() + 1));
      return countA() + countB();
    });

    test("called once", () {
      assert(result() == 4);
    });

    test("increments countC once", () {
      assert(countC() == 1);
    });

    test("called twice", () {
      assert(result() == 4);
    });

    test("does not increment countC twice", () {
      assert(countC() == 1);
      setCountB(countB() + 1);
    });

    test("called thrice (with countB updated prior)", () {
      assert(result() == 5);
    });

    test("does increment countC twice", () {
      assert(countC() == 2);
    });
  });
}
