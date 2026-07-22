import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

/// Fitzpatrick type picker for plain (light) backgrounds — used on the
/// contribution metadata screen. Visually distinct from
/// `widgets/camera/fitzpatrick_selector.dart`, which is styled for the dark
/// camera-preview overlay and would be invisible here (white borders on a
/// white background).
class FitzTypePicker extends StatelessWidget {
  final int? selectedType;
  final ValueChanged<int> onSelected;

  const FitzTypePicker({
    super.key,
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List<Widget>.generate(6, (int i) {
        final int type = i + 1;
        final bool selected = selectedType == type;
        return GestureDetector(
          onTap: () => onSelected(type),
          child: Column(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.fitzpatrickColors[i],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.divider,
                    width: selected ? 3 : 1,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 20, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 4),
              Text('$type', style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }),
    );
  }
}
