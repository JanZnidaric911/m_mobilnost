// Riverpod providers and pure helpers for ticket catalog, wallet filtering, and timers.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/ticket.dart';
import '../../../data/models/ticket_type.dart';
import '../../../data/repositories/repository_providers.dart';

/// Tickets grouped into active, upcoming, and expired wallet buckets.
@immutable
class PartitionedTickets {
  /// Creates a [PartitionedTickets] bundle.
  const PartitionedTickets({
    required this.active,
    required this.upcoming,
    required this.expired,
  });

  /// Tickets currently valid for boarding.
  final List<Ticket> active;

  /// Tickets scheduled for a future start time.
  final List<Ticket> upcoming;

  /// Tickets past their expiration timestamp.
  final List<Ticket> expired;

  /// Total number of tickets across all buckets.
  int get totalCount => active.length + upcoming.length + expired.length;
}

/// Partitions [tickets] into active, upcoming, and expired lists at [referenceTime].
PartitionedTickets partitionTicketsByStatus(
  List<Ticket> tickets, {
  DateTime? referenceTime,
}) {
  final now = referenceTime ?? DateTime.now();
  final active = <Ticket>[];
  final upcoming = <Ticket>[];
  final expired = <Ticket>[];

  for (final ticket in tickets) {
    switch (ticket.statusAt(now)) {
      case TicketStatus.active:
        active.add(ticket);
      case TicketStatus.upcoming:
        upcoming.add(ticket);
      case TicketStatus.expired:
        expired.add(ticket);
    }
  }

  upcoming.sort((a, b) => a.validFrom.compareTo(b.validFrom));
  expired.sort((a, b) => b.validUntil.compareTo(a.validUntil));

  return PartitionedTickets(
    active: List<Ticket>.unmodifiable(active),
    upcoming: List<Ticket>.unmodifiable(upcoming),
    expired: List<Ticket>.unmodifiable(expired),
  );
}

/// Formats a remaining [duration] as a digital `HH:mm:ss` or `mm:ss` countdown.
String formatTicketCountdown(Duration duration) {
  final safe = duration.isNegative ? Duration.zero : duration;
  final hours = safe.inHours;
  final minutes = safe.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

/// Loads all purchasable Marprom [TicketType] products.
final ticketTypesProvider = FutureProvider<List<TicketType>>((ref) {
  return ref.watch(ticketRepositoryProvider).getTicketTypes();
});

/// Loads a single [TicketType] by [typeId].
final ticketTypeByIdProvider =
    FutureProvider.family<TicketType?, String>((ref, typeId) {
  return ref.watch(ticketRepositoryProvider).getTicketTypeById(typeId);
});

/// Streams offline-saved tickets belonging to the currently signed-in rider.
final userTicketsProvider = StreamProvider<List<Ticket>>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.when(
    data: (u) => u,
    loading: () => authRepo.currentUser,
    error: (_, _) => authRepo.currentUser,
  );
  if (user == null) {
    return Stream<List<Ticket>>.value(const <Ticket>[]);
  }
  return ref.watch(ticketRepositoryProvider).watchUserTickets(user.id);
});

/// Resolves a single [Ticket] by [ticketId] from the current user's wallet.
final ticketByIdProvider = Provider.family<AsyncValue<Ticket?>, String>(
  (ref, ticketId) {
    final ticketsAsync = ref.watch(userTicketsProvider);
    return ticketsAsync.whenData((tickets) {
      for (final ticket in tickets) {
        if (ticket.id == ticketId) return ticket;
      }
      return null;
    });
  },
);
