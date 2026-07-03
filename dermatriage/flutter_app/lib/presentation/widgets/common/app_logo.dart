import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// DermaTriage brand mark: a magnifying glass examining a skin lesion, on the
/// brand teal. Rendered as a crisp, scalable vector so it looks sharp at any
/// size (login header, home screen, etc.).
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: size, height: size);
  }

  static const String _svg = '''
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#00897B"/>
      <stop offset="1" stop-color="#00695C"/>
    </linearGradient>
  </defs>
  <!-- brand disc -->
  <circle cx="50" cy="50" r="50" fill="url(#bg)"/>
  <!-- lens glass -->
  <circle cx="43" cy="43" r="21" fill="#FFFFFF" fill-opacity="0.12"/>
  <!-- lesion + satellite spot being examined -->
  <circle cx="43" cy="44" r="7.5" fill="#FF8F00"/>
  <circle cx="52" cy="36" r="3.2" fill="#FFB74D"/>
  <!-- magnifier ring -->
  <circle cx="43" cy="43" r="21" fill="none" stroke="#FFFFFF" stroke-width="6"/>
  <!-- handle -->
  <line x1="59" y1="59" x2="75" y2="75" stroke="#FFFFFF" stroke-width="9" stroke-linecap="round"/>
</svg>
''';
}
