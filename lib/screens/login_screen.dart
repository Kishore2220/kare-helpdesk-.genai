import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firebase_config.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _regNo = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();

  bool _isRegister = false;
  bool _hidePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _regNo.dispose();
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final reg = _regNo.text.trim().toUpperCase();
    final email = AppConfig.emailFromRegNo(reg);

    try {
      final auth = FirebaseAuth.instance;
      if (_isRegister) {
        final cred = await auth.createUserWithEmailAndPassword(
            email: email, password: _password.text);
        await cred.user!.updateDisplayName(_name.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'register_number': reg,
          'full_name': _name.text.trim(),
          'role': 'student',
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        await auth.signInWithEmailAndPassword(email: email, password: _password.text);
      }
      // The auth stream in main.dart switches to the home screen.
    } on FirebaseAuthException catch (e) {
      _toast(_friendly(e.code));
    } on FirebaseException catch (e) {
      _toast('Could not save your profile (${e.code}). Check the Firestore rules.');
    } catch (_) {
      _toast('Something went wrong. Check your internet and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendly(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-email':
        return 'Wrong register number or password.';
      case 'email-already-in-use':
        return 'This register number is already registered. Please log in.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled in Firebase yet.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a minute and try again.';
      default:
        return 'Login failed ($code).';
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ---- campus photo header ----
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 310,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/images/campus.png', fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        KareColors.darkBlue.withOpacity(0.55),
                        KareColors.darkBlue.withOpacity(0.88),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---- logo + title + card ----
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset('assets/images/kare_logo.png', height: 84, width: 84),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'KARE HELP DESK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Kalasalingam Academy of Research and Education',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12.5),
                      ),
                      const SizedBox(height: 40),
                      _card(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('Login')),
                ButtonSegment(value: true, label: Text('Register')),
              ],
              selected: {_isRegister},
              onSelectionChanged: (s) => setState(() => _isRegister = s.first),
            ),
            const SizedBox(height: 22),
            Text(
              _isRegister ? 'Create your account' : 'Welcome back',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              _isRegister
                  ? 'Use your university register number.'
                  : 'Sign in with your register number.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _regNo,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Register Number',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return 'Enter your register number';
                if (!RegExp(r'^[A-Za-z0-9]{6,15}$').hasMatch(t)) {
                  return 'Register number looks invalid';
                }
                return null;
              },
            ),
            if (_isRegister) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v ?? '').trim().length < 3 ? 'Enter your full name' : null,
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _hidePassword,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                ),
              ),
              validator: (v) =>
                  (v ?? '').length < 6 ? 'Minimum 6 characters' : null,
            ),
            if (!_isRegister)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _toast('Please contact Student Affairs / IT Support to reset your password.'),
                  child: const Text('Forgot password?'),
                ),
              )
            else
              const SizedBox(height: 14),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : Text(_isRegister ? 'CREATE ACCOUNT' : 'LOGIN'),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '© KARE · Krishnankoil, Tamil Nadu',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
