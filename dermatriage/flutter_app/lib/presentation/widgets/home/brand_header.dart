import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../common/app_logo.dart';

/// Teal gradient header carrying the logo, app name and tagline.
///
/// Used instead of an [AppBar] so the brand colour can carry a gradient behind
/// the branding. A tappable account icon (top-right) reveals the signed-in
/// username and a log-out action.
class BrandHeader extends StatelessWidget {
  /// The signed-in CHW's display name, shown in the account menu.
  final String? username;

  const BrandHeader({super.key, this.username});

  Future<void> _confirmLogout(BuildContext context) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l10n.logoutTitle),
        content: Text(l10n.logoutBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // Router redirect returns to /login once the session clears.
      AuthProvider.instance.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Square bottom edge (no rounded corners).
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primaryLight, AppColors.primary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: AppSpacing.md),
                  const AppLogo(size: 88),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppLocalizations.of(context).homeTagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Account icon: tap to see the username and log out.
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: _AccountMenu(
                username: username,
                onLogout: () => _confirmLogout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The top-right account button and its pop-up menu.
class _AccountMenu extends StatelessWidget {
  final String? username;
  final VoidCallback onLogout;

  const _AccountMenu({required this.username, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      tooltip: l10n.account,
      icon: const Icon(Icons.account_circle, color: Colors.white, size: 30),
      offset: const Offset(0, 44),
      onSelected: (String value) {
        if (value == 'logout') onLogout();
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: <Widget>[
              const Icon(Icons.person_outline,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  username != null ? l10n.signedInAs(username!) : l10n.account,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: <Widget>[
              const Icon(Icons.logout, size: 20, color: AppColors.urgent),
              const SizedBox(width: 10),
              Text(l10n.logout,
                  style: const TextStyle(color: AppColors.urgent)),
            ],
          ),
        ),
      ],
    );
  }
}
