import 'dart:typed_data';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteService {
  late Interpreter _interpreter;
  late List<String> _labels;

  Future<void> loadModel() async {
    try {
      // Create interpreter options
      final options = InterpreterOptions();

      // Only try GPU delegate on real devices, not emulators
      if (!kIsWeb && Platform.isAndroid && !_isEmulator()) {
        try {
          final gpuDelegate = GpuDelegate();
          options.addDelegate(gpuDelegate);
          print("GPU delegate added successfully");
        } catch (e) {
          print("GPU delegate not available, using CPU: $e");
        }
      } else {
        print("Using CPU delegate (emulator or web detected)");
      }

      // Load the model with options
      _interpreter = await Interpreter.fromAsset('assets/model_comp.tflite',
          options: options);

      // Load the labels
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData
          .split('\n')
          .where((label) => label.trim().isNotEmpty)
          .map((label) => label.trim()) // 🔧 TRIM setiap label!
          .toList();

      print("Model loaded successfully with ${_labels.length} labels");
      print("🏷️ Clean labels: $_labels"); // Debug clean labels
    } catch (e) {
      print("Failed to load model: $e");
      rethrow;
    }
  }

  bool _isEmulator() {
    // Simple check for emulator
    return Platform.isAndroid &&
        (Platform.environment['ANDROID_EMULATOR'] == '1' ||
            Platform.environment['EMULATOR'] == '1');
  }

  Future<Map<String, double>> classifyImage(Uint8List imageBytes) async {
    try {
      // Decode the image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize the image to the model's input size (e.g., 224x224)
      img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

      // Convert the image to a byte buffer
      var buffer = Float32List(1 * 224 * 224 * 3);
      var pixelIndex = 0;
      for (var i = 0; i < 224; i++) {
        for (var j = 0; j < 224; j++) {
          var pixel = resizedImage.getPixel(j, i);
          buffer[pixelIndex++] = (pixel.r - 127.5) / 127.5;
          buffer[pixelIndex++] = (pixel.g - 127.5) / 127.5;
          buffer[pixelIndex++] = (pixel.b - 127.5) / 127.5;
        }
      }

      // Reshape the input to the correct format [1, 224, 224, 3]
      var input = buffer.reshape([1, 224, 224, 3]);

      // DEBUG: Check actual model output shape
      var outputShape = _interpreter.getOutputTensor(0).shape;
      print("🔍 Model output shape: $outputShape");
      print("📋 Labels count: ${_labels.length}");
      print("📝 Labels: $_labels");

      // Create output based on actual model output shape (not labels length!)
      var actualOutputSize = outputShape.reduce((a, b) => a * b);
      var output = List.filled(actualOutputSize, 0.0).reshape(outputShape);

      // Run inference
      _interpreter.run(input, output);

      // DEBUG: Print raw output
      var outputList = output[0] as List<double>;
      print("🎯 Raw model output: $outputList");
      print("📊 Output length: ${outputList.length}");

      // Apply softmax for better probability distribution
      var expValues = outputList.map((x) => exp(x)).toList();
      var sumExp = expValues.fold(0.0, (a, b) => a + b);
      var probabilities = expValues.map((x) => x / sumExp).toList();

      print("📈 Probabilities after softmax: $probabilities");

      // Find highest probability
      var highestProbability =
          probabilities.fold(probabilities[0], (a, b) => a > b ? a : b);
      var highestProbabilityIndex = probabilities.indexOf(highestProbability);

      print(
          "🏆 Highest index: $highestProbabilityIndex, probability: $highestProbability");

      // Map to available labels (handle size mismatch)
      if (highestProbabilityIndex < _labels.length) {
        var label = _labels[highestProbabilityIndex].trim(); // 🔧 TRIM label!
        print(
            "✅ Final prediction: '$label' with confidence: ${(highestProbability * 100).toStringAsFixed(2)}%");
        return {label: highestProbability};
      } else {
        print(
            "⚠️ Model output size (${outputList.length}) > Labels size (${_labels.length})");
        // Use modulo to map to available labels
        var mappedIndex = highestProbabilityIndex % _labels.length;
        var label = _labels[mappedIndex].trim(); // 🔧 TRIM label!
        print("🔄 Mapped to index $mappedIndex: '$label'");
        return {label: highestProbability};
      }
    } catch (e) {
      print("❌ Error in classifyImage: $e");
      return {'Error': 0.0};
    }
  }

  void dispose() {
    _interpreter.close();
  }
}
