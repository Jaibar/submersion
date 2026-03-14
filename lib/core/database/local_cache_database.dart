import 'package:drift/drift.dart';

part 'local_cache_database.g.dart';

/// Local-only table for caching resolved asset IDs per device.
/// This table is NOT synced — it lives in a separate database file.
class LocalAssetCache extends Table {
  TextColumn get mediaId => text()();
  TextColumn get localAssetId => text().nullable()();
  IntColumn get resolvedAt => integer()();
  TextColumn get resolutionMethod => text()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {mediaId};
}

@DriftDatabase(tables: [LocalAssetCache])
class LocalCacheDatabase extends _$LocalCacheDatabase {
  LocalCacheDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
