import 'package:get_it/get_it.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/document_capture_service.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/ocr_service.dart';
import 'package:flutter_offline_ai_doc_chat/core/database/local_database.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/retrieval_service.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/export_service.dart';
import 'package:flutter_offline_ai_doc_chat/core/storage/app_preferences.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/pdf_extraction_service.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/local_llm_service.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/cloud_llm_service.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/answer_service.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Database
  sl.registerLazySingleton<LocalDatabase>(() => LocalDatabase());
  sl.registerLazySingleton<AppPreferences>(() => AppPreferences());

  // Services
  sl.registerLazySingleton<DocumentCaptureService>(() => DocumentCaptureServiceImpl());
  sl.registerLazySingleton<OcrService>(() => OcrServiceImpl());
  sl.registerLazySingleton<PdfExtractionService>(
    () => PdfExtractionServiceImpl(sl<OcrService>()),
  );
  sl.registerLazySingleton<RetrievalService>(() => RetrievalServiceImpl());
  sl.registerLazySingleton<LocalLlmService>(
    () => LocalLlmServiceImpl(sl<AppPreferences>()),
  );
  sl.registerLazySingleton<CloudLlmService>(
    () => CloudLlmServiceImpl(sl<AppPreferences>()),
  );
  sl.registerLazySingleton<AnswerService>(
    () => AnswerServiceImpl(
      sl<RetrievalService>(),
      sl<LocalLlmService>(),
      sl<CloudLlmService>(),
      sl<AppPreferences>(),
    ),
  );
  sl.registerLazySingleton<ExportService>(() => ExportService());
}
