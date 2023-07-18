import "package:rxs/hooks.dart";
import "package:rxs/core.dart";

void main() {
  final hours = state(00);
  final minutes = state(00);
  final seconds = state(00);

  final time = compose(() => "[${hours()}:${minutes()}:${seconds()}]");

  final message = state("Application booted.");

  final logger = compute(() {
    print("${time()} ${message()}");

    return () => print("Console logger disabled.");
  });

  logger;
}
