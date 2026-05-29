enum OcrLanguage {
  english,
  bangla,
  englishAndBangla,
}

extension OcrLanguageExtension on OcrLanguage {
  String get label {
    switch (this) {
      case OcrLanguage.english:
        return 'English';
      case OcrLanguage.bangla:
        return 'Bangla';
      case OcrLanguage.englishAndBangla:
        return 'English + Bangla';
    }
  }

  String get subtitle {
    switch (this) {
      case OcrLanguage.english:
        return 'ML Kit — fast Latin script OCR';
      case OcrLanguage.bangla:
        return 'Tesseract — Bengali script (বাংলা)';
      case OcrLanguage.englishAndBangla:
        return 'Tesseract — mixed English & Bangla (best for PDFs too)';
    }
  }

  /// Tesseract language code; null means use ML Kit instead.
  String? get tesseractCode {
    switch (this) {
      case OcrLanguage.english:
        return null;
      case OcrLanguage.bangla:
        return 'ben';
      case OcrLanguage.englishAndBangla:
        return 'ben+eng';
    }
  }
}
