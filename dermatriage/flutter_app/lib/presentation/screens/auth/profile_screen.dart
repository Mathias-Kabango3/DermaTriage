import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../providers/auth_provider.dart';

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
    _snack(error ?? 'Your details have been saved.');
  }

  Future<void> _saveEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _savingEmail = true);
    final String? error =
        await AuthProvider.instance.service.updateEmail(_emailController.text);
    if (!mounted) return;
    setState(() => _savingEmail = false);
    _snack(error ??
        'We sent a confirmation link to your new email. '
            'Your email changes once you open it.');
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
    _snack(error ?? 'Your password has been changed.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(
                  'Account changes need internet. Triage works offline.',
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
              ],
            ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return _Card(
      title: 'Your details',
      child: Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Display name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (String? v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter your name'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _regionController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Region / District',
                prefixIcon: Icon(Icons.map_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _facilityController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Health facility',
                prefixIcon: Icon(Icons.local_hospital_outlined),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: _savingProfile
                  ? _spinner()
                  : const Icon(Icons.save_outlined),
              label: Text(_savingProfile ? 'Saving...' : 'Save Details'),
              onPressed: _savingProfile ? null : _saveProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailCard(BuildContext context) {
    return _Card(
      title: 'Email',
      child: Form(
        key: _emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (String? v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@') || !v.contains('.')) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon:
                  _savingEmail ? _spinner() : const Icon(Icons.email_outlined),
              label: Text(_savingEmail ? 'Sending...' : 'Update Email'),
              onPressed: _savingEmail ? null : _saveEmail,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard(BuildContext context) {
    return _Card(
      title: 'Change password',
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
                labelText: 'New password',
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
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < AppConstants.minPasswordLength) {
                  return 'Use at least ${AppConstants.minPasswordLength} '
                      'characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Confirm new password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (String? v) => (v != _newPasswordController.text)
                  ? 'Passwords do not match'
                  : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: _savingPassword
                  ? _spinner()
                  : const Icon(Icons.lock_reset),
              label:
                  Text(_savingPassword ? 'Saving...' : 'Change Password'),
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
