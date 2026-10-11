import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _errorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'البريد أو كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'هذا البريد مسجل مسبقًا';
      case 'weak-password':
        return 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقًا';
      default:
        return 'حدث خطأ: ${e.message ?? e.code}';
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _submit({required bool signUp}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final auth = FirebaseAuth.instance;
      if (signUp) {
        await auth.createUserWithEmailAndPassword(
            email: email, password: password);
      } else {
        await auth.signInWithEmailAndPassword(email: email, password: password);
      }
      // التنقل يتم تلقائيًا من AuthGate بعد نجاح الدخول
    } on FirebaseAuthException catch (e) {
      _showMessage(_errorMessage(e));
    } catch (_) {
      _showMessage('حدث خطأ غير متوقع');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    decoration:
                        const InputDecoration(labelText: 'البريد الإلكتروني'),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'يرجى إدخال بريد إلكتروني صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'كلمة المرور 6 أحرف على الأقل'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : () => _submit(signUp: false),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('تسجيل الدخول'),
                    ),
                  ),
                  TextButton(
                    onPressed: _loading ? null : () => _submit(signUp: true),
                    child: const Text('إنشاء حساب جديد'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
