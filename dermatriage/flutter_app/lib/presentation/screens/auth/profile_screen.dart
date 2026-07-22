import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_bottom_nav.dart';

/// Lets a signed-in CHW manage their account: display name, region, facility,
/// email and password.
///
/// All changes here are **online** (they update the CHW's account and need
/// internet). Triage itself never needs this screen or the network.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _regionController = TextEditingController();
  final _facilityController = TextEditingController();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = true;
  bool _savingProfile = false;
  bool _savingEmail = false;
  bool _savingPassword = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    _facilityController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final auth = AuthProvider.instance;
    _nameController.text = auth.user?.displayName ?? '';
    _emailController.text = auth.email ?? '';
    final Map<String, dynamic> profile = await auth.service.loadProfile();
    if (!mounted) return;
    setState(() {
      _regionController.text = (profile['region'] as String?) ?? '';
      _facilityController.text = (profile['facility'] as String?) ?? '';
      _loading = false;
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _savingProfile = true);
    final String? error = await AuthProvider.instance.service.updateProfile(
      name: _nameController.text,
      region: _regionController.text,
      facility: _facilityController.text,
    );
    if (!mounted) return;
    setState(() => _savingProfile = false);
    _snack(error ?? AppLocalizations.of(context).detailsSaved);
  }

  Future<void> _saveEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _savingEmail = true);
    final String? error =
        await AuthProvider.instance.service.updateEmail(_emailController.text);
    if (!mounted) return;
    setState(() => _savingEmail = false);
    _snack(error ?? AppLocalizations.of(context).emailConfirmSent);
  }

  Future<void> _savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _savingPassword = true);
    final String? error = await AuthProvider.instance.service
        .updatePassword(_newPasswordController.text);
    if (!mounted) return;
    setState(() => _savingPassword = false);
    if (error == null) {
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
    _snack(error ?? AppLocalizations.of(context).passwordChanged);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(
                  l10n.profileOnlineNote,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                _buildProfileCard(context),
                const SizedBox(height: 16),
                _buildEmailCard(context),
                const SizedBox(height: 16),
                _buildPasswordCard(context),
                const SizedBox(height: 16),
                _buildAccountCard(context),
              ],
            ),
      bottomNavigationBar: const AppBottomNav(current: AppTab.profile),
    );
  }

  /// Settings and Log out, moved here from the old home-screen account menu
  /// when the header icons were replaced by the bottom tab bar.
  Widget _buildAccountCard(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return _Card(
      title: l10n.account,
      child: Column(
        children: <Widget>[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.volunteer_activism_outlined,
                color: AppColors.textSecondary),
            title: Text(l10n.viewMyContributions),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
            onTap: () => context.push('/contributions'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.settings_rounded,
                color: AppColors.textSecondary),
            title: Text(l10n.settings),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
            onTap: () => context.push('/settings'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout_rounded, color: AppColors.urgent),
            title: Text(l10n.logout,
                style: const TextStyle(color: AppColors.urgent)),
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

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

  Widget _buildProfileCard(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return _Card(
      title: l10n.yourDetails,
      child: Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.displayName,
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              validator: (String? v) => (v == null || v.trim().isEmpty)
                  ? l10n.enterName
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _regionController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.regionDistrict,
                prefixIcon: const Icon(Icons.map_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _facilityController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.healthFacility,
                prefixIcon: const Icon(Icons.local_hospital_outlined),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: _savingProfile
                  ? _spinner()
                  : const Icon(Icons.save_outlined),
              label: Text(_savingProfile ? l10n.saving : l10n.saveDetails),
              onPressed: _savingProfile ? null : _saveProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailCard(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return _Card(
      title: l10n.email,
      child: Form(
        key: _emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.email,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (String? v) {
                if (v == null || v.trim().isEmpty) return l10n.emailRequired;
                if (!v.contains('@') || !v.contains('.')) {
                  return l10n.validEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon:
                  _savingEmail ? _spinner() : const Icon(Icons.email_outlined),
              label: Text(_savingEmail ? l10n.sending : l10n.updateEmail),
              onPressed: _savingEmail ? null : _saveEmail,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return _Card(
      title: l10n.changePasswordTitle,
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.newPassword,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (String? v) {
                if (v == null || v.isEmpty) return l10n.passwordRequired;
                if (v.length < AppConstants.minPasswordLength) {
                  return l10n.minPasswordHint(AppConstants.minPasswordLength);
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.confirmNewPassword,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              validator: (String? v) => (v != _newPasswordController.text)
                  ? l10n.passwordsNoMatch
                  : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: _savingPassword
                  ? _spinner()
                  : const Icon(Icons.lock_reset),
              label:
                  Text(_savingPassword ? l10n.saving : l10n.changePasswordBtn),
              onPressed: _savingPassword ? null : _savePassword,
            ),
          ],
        ),
      ),
    );
  }

  Widget _spinner() => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
}

/// A titled card wrapper, matching the app's section styling.
class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
