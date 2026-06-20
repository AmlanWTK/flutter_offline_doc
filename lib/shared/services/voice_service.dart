import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isSpeechInitialized = false;

  Future<void> initialize() async {
    _isSpeechInitialized = await _speech.initialize(
      onError: (e) => print('STT Error: $e'),
      onStatus: (s) => print('STT Status: $s'),
    );

    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  // ── STT ──────────────────────────────────────────────────────────────────
  bool get isListening => _speech.isListening;

  Future<bool> startListening({required Function(String) onResult}) async {
    if (!_isSpeechInitialized) {
      _isSpeechInitialized = await _speech.initialize();
      if (!_isSpeechInitialized) return false;
    }

    try {
      await _speech.listen(onResult: (result) {
        onResult(result.recognizedWords);
      });
      return true;
    } catch (e) {
      print("STT Listen Error: $e");
      return false;
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  // ── TTS ──────────────────────────────────────────────────────────────────
  bool _isBengali(String text) {
    return RegExp(r'[\u0980-\u09FF]').hasMatch(text);
  }

  Future<void> speak(String text) async {
    if (_isBengali(text)) {
      // Try to set Bengali language for TTS
      await _tts.setLanguage("bn-BD");
    } else {
      await _tts.setLanguage("en-US");
    }
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }
}
