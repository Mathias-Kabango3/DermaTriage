import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/disease_classes.dart';
import '../../../core/constants/triage_levels.dart';

/// SQLite database singleton for DermaTriage.
///
/// Schema matches the proposal ERD: patients, disease_classes, encounters and
/// model_evaluations. The disease_classes reference table is seeded on create.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  // Table names.
  static const String tablePatient = 'patients';
  static const String tableDiseaseClass = 'disease_classes';
  static const String tableEncounter = 'encounters';
  static const String tableModelEvaluation = 'model_evaluations';

  Database? _db;

  /// Lazily-opened database handle.
  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final String dbPath = await getDatabasesPath();
    final String path = p.join(dbPath, AppConstants.databaseName);
    return openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onConfigure: (db) async {
        // Enforce foreign-key constraints.
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablePatient (
        patient_id TEXT PRIMARY KEY,
        approximate_age INTEGER,
        sex TEXT,
        location TEXT,
        fitzpatrick_type INTEGER,
        consent_given INTEGER NOT NULL DEFAULT 0,
        photo_consent INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableDiseaseClass (
        disease_id INTEGER PRIMARY KEY,
        disease_name TEXT NOT NULL,
        triage_level TEXT NOT NULL,
        description TEXT,
        referral_urgency TEXT,
        ntd_flag INTEGER NOT NULL DEFAULT 0,
        icd10_code TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableEncounter (
        encounter_id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        disease_id INTEGER,
        encounter_date TEXT NOT NULL,
        photo_path TEXT,
        predicted_class TEXT,
        confidence_score REAL,
        triage_category TEXT,
        heatmap_path TEXT,
        synced INTEGER NOT NULL DEFAULT 0,
        chw_notes TEXT,
        FOREIGN KEY (patient_id) REFERENCES $tablePatient (patient_id)
          ON DELETE CASCADE,
        FOREIGN KEY (disease_id) REFERENCES $tableDiseaseClass (disease_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableModelEvaluation (
        eval_id INTEGER PRIMARY KEY AUTOINCREMENT,
        model_version TEXT NOT NULL,
        accuracy_overall REAL,
        dvs_score REAL,
        evaluated_at TEXT NOT NULL
      )
    ''');

    await _seedDiseaseClasses(db);
  }

  /// Populate the disease_classes reference table from the app constants.
  Future<void> _seedDiseaseClasses(Database db) async {
    final Batch batch = db.batch();
    for (final DiseaseClass d in kDiseaseClasses) {
      batch.insert(tableDiseaseClass, <String, dynamic>{
        'disease_id': d.index,
        'disease_name': d.displayName,
        'triage_level': d.triageLevel.id,
        'description': d.description,
        'referral_urgency': d.triageLevel.displayLabel,
        'ntd_flag': d.isNtd ? 1 : 0,
        'icd10_code': d.icd10Code,
      });
    }
    await batch.commit(noResult: true);
  }

  /// Close the database (e.g. on app teardown / tests).
  Future<void> close() async {
    final Database? db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }

  /// Delete all patient/encounter/evaluation data and recreate the schema.
  ///
  /// The disease_classes reference table is re-seeded. Used by the
  /// "Reset All Data" action in settings.
  Future<void> resetDatabase() async {
    final String dbPath = await getDatabasesPath();
    final String path = p.join(dbPath, AppConstants.databaseName);
    await close();
    await deleteDatabase(path);
    _db = await _initDb(); // triggers _onCreate (+ reseed) on the fresh file
  }
}
