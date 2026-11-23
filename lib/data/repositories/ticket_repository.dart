// Abstract repository contract for Marprom ticket catalog and offline ticket wallet.

import '../models/ticket.dart';
import '../models/ticket_type.dart';

// TODO(firebase): Replace mock implementation with Firestore + Cloud Functions ticket minting.
/// Manages ticket products, purchases, validation, and offline persistence.
abstract class TicketRepository {
  /// Returns all available Marprom ticket types.
  Future<List<TicketType>> getTicketTypes();

  /// Looks up a single [TicketType] by [typeId].
  Future<TicketType?> getTicketTypeById(String typeId);

  /// Loads all purchased tickets belonging to [userId] from local/remote storage.
  Future<List<Ticket>> getUserTickets(String userId);

  /// Streams ticket list updates for [userId].
  Stream<List<Ticket>> watchUserTickets(String userId);

  /// Issues a new ticket for [type], activating immediately unless [validFrom] is set.
  Future<Ticket> purchaseTicket({
    required TicketType type,
    required String userId,
    DateTime? validFrom,
  });

  /// Records simulated QR/NFC boarding validation for [ticketId].
  Future<Ticket> validateTicket(String ticketId);

  /// Removes all tickets associated with [userId].
  Future<void> clearTicketsForUser(String userId);

  /// Clears every locally stored ticket across all users.
  Future<void> clearAllTickets();

  /// Releases stream controllers.
  void dispose();
}
