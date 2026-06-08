import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

/// Compact horizontal row of the six Fitzpatrick skin-tone swatches used to
/// confirm the patient's skin type before capture. The selected type shows a
/// checkmark.
class FitzpatrickSelector extends StatelessWidget {
  /// Currently selected Fitzpatrick type (1–6), or null if unset.
  final int? selectedType;
  final ValueChanged<int> onSelected;

  const FitzpatrickSelector({
    super.key,
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(6, (int i) {
        final int type = i + 1;
        final bool selected = selectedType == type;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () => onSelected(type),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.fitzpatrickColors[i],
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : Colors.white24,
                  width: selected ? 3 : 1,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
