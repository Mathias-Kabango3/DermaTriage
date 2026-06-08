import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// The three triage outcomes the model maps every prediction to.
enum TriageLevel {
  urgentReferral,
  monitor,
  treatLocally,
}

/// Display metadata and CHW guidance for each [TriageLevel].
extension TriageLevelExtension on TriageLevel {
  /// Stable string id used for storage and model/label mapping.
  String get id {
    switch (this) {
      case TriageLevel.urgentReferral:
        return 'URGENT_REFERRAL';
      case TriageLevel.monitor:
        return 'MONITOR';
      case TriageLevel.treatLocally:
        return 'TREAT_LOCALLY';
    }
  }

  /// Short human-readable label for the UI.
  String get displayLabel {
    switch (this) {
      case TriageLevel.urgentReferral:
        return 'Urgent Referral';
      case TriageLevel.monitor:
        return 'Monitor';
      case TriageLevel.treatLocally:
        return 'Treat Locally';
    }
  }

  /// Colour used for chips, banners and result cards.
  Color get color {
    switch (this) {
      case TriageLevel.urgentReferral:
        return AppColors.urgent;
      case TriageLevel.monitor:
        return AppColors.monitor;
      case TriageLevel.treatLocally:
        return AppColors.treatLocally;
    }
  }

  /// Lighter background variant of [color].
  Color get colorLight {
    switch (this) {
      case TriageLevel.urgentReferral:
        return AppColors.urgentLight;
      case TriageLevel.monitor:
        return AppColors.monitorLight;
      case TriageLevel.treatLocally:
        return AppColors.treatLocallyLight;
    }
  }

  /// Action guidance for the community health worker.
  String get instruction {
    switch (this) {
      case TriageLevel.urgentReferral:
        return 'Refer the patient to a clinic or hospital as soon as possible. '
            'Do not delay — this may be a serious condition.';
      case TriageLevel.monitor:
        return 'Advise the patient and arrange follow-up. Refer if the '
            'condition worsens, spreads, or does not improve.';
      case TriageLevel.treatLocally:
        return 'This can usually be managed at the community level following '
            'local protocols. Refer if there is no improvement.';
    }
  }

  /// Build a [TriageLevel] from its stored [id]; throws on unknown values.
  static TriageLevel fromId(String id) {
    switch (id) {
      case 'URGENT_REFERRAL':
        return TriageLevel.urgentReferral;
      case 'MONITOR':
        return TriageLevel.monitor;
      case 'TREAT_LOCALLY':
        return TriageLevel.treatLocally;
      default:
        throw ArgumentError('Unknown triage level id: $id');
    }
  }
}
