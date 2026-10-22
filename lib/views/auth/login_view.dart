import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../core/tokens.dart';
import '../../widgets/comic.dart';
import '../../widgets/comic_loader.dart';
import '../../widgets/google_logo.dart';
import '../../widgets/v_form.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;
  String? _validationError;

  void _submit() {
    setState(() => _validationError = null);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _validationError = 'Please fill out all fields.');
      return;
    }

    if (!_isLogin) {
      final confirmPassword = _confirmPasswordController.text;
      if (password != confirmPassword) {
        setState(() => _validationError = 'Passwords do not match');
        return;
      }
      ref
          .read(authControllerProvider.notifier)
          .signUpWithEmail(email, password);
    } else {
      ref
          .read(authControllerProvider.notifier)
          .signInWithEmail(email, password);
    }
  }

  void _submitGoogle() {
    setState(() => _validationError = null);
    ref.read(authControllerProvider.notifier).signInWithGoogle();
  }

  String _getFriendlyError(String errorString) {
    if (errorString.contains('message:')) {
      final start = errorString.indexOf('message:') + 8;
      final end = errorString.indexOf(', statusCode');
      if (end != -1 && end > start) {
        return errorString.substring(start, end).trim();
      }
    }
    if (errorString.contains('Invalid login credentials')) {
      return 'The email or password you entered is incorrect.';
    }
    if (errorString.contains('User already registered')) {
      return 'An account with this email already exists.';
    }
    return errorString.replaceAll('AuthApiException', 'Error');
  }

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final error = _validationError ??
        (authState.hasError
            ? _getFriendlyError(authState.error.toString())
            : null);

    final form = _form(context, t, authState.isLoading, isDark, error);

    return Scaffold(
      backgroundColor: t.bg,
      body: isDesktop
          ? Row(children: [
              Expanded(flex: 5, child: _Hero(t: t)),
              Expanded(
                flex: 4,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: form),
                  ),
                ),
              ),
            ])
          : Stack(fit: StackFit.expand, children: [
              Image.asset('assets/art/hero_portrait.jpg',
                  fit: BoxFit.cover, alignment: Alignment.topCenter),
              ColoredBox(color: t.bg.withValues(alpha: 0.88)),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MobileBrand(t: t),
                      const SizedBox(height: 28),
                      form,
                    ],
                  ),
                ),
              ),
            ]),
    );
  }

  Widget _form(BuildContext context, VTokens t, bool loading, bool isDark,
      String? error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_isLogin ? 'WELCOME BACK' : 'NEW HERE',
            style: VText.label(12, t.muted)),
        const SizedBox(height: 4),
        Text(_isLogin ? 'Sign in' : 'Create your account',
            style: VText.display(28, t.text)),
        const SizedBox(height: 6),
        Text(
            _isLogin
                ? 'See what your game collection is worth.'
                : 'Track what your games are worth, free.',
            style: VText.body(14, t.muted, weight: FontWeight.w500)),
        const SizedBox(height: 22),
        PressableBox(
          onTap: loading ? null : _submitGoogle,
          color: isDark ? const Color(0xFF131314) : Colors.white,
          semanticLabel: 'Continue with Google',
          minHeight: 52,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const GoogleLogo(size: 20),
            const SizedBox(width: 12),
            Text(_isLogin ? 'Continue with Google' : 'Join with Google',
                style: VText.body(15,
                    isDark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F),
                    weight: FontWeight.w900)),
          ]),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: Container(height: 2, color: t.soft)),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or with email', style: VText.body(12, t.muted))),
          Expanded(child: Container(height: 2, color: t.soft)),
        ]),
        const SizedBox(height: 18),
        AutofillGroup(
          child: Column(children: [
            VField(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              hint: 'you@example.com',
            ),
            const SizedBox(height: 16),
            VField(
              label: 'Password',
              controller: _passwordController,
              hint: _isLogin ? '' : 'At least 8 characters',
              obscure: _obscurePassword,
              onSubmitted: (_) => _isLogin ? _submit() : null,
              trailing: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: t.muted),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            if (!_isLogin) ...[
              const SizedBox(height: 16),
              VField(
                label: 'Confirm password',
                controller: _confirmPasswordController,
                obscure: _obscurePassword,
                onSubmitted: (_) => _submit(),
              ),
            ],
          ]),
        ),
        if (error != null) ...[
          const SizedBox(height: 14),
          Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: t.lossBg, border: Border.all(color: kInk, width: 2)),
              child: Text(error,
                  style: VText.body(13, t.lossInk, weight: FontWeight.w700)),
            ),
          ),
        ],
        const SizedBox(height: 20),
        PressableBox(
          onTap: loading ? null : _submit,
          color: t.money,
          semanticLabel: _isLogin ? 'Sign in' : 'Sign up',
          minHeight: 52,
          child: loading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: t.onMoney))
              : Text(_isLogin ? 'Sign in' : 'Create account',
                  style: VText.body(15, t.onMoney, weight: FontWeight.w900)),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() {
            _isLogin = !_isLogin;
            _validationError = null;
            _confirmPasswordController.clear();
          }),
          style: TextButton.styleFrom(
              minimumSize: const Size(44, 44), foregroundColor: t.text),
          child: Text(
              _isLogin
                  ? 'New here? Create an account'
                  : 'Already have an account? Sign in',
              style: VText.body(14, t.text, weight: FontWeight.w900)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

/// Original comic-panel hero: halftone, speed lines, the V mark and the animated fight strip.
class _Hero extends StatelessWidget {
  const _Hero({required this.t});
  final VTokens t;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: t.money, border: Border.all(color: kInk, width: 3)),
              child: Text('V', style: VText.display(32, t.onMoney)),
            ),
            const SizedBox(width: 12),
            Text('Valora', style: VText.display(40, t.text)),
          ],
        ),
        const SizedBox(height: 28),
        const ComicFightStrip(width: 420),
        ...[
          const SizedBox(height: 28),
          Text('Know what your game collection is worth.',
              style: VText.body(18, t.text, weight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Real market prices. No guesses.',
              style: VText.body(14, t.muted, weight: FontWeight.w500)),
        ],
      ],
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/art/hero_landscape.jpg', fit: BoxFit.cover),
        ColoredBox(color: t.surface2.withValues(alpha: 0.82)),
        CustomPaint(
            painter:
                RaysPainter(color: t.rays, origin: const Offset(0.5, 0.5))),
        CustomPaint(painter: HalftonePainter(color: t.dots, spacing: 9)),
        Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 3, color: t.line)),
        Center(child: content),
      ],
    );
  }
}

/// Phone header: a big tilted V block, an outlined yellow wordmark and a one-line promise.
class _MobileBrand extends StatelessWidget {
  const _MobileBrand({required this.t});
  final VTokens t;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Valora. Know what your game collection is worth.',
      child: ExcludeSemantics(
        child: Column(
          children: [
            Transform.rotate(
              angle: -0.1,
              child: SizedBox(
                width: 96,
                height: 96,
                child: Stack(children: [
                  Positioned.fill(
                    child: Transform.translate(
                      offset: const Offset(8, 8),
                      child: Container(
                          decoration: BoxDecoration(
                              color: t.money,
                              border: Border.all(color: kInk, width: 3))),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: kInk,
                          border: Border.all(color: kInk, width: 4)),
                      child: Text('V', style: VText.display(66, t.money)),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedText('VALORA', size: 54, fill: t.money, strokeWidth: 8),
            const SizedBox(height: 10),
            HardBox(
              color: t.surface,
              borderWidth: 2,
              shadowOffset: 3,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text('KNOW WHAT YOUR GAMES ARE WORTH',
                  style: VText.label(11, t.text, spacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}
