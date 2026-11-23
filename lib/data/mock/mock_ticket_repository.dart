// Mock TicketRepository issuing immediate or start-later tickets with Hive persistence.

import 'dart:async';

import '../models/ticket.dart';
import '../models/ticket_type.dart';
import '../repositories/ticket_repository.dart';
import '../seed/seed_tickets.dart';
import 'local_storage_helper.dart';

/// Mock [TicketRepository] persisting tickets offline in Hive (or memory in tests).
class MockTicketRepository implements TicketRepository {
  /// Creates a [MockTicketRepository] backed by Hive box [boxName].
  MockTicketRepository({
    String boxName = 'm_mobilnost_tickets',
    DateTime Function()? clock,
  })  : _store = LocalKeyValueStore(boxName),
        _clock = clock ?? DateTime.now {
    _controller = StreamController<(String, List<Ticket>)>.broadcast();
  }

  final LocalKeyValueStore _store;
  final DateTime Function() _clock;
  late final StreamController<(String, List<Ticket>)> _controller;
  int _sequence = 0;

  @override
  Future<List<TicketType>> getTicketTypes() async =>
      List<TicketType>.unmodifiable(seedTicketTypes);

  @override
  Future<TicketType?> getTicketTypeById(String typeId) async =>
      seedTicketTypesById[typeId];

  @override
  Future<List<Ticket>> getUserTickets(String userId) async {
    final entries = await _store.readAllEntries();
    final tickets = <Ticket>[];
    for (final value in entries.values) {
      if (value is Map) {
        final ticket = Ticket.fromJson(value);
        if (ticket.userId == userId) {
          tickets.add(ticket);
        }
      }
    }
    tickets.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
    return tickets;
  }

  @override
  Stream<List<Ticket>> watchUserTickets(String userId) async* {
    yield await getUserTickets(userId);
    await for (final event in _controller.stream) {
      if (event.$1 == userId || event.$1 == '*') {
        yield event.$2.where((t) => t.userId == userId).toList(growable: false);
      }
    }
  }

  @override
  Future<Ticket> purchaseTicket({
    required TicketType type,
    required String userId,
    DateTime? validFrom,
  }) async {
    _sequence++;
    final now = _clock();
    final id = 'tkt_${now.microsecondsSinceEpoch}_$_sequence';
    final start = validFrom ?? now;
    final end = start.add(Duration(minutes: type.durationMinutes));

    final shortCode = ((now.millisecondsSinceEpoch + _sequence * 7919) % 10000)
        .toString()
        .padLeft(4, '0');
    final suffix = (_sequence % 10000).toString().padLeft(4, '0');

    final ticket = Ticket.issue(
      id: id,
      ticketTypeId: type.id,
      ticketCode: type.code,
      titles: type.titles,
      priceEur: type.priceEur,
      zone: type.zone,
      durationMinutes: type.durationMinutes,
      purchasedAt: now,
      validFrom: start,
      qrPayload:
          'MM2|${type.code}|$id|${start.toIso8601String()}|${end.toIso8601String()}',
      driverFallbackCode: 'MB-$shortCode-$suffix',
      userId: userId,
    );

    await _store.write('ticket_$id', ticket.toJson());
    await _emitForUser(userId);
    return ticket;
  }

  @override
  Future<Ticket> validateTicket(String ticketId) async {
    final raw = await _store.read('ticket_$ticketId');
    if (raw is! Map) {
      throw StateError('Ticket $ticketId not found.');
    }
    final updated = Ticket.fromJson(raw).copyWith(validatedAt: _clock());
    await _store.write('ticket_$ticketId', updated.toJson());
    await _emitForUser(updated.userId);
    return updated;
  }

  @override
  Future<void> clearTicketsForUser(String userId) async {
    final entries = await _store.readAllEntries();
    for (final entry in entries.entries) {
      final val = entry.value;
      if (val is Map && val['userId'] == userId) {
        await _store.delete(entry.key);
      }
    }
    await _emitForUser(userId);
  }

  @override
  Future<void> clearAllTickets() async {
    await _store.clear();
    if (!_controller.isClosed) {
      _controller.add(('*', const []));
    }
  }

  Future<void> _emitForUser(String userId) async {
    if (_controller.isClosed) return;
    final list = await getUserTickets(userId);
    if (!_controller.isClosed) {
      _controller.add((userId, list));
    }
  }

  @override
  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
