# Flutter Offline AI Document Chat

A privacy-first Flutter app to scan documents, extract text with OCR, and chat with your files locally — no account, no cloud uploads.

## Features

- **Document capture** — camera, gallery, and PDF import (mobile OCR via Google ML Kit)
- **Local library** — searchable document list with categories (Study, Finance, Legal, Receipts, Work, Personal)
- **Offline chat** — keyword-based chunk retrieval with source excerpts
- **Export** — share extracted text as Markdown or PDF; export chat history as Markdown
- **Privacy by default** — all data stored locally with Hive

## Screenshots

_Add screenshots of onboarding, library, capture, detail, and chat screens here._

## Quick start

### Prerequisites

- Flutter SDK 3.9+
- Android Studio / Xcode for mobile builds
- Optional: Visual Studio tools for Windows desktop builds

### Install and run

```bash
cd flutter_offline_ai_doc_chat
flutter pub get
flutter run
```

### Platform notes

| Platform | Capture & OCR | Library / Chat / Export |
|----------|---------------|-------------------------|
| Android  | Full support  | Full support            |
| iOS      | Full support  | Full support            |
| Windows/macOS/Linux | Import UI only; OCR requires mobile | Library, chat, export work |

## Architecture

```
lib/
  app/           # Router, theme, dependency injection
  core/          # Database, preferences, utilities
  features/      # UI screens by feature
  shared/        # Models and services (OCR, retrieval, export)
```

### Data flow

1. User captures or imports a document
2. OCR extracts plain text (images on mobile)
3. Document + text saved to Hive
4. Chat queries are chunked and scored by keyword overlap
5. Top chunks are returned as an extractive answer with excerpts

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for more detail.

## Development roadmap

| Phase | Goal | Status |
|-------|------|--------|
| 1 | Foundation — setup, theme, routing, library shell | Done |
| 2 | Document input — camera, gallery, PDF, crop | Done |
| 3 | OCR and storage — ML Kit, Hive, categories | Done |
| 4 | Search and chat MVP — chunking, retrieval UI | Done |
| 5 | Advanced AI — embeddings, local LLM, multi-doc chat | Planned |
| 6 | Polish — export, desktop, tests, docs | Done |

## Testing

```bash
flutter test
flutter analyze
```

## Example content

Sample extracted text for manual QA lives in [docs/examples/sample_extracted_text.md](docs/examples/sample_extracted_text.md).

## Tech stack

- Flutter + Material 3
- go_router, get_it
- Hive (local storage)
- google_mlkit_text_recognition (OCR)
- image_picker, file_picker, image_cropper
- share_plus, pdf (export)

## Contributing

Issues and pull requests welcome. Good first issues:

- PDF page rendering before OCR
- Chat message persistence
- Optional cloud LLM provider with API key storage

## License

MIT — see [LICENSE](LICENSE) if present, or add one before publishing.
