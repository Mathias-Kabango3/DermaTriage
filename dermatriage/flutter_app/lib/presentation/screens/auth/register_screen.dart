import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
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
      const SnackBar(content: Text('Account created. Welcome!')),
    );
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _sectionLabel(context, 'Your name'),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Full name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (String? v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter your name'
                  : null,
            ),
            const SizedBox(height: 20),

            _sectionLabel(context, 'Email'),
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
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@') || !v.contains('.')) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            _sectionLabel(context, 'Where you work'),
            TextFormField(
              controller: _regionController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Region / District',
                prefixIcon: Icon(Icons.map_outlined),
              ),
              validator: (String? v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter your region'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _facilityController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Health facility',
                prefixIcon: Icon(Icons.local_hospital_outlined),
              ),
              validator: (String? v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter your facility'
                  : null,
            ),
            const SizedBox(height: 20),

            _sectionLabel(context, 'Password'),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'At least ${AppConstants.minPasswordLength} '
                    'characters',
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
              controller: _confirmController,
              obscureText: _obscurePassword,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Confirm password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (String? v) => (v != _passwordController.text)
                  ? 'Passwords do not match'
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              'Creating your account needs internet this one time. '
              'After that, you can use the app offline.',
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
              label: Text(_submitting ? 'Creating...' : 'Create Account'),
              onPressed: _submitting ? null : _onRegister,
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('I already have an account'),
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
