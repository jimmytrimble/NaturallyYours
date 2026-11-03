import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_client.dart';
import '../services/auth_service.dart';
import '../theme.dart';

/// Sign in / create account. Pops itself on success.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _registerMode = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    try {
      if (_registerMode) {
        await auth.signup(_name.text, _email.text, _password.text);
      } else {
        await auth.login(_email.text, _password.text);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e is ApiException ? e.message : e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_registerMode ? 'Create Account' : 'Sign In')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 8),
          const Center(
            child: Text('Naturally Yours',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 24),
          if (_registerMode)
            _field(_name, 'Full name', TextInputType.name),
          _field(_email, 'Email', TextInputType.emailAddress),
          _field(_password, 'Password', TextInputType.visiblePassword, obscure: true),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: NYTheme.pink,
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_registerMode ? 'Create Account' : 'Log In'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _busy ? null : () => setState(() => _registerMode = !_registerMode),
            child: Text(_registerMode
                ? 'Already have an account? Sign in'
                : "Don't have an account? Sign up"),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, TextInputType type, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        obscureText: obscure,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization:
            type == TextInputType.name ? TextCapitalization.words : TextCapitalization.none,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
