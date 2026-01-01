import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'main_screen.dart';

class RegisterScreen extends StatefulWidget {
  final Map<String, dynamic>? ssoProfile;

  const RegisterScreen({super.key, this.ssoProfile});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedLibrary;
  List<Map<String, dynamic>> _libraries = [];
  bool _isLoading = false;
  bool _isLoadingInfo = true;

  @override
  void initState() {
    super.initState();
    _loadRegistrationInfo();

    // Pre-fill from SSO profile if available
    if (widget.ssoProfile != null) {
      _firstNameController.text = widget.ssoProfile!['firstName'] ?? '';
      _surnameController.text = widget.ssoProfile!['lastName'] ?? '';
      _emailController.text = widget.ssoProfile!['email'] ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadRegistrationInfo() async {
    final authProvider = context.read<AuthProvider>();
    final info = await authProvider.getRegistrationInfo();

    if (mounted) {
      setState(() {
        _isLoadingInfo = false;
        if (info != null && info['libraries'] != null) {
          _libraries = List<Map<String, dynamic>>.from(info['libraries']);
          if (_libraries.isNotEmpty) {
            _selectedLibrary = _libraries.first['id'] as String?;
          }
        }
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      firstName: _firstNameController.text.trim(),
      surname: _surnameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      libraryId: _selectedLibrary,
      ssoProvider: widget.ssoProfile?['provider'],
      ssoProviderAccountId: widget.ssoProfile?['providerAccountId'],
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Registration failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSSO = widget.ssoProfile != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: _isLoadingInfo
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // SSO Badge
                    if (isSSO) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.ssoProfile!['provider'] == 'google'
                                  ? Icons.g_mobiledata
                                  : Icons.business,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Signing up with ${widget.ssoProfile!['provider'] == 'google' ? 'Google' : 'Microsoft'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    widget.ssoProfile!['email'] ?? '',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // First Name
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name *',
                        prefixIcon: Icon(Icons.person),
                      ),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Surname
                    TextFormField(
                      controller: _surnameController,
                      decoration: const InputDecoration(
                        labelText: 'Surname *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your surname';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !isSSO, // Disable if from SSO
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone (optional)
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        hintText: 'Optional',
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Library Dropdown
                    if (_libraries.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedLibrary,
                        decoration: const InputDecoration(
                          labelText: 'Home Library',
                          prefixIcon: Icon(Icons.local_library),
                        ),
                        items: _libraries.map((lib) {
                          return DropdownMenuItem(
                            value: lib['id'] as String,
                            child: Text(lib['name'] as String),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedLibrary = value);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Register Button
                    FilledButton(
                      onPressed: _isLoading ? null : _register,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('Create Account'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Terms notice
                    Text(
                      'By creating an account, you agree to the library\'s terms of use and privacy policy.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
