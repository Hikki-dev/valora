import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
      ref.read(authControllerProvider.notifier).signUpWithEmail(email, password);
    } else {
      ref.read(authControllerProvider.notifier).signInWithEmail(email, password);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final containerBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Valora', 
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: 2,
                )
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0.0, 0.5), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _isLogin ? 'Welcome back! Sign in to continue.' : 'Create an account to track your collection.', 
                  key: ValueKey<bool>(_isLogin),
                  style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                decoration: BoxDecoration(
                  color: containerBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
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
                            labelStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: textColor.withValues(alpha: 0.5),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            )
                          ),
                          obscureText: _obscurePassword,
                          onSubmitted: (_) => _submit(),
                          textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
                        ),
                        if (!_isLogin) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _confirmPasswordController,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              labelStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
                            ),
                            obscureText: _obscurePassword,
                            onSubmitted: (_) => _submit(),
                            textInputAction: TextInputAction.done,
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (authState.isLoading)
                          Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
                        else
                          ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Theme.of(context).colorScheme.surface,
                              minimumSize: const Size(double.infinity, 50),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _isLogin ? 'Sign In' : 'Sign Up', 
                                key: ValueKey<bool>(_isLogin),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                             Expanded(child: Divider(color: borderColor)),
                             Padding(
                               padding: const EdgeInsets.symmetric(horizontal: 16),
                               child: Text('OR', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
                             ),
                             Expanded(child: Divider(color: borderColor)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: authState.isLoading ? null : _submitGoogle,
                          icon: const FaIcon(FontAwesomeIcons.google, size: 20),
                          label: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _isLogin ? 'Sign In with Google' : 'Sign Up with Google',
                                key: ValueKey<bool>(_isLogin),
                              ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textColor,
                            side: BorderSide(color: borderColor),
                            minimumSize: const Size(double.infinity, 50),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() {
                            _isLogin = !_isLogin;
                            _validationError = null;
                            if (_isLogin) {
                              _confirmPasswordController.clear();
                            }
                          }),
                          style: TextButton.styleFrom(foregroundColor: Theme.of(context).primaryColor),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _isLogin ? 'Need an account? Sign Up' : 'Have an account? Sign In',
                              key: ValueKey<bool>(_isLogin),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              if (_validationError != null || authState.hasError) ...[
                const SizedBox(height: 24),
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _validationError ?? _getFriendlyError(authState.error.toString()), 
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
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
