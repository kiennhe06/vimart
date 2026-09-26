import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../core/i18n/app_strings.dart';
import '../../widgets/app_busy.dart';
import '../../widgets/app_feedback.dart';
import 'auth_provider.dart';

/// Màn đăng nhập — phong cách grocery: logo trong vòng tròn mềm, ô nhập bo tròn.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _submitting = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authProvider.notifier).login(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo trong vòng tròn mềm
                  Center(
                    child: Container(
                      width: 92, height: 92,
                      decoration: const BoxDecoration(color: AppColors.brandSoft, shape: BoxShape.circle),
                      child: const Icon(Icons.storefront_rounded, size: 46, color: AppColors.brand),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('ViMart',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.brand, fontSize: 30, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(s.tagline,
                      textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: s.email, prefixIcon: const Icon(Icons.email_outlined)),
                    validator: (v) => (v == null || !v.contains('@')) ? s.emailInvalid : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: s.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: AnimatedSwitcher(
                          duration: AppMotion.dur(context, AppMotion.fast),
                          transitionBuilder: (c, a) => ScaleTransition(
                              scale: a, child: FadeTransition(opacity: a, child: c)),
                          child: Icon(
                              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              key: ValueKey(_obscure)),
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? s.enterPassword : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: BusySwitch(busy: _submitting, child: Text(s.login)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.noAccount),
                      TextButton(onPressed: () => context.push('/register'), child: Text(s.signUpNow)),
                    ],
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/'),
                      child: Text(s.browseGuest),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(18)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.demoAccounts,
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brandDark)),
                        const SizedBox(height: 6),
                        Text(s.demoBuyer),
                        Text(s.demoSeller),
                        Text(s.demoAdmin),
                      ],
                    ),
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
