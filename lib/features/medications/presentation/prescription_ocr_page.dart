import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart';
import '../data/prescription_service.dart';

class PrescriptionOCRPage extends StatefulWidget {
  const PrescriptionOCRPage({super.key});

  @override
  State<PrescriptionOCRPage> createState() => _PrescriptionOCRPageState();
}

class _PrescriptionOCRPageState extends State<PrescriptionOCRPage> {
  final _prescriptionService = PrescriptionService();
  String _extractedText = '';
  File? _imageFile;
  Uint8List? _imageBytes; // For web platform
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _pickImage() async {
    if (kIsWeb) {
      setState(() {
        _errorMessage = 'Text recognition is not supported on web. Please use a mobile or desktop app.';
      });
      return;
    }

    try {
      setState(() => _errorMessage = null);
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        // Always use bytes for web, file for mobile
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          if (kIsWeb) {
            _imageBytes = bytes;
            _imageFile = null;
          } else {
            _imageFile = File(pickedFile.path);
            _imageBytes = null;
          }
          _extractedText = '';
          _isLoading = true;
        });
        
        if (kIsWeb) {
          await _scanTextWeb(bytes);
        } else {
          await _scanText(_imageFile!);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _scanText(File imageFile) async {
    if (kIsWeb) {
      setState(() {
        _errorMessage = 'Text recognition is not supported on web';
        _isLoading = false;
      });
      return;
    }

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      setState(() {
        _extractedText = recognizedText.text;
        _isLoading = false;
      });
      textRecognizer.close();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to scan prescription: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _scanTextWeb(Uint8List imageBytes) async {
    setState(() {
      _errorMessage = 'Text recognition is not supported on web. Please use a mobile or desktop app.';
      _isLoading = false;
    });
  }

  Future<void> _savePrescription() async {
    if (_extractedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No text extracted. Please scan a prescription first.'),
        ),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);

      // Save to Firestore via PrescriptionService
      await _prescriptionService.addPrescription(
        extractedText: _extractedText,
        scannedAt: DateTime.now(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription saved successfully!')),
        );
        // Clear form after successful save
        setState(() {
          _imageFile = null;
          _extractedText = '';
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to save prescription: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Prescription')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              const SizedBox(height: 16),

              // Scan button
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scan Prescription'),
                onPressed: (kIsWeb || _isLoading) ? null : _pickImage,
              ),
              const SizedBox(height: 20),

              // Loading indicator
              if (_isLoading) const Center(child: CircularProgressIndicator()),

              // Image preview
              if ((_imageFile != null || _imageBytes != null) && !_isLoading)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scanned Image:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_imageBytes != null)
                      Image.memory(_imageBytes!, height: 250, fit: BoxFit.cover)
                    else if (!kIsWeb && _imageFile != null)
                      Image.file(_imageFile!, height: 250, fit: BoxFit.cover),
                    const SizedBox(height: 20),
                  ],
                ),

              // Extracted text
              if (_extractedText.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Extracted Text:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_extractedText),
                    ),
                    const SizedBox(height: 20),

                    // Save button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _savePrescription,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Prescription'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
