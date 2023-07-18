import "package:test/test.dart";

import "package:rxs/core.dart";
import "package:rxs/hooks.dart";

enum Phone {
  lumia,
  galaxy,
  xperia,
  ;
}

void main() {
  test("manages state", () {
    final (phone, changePhone) = managed(
      "HTC Desire X",
      manager: (phone, {Phone event = Phone.lumia}) {
        switch (event) {
          case Phone.lumia:
            phone.set("Nokia Lumia");
          case Phone.galaxy:
            phone.set("Samsung Galaxy");
          case Phone.xperia:
            phone.set("Sony Xperia");
        }
      },
    );

    expect(phone(), "HTC Desire X");
    changePhone(Phone.xperia);
    expect(phone(), "Sony Xperia");
    changePhone(Phone.lumia);
    expect(phone(), "Nokia Lumia");
    changePhone(Phone.galaxy);
    expect(phone(), "Samsung Galaxy");
  });

  test("composes state", () {
    final brand = state("Lenovo");
    final model = state("S90");
    final phone = compose(() => "${brand()} ${model()}");

    expect(phone(), "Lenovo S90");
    brand.set("Nokia");
    model.set("E63");
    expect(phone(), "Nokia E63");
  });
}
