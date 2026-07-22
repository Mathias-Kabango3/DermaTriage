import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/body_regions.dart';
import '../../../core/theme/colors.dart';
import '../../../data/models/healthy_skin_contribution.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/contribution_provider.dart';

/// Read-only status list of healthy-skin photos submitted from this device —
/// mirrors the offline-first pattern used elsewhere (e.g. Encounter History):
/// shows local sync state, not the dermatologist's review decision (that
/// lives in the review dashboard, not on the device).
class MyContributionsScreen extends StatefulWidget {
  const MyContributionsScreen({super.key});

  @override
  State<MyContributionsScreen> createState() => _MyContributionsScreenState();
}

class _MyContributionsScreenState extends State<MyContributionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContributionProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myContributionsTitle)),
      body: Consumer<ContributionProvider>(
        builder: (BuildContext context, ContributionProvider provider, _) {
          final items = provider.items;
          if (items.isEmpty) {
            return Center(
              child: Text(
                l10n.noContributionsYet,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                return _ContributionTile(item: items[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ContributionTile extends StatelessWidget {
  final HealthySkinContribution item;

  const _ContributionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool uploaded = item.syncStatus == ContributionSyncStatus.uploaded;
    final File photo = File(item.localPhotoPath);

    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 48,
            height: 48,
            child: photo.existsSync()
                ? Image.file(photo, fit: BoxFit.cover)
                : Container(color: AppColors.divider),
          ),
        ),
        title: Text(
          '${l10n.bodyRegionName(item.bodyRegion.id)} · Type ${item.fitzpatrickRoman}',
        ),
        subtitle: Text(
          uploaded ? l10n.statusUploaded : l10n.statusQueued,
          style: TextStyle(
            color: uploaded ? AppColors.treatLocally : AppColors.monitor,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          uploaded ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
          color: uploaded ? AppColors.treatLocally : AppColors.monitor,
        ),
      ),
    );
  }
}
