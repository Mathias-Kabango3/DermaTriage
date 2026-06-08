import 'package:sqflite/sqflite.dart';

import '../../models/patient.dart';
import 'database_helper.dart';

/// Data-access object for the `patients` table.
class PatientDao {
  static const String _table = DatabaseHelper.tablePatient;

  Future<Database> get _db async => DatabaseHelper.instance.database;

  /// Insert (or replace) a patient. Returns the row id.
  Future<int> insertPatient(Patient patient) async {
    final db = await _db;
    return db.insert(
      _table,
      patient.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetch a single patient by id, or null if not found.
  Future<Patient?> getPatient(String id) async {
    final db = await _db;
    final List<Map<String, dynamic>> rows = await db.query(
      _table,
      where: 'patient_id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Patient.fromMap(rows.first);
  }

  /// All patients, newest first.
  Future<List<Patient>> getAllPatients() async {
    final db = await _db;
    final List<Map<String, dynamic>> rows = await db.query(
      _table,
      orderBy: 'created_at DESC',
    );
    return rows.map(Patient.fromMap).toList();
  }

  /// Update an existing patient. Returns the number of rows affected.
  Future<int> updatePatient(Patient patient) async {
    final db = await _db;
    return db.update(
      _table,
      patient.toMap(),
      where: 'patient_id = ?',
      whereArgs: <Object?>[patient.id],
    );
  }

  /// Delete a patient by id. Returns the number of rows affected.
  Future<int> deletePatient(String id) async {
    final db = await _db;
    return db.delete(
      _table,
      where: 'patient_id = ?',
      whereArgs: <Object?>[id],
    );
  }
}
