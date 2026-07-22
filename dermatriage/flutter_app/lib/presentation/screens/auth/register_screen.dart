import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

/// Account creation for a new community health worker.
///
/// Registration is online — it needs internet the first time so the account is
/// created in Firebase (and the project owner can see registered CHWs). After
/// that the session is cached and triage works offline.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _regionController = TextEditingController();
  final _facilityController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _regionController.dispose();
    _facilityController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final String? error = await AuthProvider.instance.service.register(
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameController.text,
      region: _regionController.text,
      facility: _facilityController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // Registration signs the CHW in automatically; the router redirect sends
    // them to the home screen once the session updates.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).accountCreated)),
    );
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createAccount)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _sectionLabel(context, l10n.yourNameHint),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: l10n.fullName,
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              validator: (String? v) => (v == null || v.trim().isEmpty)
                  ? l10n.enterName
                  : null,
            ),
            const SizedBox(height: 20),

            _sectionLabel(context, l10n.email),
            TextFormField(
              controller: _emailController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (String? v) {
                if (v == null || v.trim().isEmpty) return l10n.emailRequired;
                if (!v.contains('@') || !v.contains('.')) {
                  return l10n.validEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            _sectionLabel(context, l10n.whereYouWorkHint),
            TextFormField(
              controller: _regionController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.regionDistrict,
                prefixIcon: const Icon(Icons.map_outlined),
              ),
              validator: (String? v) => (v == null || v.trim().isEmpty)
                  ? l10n.enterRegion
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _facilityController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.healthFacility,
                prefixIcon: const Icon(Icons.local_hospital_outlined),
              ),
              validator: (String? v) => (v == null || v.trim().isEmpty)
                  ? l10n.enterFacility
                  : null,
            ),
            const SizedBox(height: 20),

            _sectionLabel(context, l10n.password),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: l10n.minPasswordHint(AppConstants.minPasswordLength),
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
              controller: _confirmController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.confirmPassword,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              validator: (String? v) => (v != _passwordController.text)
                  ? l10n.passwordsNoMatch
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.registerInternetInfo,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              icon: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_add),
              label: Text(_submitting ? l10n.creating : l10n.createAccount),
              onPressed: _submitting ? null : _onRegister,
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: Text(l10n.alreadyHaveAccount),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
