import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// A persistent, non-dismissible safety disclaimer banner.
///
/// Rendered in amber with a warning icon. Place it at the top or bottom of
/// screens where the user must remain aware that this is a decision-support
/// aid, not a diagnostic device.
class DisclaimerBanner extends StatelessWidget {
  /// Disclaimer text; defaults to [AppConstants.disclaimer].
  final String text;

  const DisclaimerBanner({super.key, this.text = AppConstants.disclaimer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        border: Border(
          top: BorderSide(color: Colors.amber.shade700, width: 1),
          bottom: BorderSide(color: Colors.amber.shade700, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.amber.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
