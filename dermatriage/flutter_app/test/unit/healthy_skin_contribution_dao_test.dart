import 'package:dermatriage/core/constants/app_constants.dart';
import 'package:dermatriage/core/constants/body_regions.dart';
import 'package:dermatriage/data/datasources/local/database_helper.dart';
import 'package:dermatriage/data/datasources/local/healthy_skin_contribution_dao.dart';
import 'package:dermatriage/data/models/healthy_skin_contribution.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Covers the local upload-queue path for the healthy-skin contribution
/// flow: the model's SQLite round-trip and the DAO's queue/status queries.
/// Uses `sqflite_common_ffi` so these run on the host without an Android/iOS
/// simulator — see reference-ml-gotchas memory for the same pattern used by
/// the other on-device data tests in this project.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    // `DatabaseHelper.instance` is a real singleton, so closing the
    // connection alone would leave the same on-disk file for the next test
    // to reopen. Delete it so every test starts from a clean schema.
    await DatabaseHelper.instance.close();
    final String dbPath =
        p.join(await databaseFactory.getDatabasesPath(), AppConstants.databaseName);
    await databaseFactory.deleteDatabase(dbPath);
  });

  HealthySkinContribution sample({
    String id = 'c1',
    BodyRegion bodyRegion = BodyRegion.forearm,
    int fitzpatrickType = 3,
    ContributionSyncStatus syncStatus = ContributionSyncStatus.queued,
    DateTime? capturedAt,
  }) {
    return HealthySkinContribution(
      id: id,
      localPhotoPath: '/tmp/$id.jpg',
      fitzpatrickType: fitzpatrickType,
      bodyRegion: bodyRegion,
      contributorId: 'chw-uid-1',
      facility: 'Kigali Health Post',
      capturedAt: capturedAt ?? DateTime.utc(2026, 1, 15, 9, 30),
      syncStatus: syncStatus,
    );
  }

  group('HealthySkinContribution.toMap/fromMap', () {
    test('round-trips every field exactly', () {
      final HealthySkinContribution original = sample(
        bodyRegion: BodyRegion.lowerLeg,
        fitzpatrickType: 5,
        syncStatus: ContributionSyncStatus.uploaded,
      );

      final HealthySkinContribution restored =
          HealthySkinContribution.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.localPhotoPath, original.localPhotoPath);
      expect(restored.fitzpatrickType, original.fitzpatrickType);
      expect(restored.bodyRegion, BodyRegion.lowerLeg);
      expect(restored.contributorId, original.contributorId);
      expect(restored.facility, original.facility);
      expect(restored.capturedAt, original.capturedAt);
      expect(restored.syncStatus, ContributionSyncStatus.uploaded);
      expect(restored.lastError, isNull);
    });

    test('stores the body region as the dashboard-matching slug, not the '
        'Dart enum name', () {
      final Map<String, dynamic> map =
          sample(bodyRegion: BodyRegion.upperArm).toMap();
      expect(map['body_region'], 'upper_arm');
    });

    test('converts 1-6 Fitzpatrick ints to Roman numerals I-VI', () {
      for (int i = 1; i <= 6; i++) {
        final HealthySkinContribution c = sample(fitzpatrickType: i);
        expect(c.fitzpatrickRoman, <String>['I', 'II', 'III', 'IV', 'V', 'VI'][i - 1]);
      }
    });

    test('preserves a non-null lastError through the round trip', () {
      final HealthySkinContribution withError =
          sample().copyWith(lastError: 'network unreachable');
      final HealthySkinContribution restored =
          HealthySkinContribution.fromMap(withError.toMap());
      expect(restored.lastError, 'network unreachable');
    });
  });

  group('HealthySkinContributionDao', () {
    test('insert + getAll returns the inserted row', () async {
      final HealthySkinContributionDao dao = HealthySkinContributionDao();
      await dao.insert(sample(id: 'a'));

      final List<HealthySkinContribution> all = await dao.getAll();

      expect(all, hasLength(1));
      expect(all.single.id, 'a');
      expect(all.single.syncStatus, ContributionSyncStatus.queued);
    });

    test('getQueued excludes uploaded rows and orders oldest first',
        () async {
      final HealthySkinContributionDao dao = HealthySkinContributionDao();
      await dao.insert(sample(
        id: 'newer',
        capturedAt: DateTime.utc(2026, 1, 20),
      ));
      await dao.insert(sample(
        id: 'older',
        capturedAt: DateTime.utc(2026, 1, 10),
      ));
      await dao.insert(sample(
        id: 'already-uploaded',
        syncStatus: ContributionSyncStatus.uploaded,
        capturedAt: DateTime.utc(2026, 1, 1),
      ));

      final List<HealthySkinContribution> queued = await dao.getQueued();

      expect(queued.map((c) => c.id).toList(), <String>['older', 'newer']);
    });

    test('getAll orders newest capture first', () async {
      final HealthySkinContributionDao dao = HealthySkinContributionDao();
      await dao.insert(sample(id: 'older', capturedAt: DateTime.utc(2026, 1, 1)));
      await dao.insert(sample(id: 'newer', capturedAt: DateTime.utc(2026, 1, 20)));

      final List<HealthySkinContribution> all = await dao.getAll();

      expect(all.map((c) => c.id).toList(), <String>['newer', 'older']);
    });

    test('markUploaded flips status and clears lastError', () async {
      final HealthySkinContributionDao dao = HealthySkinContributionDao();
      await dao.insert(sample(id: 'a'));
      await dao.markFailed('a', 'timeout');

      await dao.markUploaded('a');

      final HealthySkinContribution row = (await dao.getAll()).single;
      expect(row.syncStatus, ContributionSyncStatus.uploaded);
      expect(row.lastError, isNull);
    });

    test('markFailed records the error but leaves the row queued for retry',
        () async {
      final HealthySkinContributionDao dao = HealthySkinContributionDao();
      await dao.insert(sample(id: 'a'));

      await dao.markFailed('a', 'storage/unauthorized');

      final HealthySkinContribution row = (await dao.getAll()).single;
      expect(row.syncStatus, ContributionSyncStatus.queued);
      expect(row.lastError, 'storage/unauthorized');
      expect(await dao.getQueued(), hasLength(1));
    });

    test('insert with the same id replaces the existing row', () async {
      final HealthySkinContributionDao dao = HealthySkinContributionDao();
      await dao.insert(sample(id: 'a', fitzpatrickType: 2));
      await dao.insert(sample(id: 'a', fitzpatrickType: 4));

      final List<HealthySkinContribution> all = await dao.getAll();

      expect(all, hasLength(1));
      expect(all.single.fitzpatrickType, 4);
    });
  });
}
