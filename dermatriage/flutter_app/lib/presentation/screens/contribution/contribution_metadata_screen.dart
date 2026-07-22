import 'package:flutter/material.dart';

import '../../../core/constants/body_regions.dart';
import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/contribution/fitz_type_picker.dart';
import 'contribution_camera_screen.dart';

/// First step of the "contribute a healthy-skin photo" flow: pick the body
/// region and Fitzpatrick type, then hand off to the camera.
///
/// Kept entirely separate from [PatientRegistrationScreen]/[CameraScreen] —
/// this flow has no patient, no triage inference, and must not risk
/// regressing the tested triage capture path.
class ContributionMetadataScreen extends StatefulWidget {
  const ContributionMetadataScreen({super.key});

  @override
  State<ContributionMetadataScreen> createState() =>
      _ContributionMetadataScreenState();
}

class _ContributionMetadataScreenState
    extends State<ContributionMetadataScreen> {
  BodyRegion? _bodyRegion;
  int? _fitzType;

  bool get _canContinue => _bodyRegion != null && _fitzType != null;

  void _onContinue() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ContributionCameraScreen(
          fitzpatrickType: _fitzType!,
          bodyRegion: _bodyRegion!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.contributeTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            l10n.contributeIntro,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _sectionLabel(context, l10n.bodyRegionLabel),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BodyRegion.values.map((BodyRegion region) {
              return ChoiceChip(
                label: Text(l10n.bodyRegionName(region.id)),
                selected: _bodyRegion == region,
                onSelected: (_) => setState(() => _bodyRegion = region),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _sectionLabel(context, l10n.skinType),
          FitzTypePicker(
            selectedType: _fitzType,
            onSelected: (int t) => setState(() => _fitzType = t),
          ),
          const SizedBox(height: 8),
          Text(
            _fitzType == null
                ? l10n.skinTypeHint
                : l10n.fitzpatrickDescription(_fitzType!),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: Text(l10n.continueToCapture),
            onPressed: _canContinue ? _onContinue : null,
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
