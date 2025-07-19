import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteService {
  late Interpreter _interpreter;
  late List<String> _labels;

  Future<void> loadModel() async {
    try {
      // Load the model
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      
      // Load the labels
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n');

    } catch (e) {
      print("Failed to load model: $e");
    }
  }

  Future<Map<String, double>> classifyImage(Uint8List imageBytes) async {
    // Decode the image
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) return {};

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
    
    // Create a container for the output
    var output = List.filled(_labels.length, 0).reshape([1, _labels.length]);

    // Run inference
    _interpreter.run(input, output);
    
    // Process the output
    var outputList = output[0] as List<double>;
    var highestProbability = outputList.reduce((a, b) => a > b ? a : b);
    var highestProbabilityIndex = outputList.indexOf(highestProbability);
    var label = _labels[highestProbabilityIndex];

    return {label: highestProbability};
  }

  void dispose() {
    _interpreter.close();
  }
}
