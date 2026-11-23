// Wraps speech_to_text safely for voice search across mobile, web, and tests.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Exposes a shared [VoiceInputService] instance via Riverpod.
final voiceInputProvider = Provider<VoiceInputService>((ref) {
  final service = VoiceInputService();
  ref.onDispose(service.stop);
  return service;
});

/// Safe wrapper around [SpeechToText] guarded for web and headless widget tests.
class VoiceInputService {
  /// Creates a [VoiceInputService] with lazy speech recognizer setup.
  VoiceInputService([this._speech]);

  SpeechToText? _speech;
  bool _initialized = false;
  bool _isListening = false;

  /// Whether a speech recognition session is currently active.
  bool get isListening => _isListening;

  /// Initializes the speech recognizer and returns whether it is available.
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    if (_initialized) return true;
    if (kIsWeb) {
      // Avoid hanging on unsupported browsers or missing Web Speech API.
      return _initSafe(onStatus: onStatus, onError: onError);
    }
    return _initSafe(onStatus: onStatus, onError: onError);
  }

  Future<bool> _initSafe({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    try {
      _speech ??= SpeechToText();
      _initialized = await _speech!.initialize(
        onStatus: (status) {
          _isListening = status == SpeechToText.listeningStatus;
          onStatus?.call(status);
        },
        onError: (err) {
          _isListening = false;
          onError?.call(err.errorMsg);
        },
      );
      return _initialized;
    } catch (_) {
      _initialized = false;
      _isListening = false;
      return false;
    }
  }

  /// Starts listening for speech in [localeCode] and emits recognized words.
  Future<bool> startListening({
    required void Function(String text, bool isFinal) onResult,
    String localeCode = 'sl',
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    final ok = await initialize(onStatus: onStatus, onError: onError);
    if (!ok || _speech == null) return false;
    try {
      _isListening = true;
      await _speech!.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        listenOptions: SpeechListenOptions(
          localeId: _mapSpeechLocale(localeCode),
          listenMode: ListenMode.search,
          partialResults: true,
          cancelOnError: true,
        ),
      );
      return true;
    } catch (_) {
      _isListening = false;
      return false;
    }
  }

  /// Stops listening safely.
  Future<void> stop() async {
    _isListening = false;
    try {
      await _speech?.stop();
    } catch (_) {}
  }

  static String _mapSpeechLocale(String localeCode) {
    switch (localeCode) {
      case 'en':
        return 'en_US';
      case 'de':
        return 'de_DE';
      case 'sr_Latn':
      case 'sr':
        return 'sr_RS';
      case 'sl':
      default:
        return 'sl_SI';
    }
  }
}
