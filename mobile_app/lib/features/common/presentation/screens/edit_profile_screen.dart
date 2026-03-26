// ??? ????????
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/profile_field_tile.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../l10n/app_localizations.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();

  // Original data for comparison
  Map<String, dynamic> _originalData = {};
  final Map<String, String> _validationErrors = {};
  bool _isLoading = false;
  bool _isFetching = true;
  File? _selectedImage;
  String? _profilePicUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isFetching = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.getEditableProfile();
      if (result.success && result.data != null) {
        final userData = result.data!;

        // Extract all fields including phone_number and country
        final firstName = userData['first_name'] as String? ?? '';
        final lastName = userData['last_name'] as String? ?? '';
        final username = userData['username'] as String? ?? '';
        final email = userData['email'] as String? ?? '';
        final phoneNumber = userData['phone_number'] as String? ?? '';
        final country = userData['country'] as String? ?? '';
        final profilePicUrl = userData['profile_pic_url'] as String?;

        // Set controllers with actual data from database
        _firstNameController.text = firstName;
        _lastNameController.text = lastName;
        _usernameController.text = username;
        _emailController.text = email;
        _phoneController.text = phoneNumber;
        _countryController.text = country;
        _profilePicUrl = profilePicUrl;

        // Store original data for comparison
        _originalData = {
          'first_name': firstName,
          'last_name': lastName,
          'username': username,
          'email': email,
          'phone_number': phoneNumber,
          'country': country,
          'profile_pic_url': profilePicUrl ?? '',
        };

        // Clear validation errors on successful load
        _validationErrors.clear();

        if (mounted) {
          setState(() {});
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Failed to load profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  bool _hasChanges() {
    return _firstNameController.text != _originalData['first_name'] ||
        _lastNameController.text != _originalData['last_name'] ||
        _usernameController.text != _originalData['username'] ||
        _phoneController.text != _originalData['phone_number'] ||
        _countryController.text != _originalData['country'] ||
        _selectedImage != null;
  }

  String? _validateField(String field, String value) {
    switch (field) {
      case 'first_name':
      case 'last_name':
      case 'username':
      case 'country':
        if (value.trim().isEmpty) {
          return 'This field is required';
        }
        return null;
      case 'phone_number':
        if (value.trim().isEmpty) {
          return 'Phone number is required';
        }
        final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
        if (digitsOnly.length != 10) {
          return 'Phone number must be exactly 10 digits';
        }
        return null;
      default:
        return null;
    }
  }

  bool _validateForm() {
    _validationErrors.clear();

    final firstNameError = _validateField(
      'first_name',
      _firstNameController.text,
    );
    if (firstNameError != null) {
      _validationErrors['first_name'] = firstNameError;
    }

    final lastNameError = _validateField('last_name', _lastNameController.text);
    if (lastNameError != null) {
      _validationErrors['last_name'] = lastNameError;
    }

    final usernameError = _validateField('username', _usernameController.text);
    if (usernameError != null) {
      _validationErrors['username'] = usernameError;
    }

    final phoneError = _validateField('phone_number', _phoneController.text);
    if (phoneError != null) {
      _validationErrors['phone_number'] = phoneError;
    }

    final countryError = _validateField('country', _countryController.text);
    if (countryError != null) {
      _validationErrors['country'] = countryError;
    }

    setState(() {});
    return _validationErrors.isEmpty;
  }

  Future<void> _saveProfile() async {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_hasChanges()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes to save'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.updateEditableProfile(
        fields: <String, String>{
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'username': _usernameController.text.trim(),
          'phone_number': _phoneController.text.replaceAll(RegExp(r'\D'), ''),
          'country': _countryController.text.trim(),
        },
        avatarFile: _selectedImage,
        existingProfilePicUrl: _profilePicUrl,
      );

      if (response.success) {
        // Update original data
        _originalData = {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'username': _usernameController.text.trim(),
          'phone_number': _phoneController.text.replaceAll(RegExp(r'\D'), ''),
          'country': _countryController.text.trim(),
          'profile_pic_url':
              response.data?['profile_pic_url'] ?? _profilePicUrl ?? '',
        };

        // Update profile pic URL if changed
        if (response.data?['profile_pic_url'] != null) {
          _profilePicUrl = response.data?['profile_pic_url'] as String?;
          _selectedImage = null;
        }

        // Refresh auth state
        await ref.read(authStateProvider.notifier).refreshUser();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: AppColors.primary,
            ),
          );
          // Delay pop to avoid Navigator lock assertion
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _handleBackNavigation(context);
            }
          });
        }
      } else {
        throw Exception(response.message ?? 'Failed to update profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _discardChanges() {
    _firstNameController.text = _originalData['first_name'] ?? '';
    _lastNameController.text = _originalData['last_name'] ?? '';
    _usernameController.text = _originalData['username'] ?? '';
    _phoneController.text = _originalData['phone_number'] ?? '';
    _countryController.text = _originalData['country'] ?? '';
    _selectedImage = null;
    _validationErrors.clear();
    setState(() {});
  }

  void _cancelEditing(BuildContext context) {
    _discardChanges();
    _handleBackNavigation(context);
  }

  void _handleBackNavigation(BuildContext context) {
    // Use go_router's context.pop() which is safer than Navigator.pop()
    // It handles the navigation stack properly and avoids lock assertions
    if (context.canPop()) {
      context.pop();
    } else {
      // Fallback: navigate to profile based on user role
      // This prevents black screen when there's no route to pop
      final user = ref.read(authStateProvider).user;
      if (user != null) {
        // Check role_id: 2 = client, 3 = freelancer
        final profileRoute = user.roleId == 2
            ? '/client/profile'
            : '/freelancer/profile';
        context.go(profileRoute);
      } else {
        // If no user, go to client home as default
        context.go('/client');
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fullName = '${_firstNameController.text} ${_lastNameController.text}'
        .trim();

    if (_isFetching) {
      return const AppScaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Custom Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Back button in circle
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowColorLight,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        color: AppColors.textPrimary,
                        onPressed: () => _handleBackNavigation(context),
                      ),
                    ),
                    const Spacer(),
                    // Title
                    Text(
                      l10n.editProfile,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40), // Balance the back button
                  ],
                ),
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Avatar Section
                    _buildAvatarSection(),

                    const SizedBox(height: 32),

                    // Form Fields
                    ProfileFieldTile(
                      label: '${l10n.firstName} ${l10n.lastName}',
                      value: fullName.isEmpty ? '—' : fullName,
                      icon: Icons.edit_outlined,
                      readOnly: true,
                    ),

                    const SizedBox(height: 12),

                    ProfileFieldTile(
                      label: l10n.firstName,
                      controller: _firstNameController,
                      icon: Icons.person_outline_rounded,
                      errorText: _validationErrors['first_name'],
                      onChanged: (value) {
                        setState(() {
                          _validationErrors.remove('first_name');
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    ProfileFieldTile(
                      label: l10n.lastName,
                      controller: _lastNameController,
                      icon: Icons.person_outline_rounded,
                      errorText: _validationErrors['last_name'],
                      onChanged: (value) {
                        setState(() {
                          _validationErrors.remove('last_name');
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    ProfileFieldTile(
                      label: l10n.username,
                      controller: _usernameController,
                      icon: Icons.alternate_email_rounded,
                      errorText: _validationErrors['username'],
                      onChanged: (value) {
                        setState(() {
                          _validationErrors.remove('username');
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    ProfileFieldTile(
                      label: l10n.email,
                      value: _emailController.text,
                      icon: Icons.email_outlined,
                      readOnly: true,
                    ),

                    const SizedBox(height: 12),

                    ProfileFieldTile(
                      label: l10n.phone,
                      controller: _phoneController,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      errorText: _validationErrors['phone_number'],
                      onChanged: (value) {
                        // Allow only digits, max 10
                        final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                        if (digitsOnly.length <= 10) {
                          _phoneController.value = TextEditingValue(
                            text: digitsOnly,
                            selection: TextSelection.collapsed(
                              offset: digitsOnly.length,
                            ),
                          );
                        }
                        setState(() {
                          _validationErrors.remove('phone_number');
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    ProfileFieldTile(
                      label: l10n.country,
                      controller: _countryController,
                      icon: Icons.location_on_outlined,
                      errorText: _validationErrors['country'],
                      onChanged: (value) {
                        setState(() {
                          _validationErrors.remove('country');
                        });
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColorLight,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Discard Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => _cancelEditing(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          side: const BorderSide(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Save Button
                    Expanded(
                      child: PrimaryGradientButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        label: l10n.save,
                        isLoading: _isLoading,
                        height: 52,
                        borderRadius: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final imageUrl = _selectedImage != null
        ? null
        : (_profilePicUrl != null && _profilePicUrl!.isNotEmpty
              ? (_profilePicUrl!.startsWith('http')
                    ? _profilePicUrl!
                    : '${AppConfig.baseUrl}$_profilePicUrl')
              : null);

    return Center(
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.accentOrange.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: _selectedImage != null
            ? ClipOval(
                child: Image.file(
                  _selectedImage!,
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              )
            : imageUrl != null
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.accentOrange.withValues(alpha: 0.10),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.accentOrange,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.accentOrange.withValues(alpha: 0.10),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 55,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 55,
                  color: AppColors.primary,
                ),
              ),
      ),
    );
  }
}
