import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _loadingType; // 'login', 'guest', 'google'

  @override
  void dispose() {
    _cardNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _loadingType = 'login';
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _cardNumberController.text.trim(),
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
      _loadingType = null;
    });

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _isLoading = true;
      _loadingType = 'guest';
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginAsGuest();

    setState(() {
      _isLoading = false;
      _loadingType = null;
    });

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Failed to continue as guest'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _loadingType = 'google';
    });

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.loginWithGoogle();

    setState(() {
      _isLoading = false;
      _loadingType = null;
    });

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else if (result['needsRegistration'] == true) {
      // Navigate to registration with pre-filled SSO data
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RegisterScreen(
            ssoProfile: result['ssoProfile'] as Map<String, dynamic>?,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Google sign in failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _goToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Logo
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.local_library,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Welcome to',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'Al-Burhaan Library',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 32),

                // Card Number Field
                TextFormField(
                  controller: _cardNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Library Card Number',
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your card number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Login Button
                FilledButton(
                  onPressed: _isLoading ? null : _login,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _loadingType == 'login'
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Login'),
                  ),
                ),
                const SizedBox(height: 16),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                // Google Sign In Button
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loginWithGoogle,
                  icon: _loadingType == 'google'
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.g_mobiledata, size: 24),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_loadingType == 'google'
                        ? 'Signing in...'
                        : 'Continue with Google'),
                  ),
                ),
                const SizedBox(height: 12),

                // Guest Button
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _continueAsGuest,
                  icon: _loadingType == 'guest'
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_outline),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_loadingType == 'guest'
                        ? 'Loading...'
                        : 'Continue as Guest'),
                  ),
                ),
                const SizedBox(height: 24),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _goToRegister,
                      child: const Text('Register'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Language Selector
                Center(
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _LanguageChip(
                        label: 'English',
                        isSelected: settings.locale.languageCode == 'en',
                        onTap: () => settings.setLanguage('en'),
                      ),
                      _LanguageChip(
                        label: 'العربية',
                        isSelected: settings.locale.languageCode == 'ar',
                        onTap: () => settings.setLanguage('ar'),
                      ),
                      _LanguageChip(
                        label: 'اردو',
                        isSelected: settings.locale.languageCode == 'ur',
                        onTap: () => settings.setLanguage('ur'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}
