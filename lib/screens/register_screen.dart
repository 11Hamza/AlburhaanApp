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
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  String? _selectedLibrary;
  String? _selectedCategory;
  List<Map<String, dynamic>> _libraries = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  bool _isLoadingInfo = true;
  DateTime? _dateOfBirth;

  // Fallback categories from Al-Burhaan Koha system
  static const List<Map<String, dynamic>> _fallbackCategories = [
    {'id': 'PT', 'name': 'Patron (Adult)'},
    {'id': 'ST', 'name': 'Student'},
    {'id': 'YA', 'name': 'Young Adult'},
    {'id': 'J', 'name': 'Juvenile'},
    {'id': 'K', 'name': 'Kid'},
    {'id': 'T', 'name': 'Teacher'},
    {'id': 'HB', 'name': 'Home Bound'},
  ];

  // Fallback library
  static const List<Map<String, dynamic>> _fallbackLibraries = [
    {'id': 'MAIN', 'name': 'Main Library'},
  ];

  @override
  void initState() {
    super.initState();

    // Set fallback values immediately
    _categories = List<Map<String, dynamic>>.from(_fallbackCategories);
    _libraries = List<Map<String, dynamic>>.from(_fallbackLibraries);
    _selectedCategory = _categories.first['id']?.toString();
    _selectedLibrary = _libraries.first['id']?.toString();

    _loadRegistrationInfo();

    // Pre-fill from SSO profile if available
    if (widget.ssoProfile != null) {
      _firstNameController.text = widget.ssoProfile!['firstName']?.toString() ?? '';
      _surnameController.text = widget.ssoProfile!['lastName']?.toString() ?? '';
      _emailController.text = widget.ssoProfile!['email']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadRegistrationInfo() async {
    // Already have fallback values, so set loading to false immediately
    if (mounted) {
      setState(() => _isLoadingInfo = false);
    }

    // Try to fetch from API to get actual libraries
    try {
      final authProvider = context.read<AuthProvider>();
      final info = await authProvider.getRegistrationInfo();

      debugPrint('DEBUG: Registration info received: $info');

      if (mounted && info != null) {
        setState(() {
          // Only override libraries if API returned valid data
          if (info['libraries'] != null) {
            final apiLibraries = List<Map<String, dynamic>>.from(info['libraries'] as List);
            if (apiLibraries.isNotEmpty) {
              _libraries = apiLibraries;
              _selectedLibrary = _libraries.first['id']?.toString();
              debugPrint('DEBUG: Loaded ${_libraries.length} libraries from API');
            }
          }
          // Only override categories if API returned valid data
          if (info['categories'] != null) {
            final apiCategories = List<Map<String, dynamic>>.from(info['categories'] as List);
            if (apiCategories.isNotEmpty) {
              _categories = apiCategories;
              _selectedCategory = _categories.first['id']?.toString();
              debugPrint('DEBUG: Loaded ${_categories.length} categories from API');
            }
          }
        });
      }
    } catch (e) {
      debugPrint('DEBUG: Error loading registration info: $e');
      // Keep using fallback values
    }
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select Date of Birth',
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate category and library are selected
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patron category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedLibrary == null || _selectedLibrary!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a home library'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    debugPrint('DEBUG: Registering with category=$_selectedCategory, library=$_selectedLibrary');

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
      categoryId: _selectedCategory,
      ssoProvider: widget.ssoProfile?['provider']?.toString(),
      ssoProviderAccountId: widget.ssoProfile?['providerAccountId']?.toString(),
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
                    // Header
                    Text(
                      'Join Al-Burhaan Library',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your library account to borrow books, place holds, and access digital resources.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                    ),
                    const SizedBox(height: 24),

                    // SSO Badge (if applicable)
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
                                    widget.ssoProfile!['email']?.toString() ?? '',
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

                    // Personal Information Section
                    _buildSectionHeader(context, 'Personal Information', Icons.person),
                    const SizedBox(height: 16),

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

                    // Date of Birth
                    InkWell(
                      onTap: _selectDateOfBirth,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          prefixIcon: Icon(Icons.cake),
                        ),
                        child: Text(
                          _dateOfBirth != null
                              ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                              : 'Select date (optional)',
                          style: _dateOfBirth != null
                              ? null
                              : TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Contact Information Section
                    _buildSectionHeader(context, 'Contact Information', Icons.contact_mail),
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

                    // Phone
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
                    const SizedBox(height: 24),

                    // Address Section
                    _buildSectionHeader(context, 'Address (Optional)', Icons.home),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Street Address',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // City and Postal Code in a Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              prefixIcon: Icon(Icons.location_city),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _postalCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Postal Code',
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Library Preferences Section
                    _buildSectionHeader(context, 'Library Preferences', Icons.local_library),
                    const SizedBox(height: 16),

                    // Library Dropdown (required by Koha)
                    Builder(
                      builder: (context) {
                        // Validate that selected value exists in items
                        final validLibrary = _libraries.isEmpty
                            ? null
                            : (_libraries.any((lib) => lib['id']?.toString() == _selectedLibrary)
                                ? _selectedLibrary
                                : _libraries.first['id']?.toString());
                        return DropdownButtonFormField<String>(
                          value: validLibrary,
                          decoration: const InputDecoration(
                            labelText: 'Home Library *',
                            prefixIcon: Icon(Icons.local_library),
                          ),
                          items: _libraries.map((lib) {
                            return DropdownMenuItem(
                              value: lib['id']?.toString(),
                              child: Text(lib['name']?.toString() ?? 'Unknown'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedLibrary = value);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a home library';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown (required by Koha)
                    Builder(
                      builder: (context) {
                        // Validate that selected value exists in items
                        final validCategory = _categories.isEmpty
                            ? null
                            : (_categories.any((cat) => cat['id']?.toString() == _selectedCategory)
                                ? _selectedCategory
                                : _categories.first['id']?.toString());
                        return DropdownButtonFormField<String>(
                          value: validCategory,
                          decoration: const InputDecoration(
                            labelText: 'Patron Category *',
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: _categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat['id']?.toString(),
                              child: Text(cat['name']?.toString() ?? 'Unknown'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCategory = value);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a patron category';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 32),

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
                    const SizedBox(height: 16),

                    // Already have account link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}
