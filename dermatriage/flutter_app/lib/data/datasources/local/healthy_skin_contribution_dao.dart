import 'package:sqflite/sqflite.dart';

import '../../models/healthy_skin_contribution.dart';
import 'database_helper.dart';

/// Data-access object for the local healthy-skin contribution upload queue.
class HealthySkinContributionDao {
  static const String _table = DatabaseHelper.tableHealthySkinContribution;

  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<void> insert(HealthySkinContribution contribution) async {
    final db = await _db;
    await db.insert(
      _table,
      contribution.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Rows not yet uploaded, oldest first (so a long-offline backlog uploads
  /// in submission order once connectivity returns).
  Future<List<HealthySkinContribution>> getQueued() async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'sync_status = ?',
      whereArgs: <Object?>[ContributionSyncStatus.queued.id],
      orderBy: 'captured_at ASC',
    );
    return rows.map(HealthySkinContribution.fromMap).toList();
  }

  /// All contributions from this device, newest first — for the "My
  /// Contributions" status list.
  Future<List<HealthySkinContribution>> getAll() async {
    final db = await _db;
    final rows = await db.query(_table, orderBy: 'captured_at DESC');
    return rows.map(HealthySkinContribution.fromMap).toList();
  }

  Future<void> markUploaded(String id) async {
    final db = await _db;
    await db.update(
      _table,
      <String, dynamic>{
        'sync_status': ContributionSyncStatus.uploaded.id,
        'last_error': null,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> markFailed(String id, String error) async {
    final db = await _db;
    await db.update(
      _table,
      <String, dynamic>{'last_error': error},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }
}
