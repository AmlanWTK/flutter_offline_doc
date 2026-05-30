import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'package:tesseract_ocr/ocr_engine_config.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/ocr_language.dart';

abstract class OcrService {
  Future<String> extractTextFromImage(
    File imageFile, {
    OcrLanguage language = OcrLanguage.english,
  });
  void dispose();
}

class OcrServiceImpl implements OcrService {
  TextRecognizer? _latinRecognizer;

  TextRecognizer get _latin {
    _latinRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _latinRecognizer!;
  }

  @override
  Future<String> extractTextFromImage(
    File imageFile, {
    OcrLanguage language = OcrLanguage.english,
  }) async {
    final tesseractLang = language.tesseractCode;
    if (tesseractLang != null) {
      return _extractWithTesseract(imageFile.path, tesseractLang);
    }

    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _latin.processImage(inputImage);
    return recognizedText.text;
  }

  Future<String> _extractWithTesseract(String path, String language) async {
    try {
      final text = await TesseractOcr.extractText(
        path,
        config: OCRConfig(
          language: language,
          engine: OCREngine.tesseract,
        ),
      );
      return text.trim();
    } catch (e) {
      return 'OCR failed: $e\n\n'
          'Try a full rebuild: flutter clean && flutter pub get && flutter run';
    }
  }

  @override
  void dispose() {
    _latinRecognizer?.close();
    _latinRecognizer = null;
  }
}
