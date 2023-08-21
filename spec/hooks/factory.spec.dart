import "package:rxs/hooks.dart";
import "package:rxs/types.dart";
import "package:test/test.dart";

void main() {
  group("two different", () {
    test("state scopes", () {
      final context = SubscriptionContext(stack: []);
      final local = StateFactory.from(parentContext: context);

      final count = state.be(1);
      final squared = local.from(() => count() * count());

      expect(squared(), 1);

      count.set(2);
      expect(squared(), 1);
    });

    test("two different chained state scopes", () {
      // Not recommended.
      final context = SubscriptionContext(stack: []);
      final local = StateFactory.from(parentContext: context);

      final count = state.be(2);
      final squared = local.from(() => count() * count());
      final cubed = state.from(() => squared() * count());

      expect(cubed(), 8);

      count.set(3);
      expect(cubed(), 12);
    });
  });
}
