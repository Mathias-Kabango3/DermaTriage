import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/body_regions.dart';
import '../../data/datasources/local/healthy_skin_contribution_dao.dart';
import '../../data/models/healthy_skin_contribution.dart';
import '../../services/contribution/contribution_upload_service.dart';

/// Drives the "contribute a healthy-skin photo" flow and the "My
/// Contributions" status list.
class ContributionProvider extends ChangeNotifier {
  final HealthySkinContributionDao _dao;
  final ContributionUploadService _uploadService;

  ContributionProvider({
    HealthySkinContributionDao? dao,
    ContributionUploadService? uploadService,
  })  : _dao = dao ?? HealthySkinContributionDao(),
        _uploadService = uploadService ?? ContributionUploadService.instance;

  List<HealthySkinContribution> _items = <HealthySkinContribution>[];
  List<HealthySkinContribution> get items => _items;

  /// Save a captured photo locally and queue it for upload. Never blocks on
  /// the network — capture succeeds immediately regardless of connectivity.
  Future<void> submit({
    required String localPhotoPath,
    required int fitzpatrickType,
    required BodyRegion bodyRegion,
    required String contributorId,
    required String facility,
  }) async {
    final contribution = HealthySkinContribution(
      id: const Uuid().v4(),
      localPhotoPath: localPhotoPath,
      fitzpatrickType: fitzpatrickType,
      bodyRegion: bodyRegion,
      contributorId: contributorId,
      facility: facility,
      capturedAt: DateTime.now(),
    );
    await _uploadService.enqueue(contribution);
    await refresh();
  }

  /// Reload this device's contribution list and retry any queued uploads.
  Future<void> refresh() async {
    _items = await _dao.getAll();
    notifyListeners();
    await _uploadService.syncPending();
    _items = await _dao.getAll();
    notifyListeners();
  }
}
