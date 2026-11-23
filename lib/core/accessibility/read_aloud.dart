// Wraps flutter_tts safely for screen read-aloud across mobile, web, and tests.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Exposes a shared [ReadAloudService] instance for spoken accessibility cues.
final readAloudProvider = Provider<ReadAloudService>((ref) {
  final service = ReadAloudService();
  ref.onDispose(service.dispose);
  return service;
});

/// Safe wrapper around [FlutterTts] that degrades gracefully on web and tests.
class ReadAloudService {
  /// Creates a [ReadAloudService] with lazy plugin initialization.
  ReadAloudService([this._tts]);

  FlutterTts? _tts;
  bool _disposed = false;

  FlutterTts? _ensureInstance() {
    if (_disposed) return null;
    if (_tts != null) return _tts;
    try {
      _tts = FlutterTts();
      return _tts;
    } catch (_) {
      return null;
    }
  }

  /// Speaks [text] in [localeCode] when [enabled] is true.
  Future<void> speak(
    String text, {
    required bool enabled,
    String localeCode = 'sl',
  }) async {
    if (!enabled || text.trim().isEmpty || _disposed) return;
    // Web browsers require user gesture and may throw on headless runners.
    if (kIsWeb) {
      await _speakSafe(text, localeCode);
      return;
    }
    await _speakSafe(text, localeCode);
  }

  Future<void> _speakSafe(String text, String localeCode) async {
    try {
      final tts = _ensureInstance();
      if (tts == null) return;
      await tts.stop();
      await tts.setLanguage(_mapTtsLocale(localeCode));
      await tts.setSpeechRate(0.5);
      await tts.speak(text);
    } catch (_) {
      // Gracefully ignore missing plugin implementations in tests/headless environments.
    }
  }

  /// Stops any active speech playback safely.
  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {
      // Ignore missing platform handlers.
    }
  }

  /// Releases underlying TTS resources.
  void dispose() {
    _disposed = true;
    try {
      _tts?.stop();
    } catch (_) {}
  }

  static String _mapTtsLocale(String localeCode) {
    switch (localeCode) {
      case 'en':
        return 'en-US';
      case 'de':
        return 'de-DE';
      case 'sr_Latn':
      case 'sr':
        return 'sr-RS';
      case 'sl':
      default:
        return 'sl-SI';
    }
  }
}
