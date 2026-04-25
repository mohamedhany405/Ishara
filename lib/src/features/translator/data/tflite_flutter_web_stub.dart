// Web-safe fallback for tflite_flutter imports.
//
// On web, dart:ffi is unavailable, so we provide minimal API-compatible
// stubs used by sign_language_service.dart.

class InterpreterOptions {
  int? threads;
}

class Tensor {
  const Tensor({this.shape = const <int>[]});

  final List<int> shape;
}

class Interpreter {
  Interpreter._();

  static Future<Interpreter> fromAsset(
    String assetName, {
    InterpreterOptions? options,
  }) async {
    return Interpreter._();
  }

  Tensor getOutputTensor(int index) {
    return const Tensor();
  }

  Tensor getInputTensor(int index) {
    return const Tensor();
  }

  List<Tensor> getInputTensors() => const <Tensor>[];

  void run(Object input, Object output) {}

  void close() {}
}
