import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_shadows.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/home/action_card.dart';
import '../../widgets/home/brand_header.dart';

/// Landing screen: branding and primary actions.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? username = context.watch<AuthProvider>().displayName;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Column(
        children: <Widget>[
          BrandHeader(username: username),
          // Centred in the space between header and tab bar so two actions
          // read as a balanced screen rather than a top-aligned stub; still
          // scrollable on short displays.
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          ActionCard.primary(
                            icon: Icons.camera_alt_rounded,
                            label: l10n.homeStartTriage,
                            onTap: () => context.push('/patient/register'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ActionCard.secondary(
                            icon: Icons.history_rounded,
                            label: l10n.homeViewHistory,
                            onTap: () => context.go('/history'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ActionCard.secondary(
                            icon: Icons.volunteer_activism_rounded,
                            label: l10n.contributeCardLabel,
                            onTap: () => context.push('/contribute'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(current: AppTab.home),
    );
  }
}
