// Renders the Home screen's composition to a PNG for visual review.
//
//   flutter test test/golden/home_render_test.dart
//   -> build/home_redesign.png
//
// This mirrors HomeScreen's tree using the same widgets (BrandHeader,
// ActionCard, AppBottomNav) rather than pumping HomeScreen itself: HomeScreen
// watches AuthProvider, whose singleton constructs FirebaseAuth eagerly, and
// the mocked Firebase channel never completes on the host. Layout and styling
// are what this artefact is for, and those live in the widgets below.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:dermatriage/core/theme/app_shadows.dart';
import 'package:dermatriage/core/theme/app_theme.dart';
import 'package:dermatriage/presentation/widgets/common/app_bottom_nav.dart';
import 'package:dermatriage/presentation/widgets/home/action_card.dart';
import 'package:dermatriage/presentation/widgets/home/brand_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// flutter_test ships a placeholder font that paints every glyph as a box.
/// Load the SDK's real Roboto + MaterialIcons so the artefact is readable.
Future<void> _loadRealFonts() async {
  const String fonts =
      '/usr/local/share/flutter/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String path) async =>
      ByteData.sublistView(File(path).readAsBytesSync());

  if (!Directory(fonts).existsSync()) return; // fall back to box glyphs

  await (FontLoader('Roboto')
        ..addFont(read('$fonts/Roboto-Regular.ttf'))
        ..addFont(read('$fonts/Roboto-Medium.ttf'))
        ..addFont(read('$fonts/Roboto-Bold.ttf')))
      .load();
  await (FontLoader('MaterialIcons')
        ..addFont(read('$fonts/MaterialIcons-Regular.otf')))
      .load();
}

/// Mirrors HomeScreen's tree, with the auth-dependent username passed directly.
Widget _home() {
  return Scaffold(
    body: Column(
      children: <Widget>[
        const BrandHeader(username: 'Mathias K.'),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ActionCard.primary(
                    icon: Icons.camera_alt_rounded,
                    label: 'Start New Triage',
                    onTap: () {},
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ActionCard.secondary(
                    icon: Icons.history_rounded,
                    label: 'View History',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
    bottomNavigationBar: const AppBottomNav(current: AppTab.home),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadRealFonts);

  testWidgets('render Home composition', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2020);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[GoRoute(path: '/', builder: (_, __) => _home())],
    );

    final GlobalKey captureKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final RenderRepaintBoundary boundary = captureKey.currentContext!
        .findRenderObject()! as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final File out = File('build/home_redesign.png');
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(bytes!.buffer.asUint8List());
    // ignore: avoid_print
    print('wrote ${out.absolute.path}');
  });
}
