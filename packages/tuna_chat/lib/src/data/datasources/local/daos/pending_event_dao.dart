import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/pending_events_table.dart';

part 'pending_event_dao.g.dart';

@DriftAccessor(tables: [PendingEventsTable])
class PendingEventDao extends DatabaseAccessor<AppDatabase>
    with _$PendingEventDaoMixin {
  PendingEventDao(super.db);

  Future<List<PendingEventRow>> findAll() =>
      (select(pendingEventsTable)
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  Stream<List<PendingEventRow>> watchAll() =>
      (select(pendingEventsTable)
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .watch();

  Future<int> insert(PendingEventsTableCompanion companion) =>
      into(pendingEventsTable).insert(companion);

  Future<void> deleteById(int id) =>
      (delete(pendingEventsTable)..where((t) => t.id.equals(id))).go();

  Future<void> incrementRetry(int id) async {
    final row = await (select(pendingEventsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    await (update(pendingEventsTable)..where((t) => t.id.equals(id))).write(
      PendingEventsTableCompanion(retryCount: Value(row.retryCount + 1)),
    );
  }

  Future<void> deleteAll() => delete(pendingEventsTable).go();
}
