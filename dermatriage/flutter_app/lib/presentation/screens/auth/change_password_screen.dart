import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';

/// Lets a logged-in CHW change their password (they know the current one).
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final String? username = AuthProvider.instance.currentUsername;
    if (username == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not signed in.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final String? error = await AuthProvider.instance.service.changePassword(
      username,
      _oldController.text,
      _newController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your password has been changed.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _oldController,
              obscureText: _obscure,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Current password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (String? v) => (v == null || v.isEmpty)
                  ? 'Please enter your current password'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newController,
              obscureText: _obscure,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'New password',
                hintText:
                    'At least ${AppConstants.minPasswordLength} characters',
                prefixIcon: Icon(Icons.lock_reset),
              ),
              validator: (String? v) {
                if (v == null || v.isEmpty) return 'Please enter a new password';
                if (v.length < AppConstants.minPasswordLength) {
                  return 'Use at least ${AppConstants.minPasswordLength} '
                      'characters';
                }
                if (v == _oldController.text) {
                  return 'New password must be different';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscure,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Confirm new password',
                prefixIcon: Icon(Icons.lock_reset),
              ),
              validator: (String? v) => (v != _newController.text)
                  ? 'Passwords do not match'
                  : null,
            ),
            const SizedBox(height: 28),
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
                  : const Icon(Icons.check),
              label: Text(_submitting ? 'Saving...' : 'Save New Password'),
              onPressed: _submitting ? null : _onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
