import "package:rxs/rxs.dart";

void main() {
  final (augend, setAugend) = signal(0);
  final (addend, setAddend) = signal(0);

  effect(() {
    final sum = augend() + addend();

    if (sum % 2 == 0) {
      print("even!");
    } else {
      print("odd.");
    }
  });

  setAugend(1);
  setAddend(1);
}
