import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onAuthChanged;
  final Function(Locale) onLanguageChange;

  const LoginScreen({super.key, this.onAuthChanged, required this.onLanguageChange});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  String _translateErrorMessage(String message, AppLocalizations l10n) {
    // Map common error messages from backend to localized versions
    switch (message.toLowerCase()) {
      case 'invalid credentials':
        return l10n.invalidCredentials;
      case 'user not found':
        return l10n.userNotFound;
      case 'account is deactivated':
        return l10n.accountDeactivated;
      case 'validation error':
        return l10n.validationError;
      case 'server error':
        return l10n.serverError;
      default:
        // Handle network errors
        if (message.startsWith('Network error:')) {
          return l10n.networkError;
        }
        // If no translation found, return the original message
        return message;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        if (result['success']) {
          widget.onAuthChanged?.call();
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_translateErrorMessage(result['message'], AppLocalizations.of(context)!)),
              backgroundColor: const Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: () {
              final currentLocale = Localizations.localeOf(context);
              final newLocale = currentLocale.languageCode == 'en' 
                ? const Locale('he', '') 
                : const Locale('en', '');
              widget.onLanguageChange(newLocale);
            },
            child: Text(
              Localizations.localeOf(context).languageCode == 'en' ? '🇮🇱' : '🇺🇸',
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              
              // Minimalist Title
              Text(
                localizations.appTitle,
                style: theme.textTheme.displayMedium?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w300,
                  letterSpacing: -0.5,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                localizations.appSubtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 80),
              
              // Clean Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.login,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF111827),
                      ),
                      decoration: InputDecoration(
                        labelText: localizations.email,
                        labelStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localizations.emailRequired;
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value.trim())) {
                          return localizations.emailInvalid;
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF111827),
                      ),
                      decoration: InputDecoration(
                        labelText: localizations.password,
                        labelStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF6B7280),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.passwordRequired;
                        }
                        if (value.length < 6) {
                          return localizations.passwordTooShort;
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 56),
                    
                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                localizations.login,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Forgot Password
                    TextButton(
                      onPressed: _isLoading ? null : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(localizations.forgotPasswordComingSoon),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        localizations.forgotPassword,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6B7280),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}