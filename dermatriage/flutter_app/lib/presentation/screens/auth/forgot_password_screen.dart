import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../providers/auth_provider.dart';

/// Offline "forgot password" recovery:
/// 1. enter username → app looks up the stored security question
/// 2. answer the question and set a new password
///
/// There is no email/server — the security question is the recovery path.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _usernameFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _answerController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _securityQuestion; // non-null once the username is confirmed
  bool _obscurePassword = true;
  bool _busy = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _answerController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onFindAccount() async {
    if (!_usernameFormKey.currentState!.validate()) return;

    setState(() => _busy = true);
    final String? question = await AuthProvider.instance.service
        .getSecurityQuestion(_usernameController.text);
    if (!mounted) return;
    setState(() => _busy = false);

    if (question == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No account found with that username.')),
      );
      return;
    }
    setState(() => _securityQuestion = question);
  }

  Future<void> _onResetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    setState(() => _busy = true);
    final String? error = await AuthProvider.instance.service
        .resetPasswordWithSecurityAnswer(
      _usernameController.text,
      _answerController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated. Please log in.')),
    );
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (_securityQuestion == null)
            _buildUsernameStep(context)
          else
            _buildResetStep(context),
        ],
      ),
    );
  }

  Widget _buildUsernameStep(BuildContext context) {
    return Form(
      key: _usernameFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionLabel(context, 'Enter your username'),
          Text(
            'We will show your security question so you can reset your '
            'password — all on this device.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (String? v) => (v == null || v.trim().isEmpty)
                ? 'Please enter your username'
                : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: Text(_busy ? 'Please wait...' : 'Continue'),
            onPressed: _busy ? null : _onFindAccount,
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep(BuildContext context) {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionLabel(context, 'Security question'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _securityQuestion!,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _answerController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Your answer',
              prefixIcon: Icon(Icons.question_answer_outlined),
            ),
            validator: (String? v) => (v == null || v.trim().isEmpty)
                ? 'Please enter your answer'
                : null,
          ),
          const SizedBox(height: 20),
          _sectionLabel(context, 'New password'),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText:
                  'At least ${AppConstants.minPasswordLength} characters',
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
              labelText: 'Confirm new password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (String? v) => (v != _passwordController.text)
                ? 'Passwords do not match'
                : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.lock_reset),
            label: Text(_busy ? 'Saving...' : 'Reset Password'),
            onPressed: _busy ? null : _onResetPassword,
          ),
        ],
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
