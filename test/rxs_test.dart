import "package:test/test.dart";
import "package:rxs/rxs.dart";

void main() {
  test("updates signal", () {
    final (count, setCount) = signal(0);

    assert(count() == 0);

    setCount(count() + 505);

    assert(count() == 505);
  });

  test("composes signals", () {
    final (countA, setCountA) = signal(0, effectMutation: EffectMutation.error);
    final (countB, setCountB) = signal(0, effectMutation: EffectMutation.error);
    final countC = stream(() => countA() + countB());

    assert(countC.value == 0);

    setCountA(6);
    assert(countC.value == 6);

    setCountB(4);
    assert(countC.value == 10);
  });

  test("updates effects", () {
    final (countA, setCountA) = signal(0, effectMutation: EffectMutation.error);
    final (countB, setCountB) = signal(0, effectMutation: EffectMutation.error);
    final (countC, setCountC) = signal(0);

    effect(() => setCountC(countA() + countB()));

    assert(countC() == 0);

    setCountA(6);
    assert(countC() == 6);

    setCountB(4);
    assert(countC() == 10);
  });

  test("is uneffected", () {
    final (countA, setCountA) = signal(6, effectMutation: EffectMutation.error);
    final (countB, setCountB) = signal(0, effectMutation: EffectMutation.error);
    final (countC, setCountC) = signal(0);

    assert(countC() == 0);

    effect(() {
      final count = untracked(() => countA());
      setCountC(count + countB());
    });

    assert(countC() == 6);

    setCountA(10);
    assert(countC() == 6);

    setCountB(6);
    assert(countC() == 16);
  });
}
