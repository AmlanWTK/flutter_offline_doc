enum AnswerMode {
  excerpts,
  localLlm,
  cloudApi;

  String get label => switch (this) {
        AnswerMode.excerpts => 'Keyword excerpts',
        AnswerMode.localLlm => 'Local LLM (GGUF)',
        AnswerMode.cloudApi => 'Cloud API',
      };

  String get subtitle => switch (this) {
        AnswerMode.excerpts =>
          'Fast offline search; returns relevant document excerpts',
        AnswerMode.localLlm =>
          'Runs a GGUF model on-device via llama.cpp (no network)',
        AnswerMode.cloudApi =>
          'OpenAI-compatible API; document text is sent to your endpoint',
      };

  static AnswerMode fromStorage(String? value) {
    return AnswerMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => AnswerMode.excerpts,
    );
  }
}
