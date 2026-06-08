import 'package:sqflite/sqflite.dart';

import '../../models/encounter.dart';
import 'database_helper.dart';

/// Data-access object for the `encounters` table.
class EncounterDao {
  static const String _table = DatabaseHelper.tableEncounter;

  Future<Database> get _db async => DatabaseHelper.instance.database;

  /// Insert (or replace) an encounter. Returns the row id.
  Future<int> insertEncounter(Encounter encounter) async {
    final db = await _db;
    return db.insert(
      _table,
      encounter.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// All encounters for a patient, most recent first.
  Future<List<Encounter>> getEncountersByPatient(String patientId) async {
    final db = await _db;
    final List<Map<String, dynamic>> rows = await db.query(
      _table,
      where: 'patient_id = ?',
      whereArgs: <Object?>[patientId],
      orderBy: 'encounter_date DESC',
    );
    return rows.map(Encounter.fromMap).toList();
  }

  /// All encounters across all patients, most recent first.
  Future<List<Encounter>> getAllEncounters() async {
    final db = await _db;
    final List<Map<String, dynamic>> rows = await db.query(
      _table,
      orderBy: 'encounter_date DESC',
    );
    return rows.map(Encounter.fromMap).toList();
  }

  /// Fetch a single encounter by id, or null if not found.
  Future<Encounter?> getEncounter(String id) async {
    final db = await _db;
    final List<Map<String, dynamic>> rows = await db.query(
      _table,
      where: 'encounter_id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Encounter.fromMap(rows.first);
  }
}
