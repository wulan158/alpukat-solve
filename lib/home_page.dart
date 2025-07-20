import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/tflite_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final TfliteService _tfliteService = TfliteService();

  String _classificationResult = '';
  double _probability = 0.0;
  bool _isClassifying = false;
  String? _imageUrl; // To store the uploaded image URL

  @override
  void initState() {
    super.initState();
    try {
      _tfliteService.loadModel();
    } catch (e) {
      print("Error loading model: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat model: $e')),
      );
    }
  }

  @override
  void dispose() {
    _tfliteService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isClassifying = true;
        _classificationResult = '';
        _probability = 0.0;
        _imageUrl = null; // Reset image URL
      });
      await _classifyImage(_image!.readAsBytesSync());
    }
  }

  Future<void> _classifyImage(Uint8List imageBytes) async {
    try {
      final result = await _tfliteService.classifyImage(imageBytes);
      setState(() {
        _classificationResult = result.keys.first.trim(); // 🔧 TRIM result!
        _probability = result.values.first;
        _isClassifying = false;
      });

      // DEBUG: Print classification result
      print("🎯 _classificationResult: '$_classificationResult'");
      print("📊 _probability: $_probability");
      print("🔍 Description: '${_getDescription(_classificationResult)}'");
    } catch (e) {
      print("Error classifying image: $e");
      setState(() {
        _classificationResult = 'Error Klasifikasi';
        _probability = 0.0;
        _isClassifying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengklasifikasi gambar: $e')),
      );
    }
  }

  Future<void> _saveClassification() async {
    if (_image == null || _classificationResult.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Tidak ada gambar atau hasil klasifikasi untuk disimpan.')),
      );
      return;
    }

    setState(() {
      _isClassifying = true; // Indicate saving process
    });

    try {
      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('leaf_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(_image!);
      _imageUrl = await storageRef.getDownloadURL();

      // Save classification data to Firestore
      await FirebaseFirestore.instance.collection('history').add({
        'image_url': _imageUrl,
        'name': _classificationResult,
        'description': _getDescription(_classificationResult),
        'probability': _probability,
        'timestamp': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasil klasifikasi berhasil disimpan!')),
      );
      _resetState();
    } catch (e) {
      print("Error saving classification: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan hasil: $e')),
      );
    } finally {
      setState(() {
        _isClassifying = false;
      });
    }
  }

  String _getDescription(String result) {
    // 🔧 TRIM input untuk konsistensi
    final cleanResult = result.trim();
    print("🔎 Getting description for: '$cleanResult'");
    print("🔎 String length: ${cleanResult.length}");
    print("🔎 String bytes: ${cleanResult.codeUnits}");

    switch (cleanResult) {
      case 'Alpukat_Aligator':
        print("✅ Matched: Alpukat_Aligator");
        return 'Alpukat Aligator memiliki kulit bergelombang seperti kulit buaya, dengan daging buah yang creamy dan rasa yang khas.';
      case 'Alpukat_Kendil':
        print("✅ Matched: Alpukat_Kendil");
        return 'Alpukat Kendil berbentuk lonjong seperti kendil, ukuran besar dengan daging tebal dan tekstur lembut.';
      case 'Alpukat_Madu':
        print("✅ Matched: Alpukat_Madu");
        return 'Alpukat Madu memiliki rasa manis seperti madu dengan tekstur lembut dan creamy, cocok untuk jus.';
      case 'Alpukat_SW01':
        print("✅ Matched: Alpukat_SW01");
        return 'Alpukat SW01 adalah varietas unggul dengan produktivitas tinggi, daging tebal, dan rasa yang gurih.';
      case 'Alpukat_Super':
        print("✅ Matched: Alpukat_Super");
        return 'Alpukat Super memiliki ukuran yang besar dengan kualitas daging buah yang sangat baik dan rasa yang lezat.';
      default:
        print("❌ No match found for: '$cleanResult'");
        return 'Deskripsi belum tersedia untuk jenis alpukat ini.';
    }
  }

  void _resetState() {
    setState(() {
      _image = null;
      _classificationResult = '';
      _probability = 0.0;
      _isClassifying = false;
      _imageUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Klasifikasi Daun Alpukat'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_image == null) ...[
                Text(
                  'Klasifikasi Daun Alpukat',
                  style: textTheme.displayLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: 32,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ambil atau unggah gambar daun alpukat untuk mengetahui jenisnya secara instan.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 24), // Ikon standar
                  label: const Text('Ambil dari Kamera'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon:
                      const Icon(Icons.photo_library, size: 24), // Ikon standar
                  label: const Text('Pilih dari Galeri'),
                ),
              ] else if (_isClassifying) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 20),
                Text(
                  'Sedang Memproses...',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium,
                ),
              ] else ...[
                // Result State
                Text(
                  'Hasil Klasifikasi',
                  style: textTheme.titleLarge
                      ?.copyWith(color: theme.colorScheme.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _image != null
                              ? Image.file(
                                  _image!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/icon/app_icon.png', // Fallback placeholder
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _classificationResult,
                          style: textTheme.displayLarge?.copyWith(fontSize: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getDescription(_classificationResult),
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildProbabilityIndicator(theme, textTheme),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _saveClassification,
                  icon: const Icon(Icons.save_alt), // Ikon standar
                  label: const Text('Simpan ke Riwayat'),
                  style: theme.elevatedButtonTheme.style?.copyWith(
                    backgroundColor:
                        MaterialStateProperty.all(theme.colorScheme.secondary),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _resetState,
                  icon: const Icon(Icons.refresh), // Ikon standar
                  label: const Text('Klasifikasi Ulang'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProbabilityIndicator(ThemeData theme, TextTheme textTheme) {
    return Column(
      children: [
        Text(
          'Tingkat Keyakinan',
          style: textTheme.titleLarge?.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: _probability,
          minHeight: 12,
          backgroundColor: theme.colorScheme.surface,
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        const SizedBox(height: 8),
        Text(
          '${(_probability * 100).toStringAsFixed(0)}%',
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
