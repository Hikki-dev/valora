import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../controllers/auth_controller.dart';

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
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    // Liquid Glass Aesthetics
    final containerBg = isDark
        ? Colors.black.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.85);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    // Heroic responsive assets
    final backgroundImage =
        isDesktop ? 'assets/icon/batman.jpg' : 'assets/icon/Splash.webp';

    return Scaffold(
      backgroundColor: Colors.black, // Dark foundation for the image stack
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Cinematic Background Layer
          Image.asset(
            backgroundImage,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ).animate().fadeIn(duration: 800.ms).scale(
              begin: const Offset(1.1, 1.1),
              end: const Offset(1.0, 1.0),
              duration: 2.seconds,
              curve: Curves.easeOut),

          // 2. Artistic Gradient Overlay (Ensures readability & premium feel)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.9),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // 3. Login Content Layer
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Valora',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Colors
                            .white, // Locked to white for high contrast on image
                        letterSpacing: -2.0,
                      ),
                    ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _isLogin
                            ? 'COLLECTION VALUATION ENGINE'
                            : 'JOIN THE ARCHIVE',
                        key: ValueKey<bool>(_isLogin),
                        style: TextStyle(
                            color: Colors.amber.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Glassmorphic Login Container
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: containerBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          alignment: Alignment.topCenter,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _emailController,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: TextStyle(
                                      color: textColor.withValues(alpha: 0.5)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: borderColor)),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: theme.primaryColor, width: 2)),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: TextStyle(
                                        color:
                                            textColor.withValues(alpha: 0.5)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide:
                                            BorderSide(color: borderColor)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: theme.primaryColor,
                                            width: 2)),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: textColor.withValues(alpha: 0.5),
                                      ),
                                      onPressed: () => setState(() =>
                                          _obscurePassword = !_obscurePassword),
                                    )),
                                obscureText: _obscurePassword,
                                onSubmitted: (_) => _submit(),
                                textInputAction: _isLogin
                                    ? TextInputAction.done
                                    : TextInputAction.next,
                              ),
                              if (!_isLogin) ...[
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _confirmPasswordController,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    labelStyle: TextStyle(
                                        color:
                                            textColor.withValues(alpha: 0.5)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide:
                                            BorderSide(color: borderColor)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: theme.primaryColor,
                                            width: 2)),
                                  ),
                                  obscureText: _obscurePassword,
                                  onSubmitted: (_) => _submit(),
                                  textInputAction: TextInputAction.done,
                                ),
                              ],
                              const SizedBox(height: 32),
                              if (authState.isLoading)
                                Shimmer.fromColors(
                                  baseColor: textColor.withValues(alpha: 0.1),
                                  highlightColor:
                                      textColor.withValues(alpha: 0.2),
                                  child: Container(
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                )
                              else
                                ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor: theme.colorScheme.surface,
                                    minimumSize:
                                        const Size(double.infinity, 54),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    elevation: 0,
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Text(
                                        _isLogin ? 'Sign In' : 'Sign Up',
                                        key: ValueKey<bool>(_isLogin),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16)),
                                  ),
                                ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(child: Divider(color: borderColor)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text('OR',
                                        style: TextStyle(
                                            color: textColor.withValues(
                                                alpha: 0.5),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Expanded(child: Divider(color: borderColor)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              OutlinedButton.icon(
                                onPressed:
                                    authState.isLoading ? null : _submitGoogle,
                                icon: const FaIcon(FontAwesomeIcons.google,
                                    size: 20),
                                label: Text(_isLogin
                                    ? 'Continue with Google'
                                    : 'Join with Google'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textColor,
                                  side: BorderSide(
                                      color: borderColor, width: 1.5),
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms).scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.0, 1.0)),

                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() {
                        _isLogin = !_isLogin;
                        _validationError = null;
                        if (_isLogin) {
                          _confirmPasswordController.clear();
                        }
                      }),
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.white70),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _isLogin
                              ? 'Don\'t have an account? Create one'
                              : 'Already have an account? Sign In',
                          key: ValueKey<bool>(_isLogin),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          if (_validationError != null || authState.hasError)
            Positioned(
              bottom: 48,
              left: 24,
              right: 24,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20)
                      ]),
                  child: Text(
                    _validationError ??
                        _getFriendlyError(authState.error.toString()),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutBack),
        ],
      ),
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
