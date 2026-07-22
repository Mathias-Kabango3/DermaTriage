import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/body_regions.dart';
import '../../core/constants/cloudinary_config.dart';
import '../../data/datasources/local/healthy_skin_contribution_dao.dart';
import '../../data/models/healthy_skin_contribution.dart';

/// Uploads queued healthy-skin contribution photos to Cloudinary (the photo
/// bytes) + Firestore (the metadata), matching the offline-first pattern the
/// rest of the app already uses: capture always succeeds locally first; the
/// network step happens in the background and is retried automatically once
/// connectivity returns.
///
/// This is the mobile-side counterpart to the review dashboard
/// (`review_dashboard/`) — see docs/review_dashboard_schema.md for the shared
/// `healthy_skin_contributions` collection contract. A contribution's local
/// row id is reused as the Firestore document id, so each device's queue maps
/// 1:1 onto a document without needing a separate remote-id column.
class ContributionUploadService {
  ContributionUploadService._();
  static final ContributionUploadService instance =
      ContributionUploadService._();

  final HealthySkinContributionDao _dao = HealthySkinContributionDao();
  bool _syncing = false;
  bool _autoSyncStarted = false;

  static const String _collection = 'healthy_skin_contributions';

  /// Queue a freshly captured photo, then immediately try to upload it (a
  /// no-op network attempt if offline — it simply stays queued).
  Future<void> enqueue(HealthySkinContribution contribution) async {
    await _dao.insert(contribution);
    unawaited(syncPending());
  }

  /// Attempt to upload every not-yet-uploaded contribution. Safe to call
  /// repeatedly (e.g. on every app start and every connectivity change) —
  /// re-entrant calls are ignored while a sync is already running.
  Future<void> syncPending() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final List<HealthySkinContribution> queued = await _dao.getQueued();
      for (final HealthySkinContribution c in queued) {
        await _uploadOne(c);
      }
    } finally {
      _syncing = false;
    }
  }

  /// Start automatic background sync: one attempt now, then again whenever
  /// connectivity is regained. Call once from main() after Firebase/auth
  /// init. Safe to call more than once (subsequent calls are ignored).
  void startAutoSync() {
    if (_autoSyncStarted) return;
    _autoSyncStarted = true;
    unawaited(syncPending());
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> r) {
      if (!r.contains(ConnectivityResult.none)) {
        unawaited(syncPending());
      }
    });
  }

  Future<void> _uploadOne(HealthySkinContribution c) async {
    try {
      final File file = File(c.localPhotoPath);
      if (!await file.exists()) {
        // The photo went missing on disk — nothing to retry.
        await _dao.markFailed(c.id, 'Local photo file no longer exists.');
        return;
      }

      final String imageUrl = await _uploadToCloudinary(file, c.id);

      // submittedAt is the true capture time, not "whenever this device
      // finally got signal" — a contribution can sit queued offline for
      // days, and the dashboard's audit trail should reflect when it was
      // actually taken.
      await FirebaseFirestore.instance.collection(_collection).doc(c.id).set(
        <String, dynamic>{
          'imageUrl': imageUrl,
          'fitzpatrickType': c.fitzpatrickRoman,
          'bodyRegion': c.bodyRegion.id,
          'contributorId': c.contributorId,
          'facility': c.facility,
          'submittedAt': Timestamp.fromDate(c.capturedAt),
          'status': 'pending',
          'plausibilityScore': null,
          'reviewNote': null,
          'reviewedBy': null,
          'reviewedAt': null,
        },
      );

      await _dao.markUploaded(c.id);
    } catch (e, st) {
      // Expected in normal offline use — stays queued for the next attempt.
      developer.log(
        'Contribution upload deferred (will retry): ${c.id}',
        name: 'ContributionUploadService',
        error: e,
        stackTrace: st,
      );
      await _dao.markFailed(c.id, e.toString());
    }
  }

  /// Uploads [file] to Cloudinary via an unsigned upload preset (see
  /// cloudinary_config.dart) and returns the resulting public
  /// `secure_url` — stored directly in Firestore's `imageUrl` field, so the
  /// review dashboard can load it with a plain `<img>`, no separate
  /// download-URL resolution step needed.
  Future<String> _uploadToCloudinary(File file, String contributionId) async {
    final http.MultipartRequest request =
        http.MultipartRequest('POST', CloudinaryConfig.uploadEndpoint)
          ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
          ..fields['public_id'] = contributionId
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final http.StreamedResponse streamed = await request.send();
    final String body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw Exception('Cloudinary upload failed (${streamed.statusCode}): $body');
    }

    final Map<String, dynamic> json =
        jsonDecode(body) as Map<String, dynamic>;
    final String? secureUrl = json['secure_url'] as String?;
    if (secureUrl == null) {
      throw Exception('Cloudinary response missing secure_url: $body');
    }
    return secureUrl;
  }
}

/// Explicitly discard a Future — same intent as package:pedantic's
/// `unawaited`, inlined to avoid adding a dependency for one helper.
void unawaited(Future<void> future) {}
