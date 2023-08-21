import "package:rxs/hooks.dart";

void main() {
  final hours = state.be(00);
  final minutes = state.be(00);
  final seconds = state.be(00);

  final time = state.from(() => "[${hours()}:${minutes()}:${seconds()}]");

  final message = state.be("Application booted.");

  final logger = state.from(
    () => print("${time()} ${message()}"),
    onDereference: () => print("Console logger disabled"),
  );

  logger;
}
