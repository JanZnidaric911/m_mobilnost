// Abstract NFC card reader contract and coming-soon stub implementation for tickets.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Snapshot describing simulated or device NFC card reader availability.
@immutable
class NfcCardReaderStatus {
  /// Creates an [NfcCardReaderStatus] payload.
  const NfcCardReaderStatus({
    required this.isAvailable,
    required this.message,
  });

  /// Whether hardware NFC card emulation/reading is currently enabled.
  final bool isAvailable;

  /// Human-readable status note for diagnostics and stub tests.
  final String message;
}

/// Abstract contract for contactless NFC transit card reading and validation.
abstract class TicketCardReader {
  /// Returns true when physical NFC card reading is supported and active.
  Future<bool> isAvailable();

  /// Returns the current NFC card reader status and availability note.
  Future<NfcCardReaderStatus> readCardStatus();

  /// Simulates tapping the device at a validator for [ticketId], returning the timestamp.
  Future<DateTime> simulateTapValidation(String ticketId);
}

/// Stub [TicketCardReader] reporting NFC card support as coming soon.
class StubTicketCardReader implements TicketCardReader {
  /// Creates a [StubTicketCardReader] with an optional deterministic [clock].
  const StubTicketCardReader({this._clock});

  /// Canonical stub availability message returned until native NFC lands.
  static const String comingSoonMessage = 'NFC card in app coming soon';

  final DateTime Function()? _clock;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<NfcCardReaderStatus> readCardStatus() async {
    return const NfcCardReaderStatus(
      isAvailable: false,
      message: comingSoonMessage,
    );
  }

  @override
  Future<DateTime> simulateTapValidation(String ticketId) async {
    if (ticketId.trim().isEmpty) {
      throw ArgumentError.value(ticketId, 'ticketId', 'Must not be empty.');
    }
    return (_clock ?? DateTime.now)();
  }
}

/// Provides the active [TicketCardReader] implementation across the app.
final ticketCardReaderProvider = Provider<TicketCardReader>((ref) {
  return const StubTicketCardReader();
});
