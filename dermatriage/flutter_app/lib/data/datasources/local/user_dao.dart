import 'package:sqflite/sqflite.dart';

import '../../models/app_user.dart';
import 'database_helper.dart';

/// Data-access object for the `users` table (offline CHW accounts).
class UserDao {
  static const String _table = DatabaseHelper.tableUser;

  Future<Database> get _db async => DatabaseHelper.instance.database;

  /// Insert a new user. Returns the new row id.
  Future<int> insertUser(AppUser user) async {
    final db = await _db;
    return db.insert(_table, user.toMap());
  }

  /// Fetch a user by username (case-insensitive), or null if not found.
  Future<AppUser?> getByUsername(String username) async {
    final db = await _db;
    final List<Map<String, dynamic>> rows = await db.query(
      _table,
      where: 'username = ? COLLATE NOCASE',
      whereArgs: <Object?>[username],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  /// Update the stored bcrypt password hash for [username]. Returns the
  /// number of rows affected.
  Future<int> updatePasswordHash(String username, String passwordHash) async {
    final db = await _db;
    return db.update(
      _table,
      <String, dynamic>{'password_hash': passwordHash},
      where: 'username = ? COLLATE NOCASE',
      whereArgs: <Object?>[username],
    );
  }

  /// Total number of registered users.
  Future<int> count() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_table');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
