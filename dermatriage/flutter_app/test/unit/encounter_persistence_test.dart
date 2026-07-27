import 'package:dermatriage/core/constants/app_constants.dart';
import 'package:dermatriage/data/datasources/local/database_helper.dart';
import 'package:dermatriage/data/datasources/local/encounter_dao.dart';
import 'package:dermatriage/data/datasources/local/patient_dao.dart';
import 'package:dermatriage/data/models/encounter.dart';
import 'package:dermatriage/data/models/patient.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Phase 4/5 schema (database v5): the retrieval summary columns on
/// `encounters` round-trip through the DAO, and stay nullable so a
/// rejection-outcome encounter (no retrieval) is still valid.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
    final String dbPath = p.join(
        await databaseFactory.getDatabasesPath(), AppConstants.databaseName);
    await databaseFactory.deleteDatabase(dbPath);
  });

  Future<void> seedPatient(String id) async {
    await PatientDao().insertPatient(Patient(
      id: id,
      name: 'Test Patient',
      approximateAge: 40,
      sex: 'F',
      location: 'Kigali',
      fitzpatrickType: 5,
      consentGiven: true,
      photoConsent: true,
      createdAt: DateTime.now(),
    ));
  }

  test('encounter round-trips the retrieval summary fields', () async {
    await seedPatient('pat-1');
    final Encounter e = Encounter(
      encounterId: 'enc-1',
      patientId: 'pat-1',
      photoPath: '/tmp/x.jpg',
      predictedClass: 'eczema',
      confidenceScore: 0.82,
      triageCategory: 'monitor',
      encounterDate: DateTime.now(),
      retrievalTop1Label: 'eczema',
      retrievalTop1Similarity: 0.9137,
      retrievalAgreement: true,
    );
    await EncounterDao().insertEncounter(e);

    final Encounter? got = await EncounterDao().getEncounter('enc-1');
    expect(got, isNotNull);
    expect(got!.retrievalTop1Label, 'eczema');
    expect(got.retrievalTop1Similarity, closeTo(0.9137, 1e-6));
    expect(got.retrievalAgreement, isTrue);
  });

  test('retrieval fields stay null for a rejection-outcome encounter',
      () async {
    await seedPatient('pat-2');
    await EncounterDao().insertEncounter(Encounter(
      encounterId: 'enc-2',
      patientId: 'pat-2',
      photoPath: '/tmp/y.jpg',
      predictedClass: 'not_skin',
      confidenceScore: 0.71,
      triageCategory: 'monitor',
      encounterDate: DateTime.now(),
    ));

    final Encounter got = (await EncounterDao().getEncounter('enc-2'))!;
    expect(got.retrievalTop1Label, isNull);
    expect(got.retrievalTop1Similarity, isNull);
    expect(got.retrievalAgreement, isNull);
  });

  test('disagreement is stored as false, not null', () async {
    await seedPatient('pat-3');
    await EncounterDao().insertEncounter(Encounter(
      encounterId: 'enc-3',
      patientId: 'pat-3',
      photoPath: '/tmp/z.jpg',
      predictedClass: 'fungal',
      confidenceScore: 0.65,
      triageCategory: 'treat_locally',
      encounterDate: DateTime.now(),
      retrievalTop1Label: 'eczema',
      retrievalTop1Similarity: 0.71,
      retrievalAgreement: false,
    ));

    final Encounter got = (await EncounterDao().getEncounter('enc-3'))!;
    expect(got.retrievalAgreement, isFalse);
  });

  test(
      'migration tolerates a stale db where a column already exists under '
      'an older recorded version', () async {
    // Reproduces a real crash: a device's on-disk database physically
    // already has patients.name (e.g. from an earlier development build)
    // but is recorded at user_version 3 — so opening it re-triggers the v4
    // migration, which used to try to re-add a column that's already there
    // and crash with "duplicate column name: name".
    final String dbPath = p.join(
        await databaseFactory.getDatabasesPath(), AppConstants.databaseName);

    final raw = await databaseFactory.openDatabase(dbPath);
    await raw.execute('''
      CREATE TABLE patients (
        patient_id TEXT PRIMARY KEY,
        name TEXT NOT NULL DEFAULT '',
        approximate_age INTEGER,
        sex TEXT,
        location TEXT,
        fitzpatrick_type INTEGER,
        consent_given INTEGER NOT NULL DEFAULT 0,
        photo_consent INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    // The rest of the v3 shape (pre-dating v4/v5) must exist too, or the v5
    // migration fails for an unrelated reason (no such table) instead of
    // exercising the "column already exists" path this test targets.
    await raw.execute('''
      CREATE TABLE encounters (
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
        chw_notes TEXT
      )
    ''');
    await raw.execute('PRAGMA user_version = 3');
    await raw.close();

    // Opening through the real DatabaseHelper upgrades 3 -> 5. This must not
    // throw even though patients.name already physically exists.
    await DatabaseHelper.instance.database;

    await seedPatient('pat-stale');
    final Patient? patient = await PatientDao().getPatient('pat-stale');
    expect(patient, isNotNull);
  });
}
