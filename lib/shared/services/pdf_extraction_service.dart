import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/ocr_language.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/ocr_service.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/pdf_text_utils.dart';

typedef PdfExtractionProgress = void Function(int currentPage, int totalPages);

abstract class PdfExtractionService {
  Future<String> extractTextFromPdf(
    File pdfFile, {
    OcrLanguage language = OcrLanguage.englishAndBangla,
    PdfExtractionProgress? onProgress,
  });
}

class PdfExtractionServiceImpl implements PdfExtractionService {
  final OcrService _ocrService;

  PdfExtractionServiceImpl(this._ocrService);

  /// ~150 DPI — good balance for Bangla/English OCR on mobile.
  static const double _renderDpiScale = 200 / 72;

  @override
  Future<String> extractTextFromPdf(
    File pdfFile, {
    OcrLanguage language = OcrLanguage.englishAndBangla,
    PdfExtractionProgress? onProgress,
  }) async {
    PdfDocument? document;

    try {
      document = await PdfDocument.openFile(pdfFile.path);

      if (document.isEncrypted) {
        return 'This PDF is password-protected. Remove the password and try again.';
      }

      final pages = document.pages;
      if (pages.isEmpty) {
        return 'No pages found in this PDF.';
      }

      final buffer = StringBuffer();
      var pagesWithText = 0;

      for (var i = 0; i < pages.length; i++) {
        onProgress?.call(i + 1, pages.length);

        final page = pages[i];
        await page.waitForLoaded();

        var pageText = await _extractEmbeddedPageText(page);

        if (!isSubstantialEmbeddedText(pageText)) {
          pageText = await _ocrRenderedPage(page, i + 1, language);
        }

        pageText = pageText.trim();
        if (pageText.isEmpty) continue;

        pagesWithText++;
        if (pages.length > 1) {
          buffer.writeln('--- Page ${i + 1} ---');
        }
        buffer.writeln(pageText);
        buffer.writeln();
      }

      if (pagesWithText == 0) {
        return 'No readable text was found in this PDF. '
            'Try a clearer scan or a different OCR language.';
      }

      return buffer.toString().trim();
    } catch (e) {
      return 'PDF extraction failed: $e';
    } finally {
      await document?.dispose();
    }
  }

  Future<String> _extractEmbeddedPageText(PdfPage page) async {
    try {
      final raw = await page.loadText();
      return raw?.fullText ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<String> _ocrRenderedPage(
    PdfPage page,
    int pageNumber,
    OcrLanguage language,
  ) async {
    PdfImage? pageImage;
    File? tempFile;

    try {
      final renderWidth = (page.width * _renderDpiScale).round();
      final renderHeight = (page.height * _renderDpiScale).round();

      pageImage = await page.render(
        width: renderWidth,
        height: renderHeight,
        backgroundColor: 0xFFFFFFFF,
      );

      if (pageImage == null) return '';

      final pngBytes = img.encodePng(pageImage.createImageNF());
      final tempDir = await getTemporaryDirectory();
      tempFile = File('${tempDir.path}/pdf_page_$pageNumber.png');
      await tempFile.writeAsBytes(pngBytes);

      return await _ocrService.extractTextFromImage(
        tempFile,
        language: language,
      );
    } finally {
      pageImage?.dispose();
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }
}
