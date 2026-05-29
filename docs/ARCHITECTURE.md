# Architecture

## Layers

The app uses a lightweight feature-first structure:

- **Presentation** — Flutter screens under `lib/features/`
- **Application services** — OCR, capture, retrieval, export under `lib/shared/services/`
- **Data** — Hive-backed `LocalDatabase` and `AppPreferences`

Dependency injection is handled with `get_it` in `lib/app/di/service_locator.dart`.

## Key modules

### Document capture

`DocumentCaptureService` wraps camera, gallery, file picker, and optional image cropping.
On desktop, camera and ML Kit OCR are unavailable; the UI falls back to file import messaging.

### OCR

`OcrService` uses Google ML Kit for English image OCR and Tesseract (`ben`, `ben+eng`) for Bangla.

### PDF extraction

`PdfExtractionService` uses pdfrx (PDFium) per page:

1. Try embedded text via `loadText()` (fast, works for digital PDFs with Unicode Bangla/English).
2. If a page has little or no text (scanned PDF), render the page to an image and run OCR with the selected language.

Use **English + Bangla** for mixed documents.

### Retrieval & answers

`RetrievalService` chunks documents and scores chunks by keyword overlap.

`AnswerService` routes the top chunks to one of three backends (`AnswerMode` in `AppPreferences`):

| Mode | Backend | Notes |
|------|---------|--------|
| `excerpts` | `RetrievalService.generateAnswer` | Default; fully offline |
| `localLlm` | `LocalLlmService` + `llamadart` | User picks a GGUF file; Android minSdk 29 |
| `cloudApi` | `CloudLlmService` | OpenAI-compatible `/chat/completions` |

`RagPromptBuilder` formats document excerpts + question for LLM backends.

### Export

`ExportService` writes Markdown or PDF to a temp file and opens the system share sheet.

## Routing

`GoRouter` redirects first-time users to onboarding until `AppPreferences.hasCompletedOnboarding` is true.

## Future extensions

- Local embeddings + vector search (semantic retrieval)
- Multi-document chat sessions
- Chat history persistence in Hive
