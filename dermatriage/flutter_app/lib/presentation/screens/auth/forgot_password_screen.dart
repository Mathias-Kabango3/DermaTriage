import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

/// Password recovery: enter your email and Firebase sends a reset link.
///
/// This needs internet (it sends an email). Once the link is used, the CHW can
/// sign in again with the new password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSendReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    final String? error = await AuthProvider.instance.service
        .sendPasswordReset(_emailController.text);
    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).forgotTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (_sent) _buildSent(context) else _buildForm(context),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionLabel(context, l10n.enterYourEmail),
          Text(
            l10n.forgotIntro,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.email,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (String? v) => (v == null || v.trim().isEmpty)
                ? l10n.enterEmail
                : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.send),
            label: Text(_busy ? l10n.sending : l10n.sendResetLink),
            onPressed: _busy ? null : _onSendReset,
          ),
        ],
      ),
    );
  }

  Widget _buildSent(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 24),
        const Icon(Icons.mark_email_read_outlined,
            size: 64, color: AppColors.primary),
        const SizedBox(height: 16),
        Text(
          l10n.checkEmail,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.resetSent(_emailController.text.trim()),
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: Text(l10n.backToLogin),
          onPressed: () => context.go('/login'),
        ),
      ],
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
