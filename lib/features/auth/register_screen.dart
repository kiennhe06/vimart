import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design.dart';
import '../../widgets/sticker_icon.dart';
import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../core/i18n/app_strings.dart';
import '../../widgets/app_busy.dart';
import '../../widgets/app_feedback.dart';
import 'auth_provider.dart';

/// Màn đăng ký tài khoản mới — đồng bộ phong cách grocery.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _submitting = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authProvider.notifier).register(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            fullName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
          );
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
      appBar: AppBar(title: Text(s.register)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72, height: 72,
                    decoration: const BoxDecoration(color: AppColors.brandSoft, shape: BoxShape.circle),
                    child: const StickerIcon('person', size: 40),
                  ),
                ),
                const SizedBox(height: 14),
                Text(s.registerTitle,
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(s.registerSub, textAlign: TextAlign.center, style: TextStyle(color: context.c.textSecondary)),
                const SizedBox(height: 26),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(labelText: s.fullName, prefixIcon: const StickerIcon('person', size: 22)),
                  validator: (v) => (v == null || v.trim().length < 2) ? s.enterName : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: s.email, prefixIcon: const StickerIcon('mail', size: 22)),
                  validator: (v) => (v == null || !v.contains('@')) ? s.emailInvalid : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                      labelText: s.phoneOptional, prefixIcon: const StickerIcon('call', size: 22)),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: s.password,
                    prefixIcon: const StickerIcon('lock', size: 22),
                    suffixIcon: IconButton(
                      icon: AnimatedSwitcher(
                        duration: AppMotion.dur(context, AppMotion.fast),
                        transitionBuilder: (c, a) => ScaleTransition(
                            scale: a, child: FadeTransition(opacity: a, child: c)),
                        child: StickerIcon(
                            _obscure ? 'eye-off' : 'eye',
                            size: 22,
                            key: ValueKey(_obscure)),
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? s.passwordMin6 : null,
                ),
                const SizedBox(height: 26),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: BusySwitch(busy: _submitting, child: Text(s.createAccount)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
