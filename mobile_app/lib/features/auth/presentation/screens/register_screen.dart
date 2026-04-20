// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/screenutil_helpers.dart';
import '../../../../core/utils/validators.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/models/category.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../providers/auth_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../data/models/signup_payload.dart';

// Alias for backward compatibility
typedef GradientButton = PrimaryGradientButton;

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  final _usernameController = TextEditingController();
  final _referralCodeController = TextEditingController();

  int? _selectedRole;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0; // Visual step (0-3 for Client, 0-4 for Freelancer)
  List<int> _selectedCategories = []; // Selected category IDs for Freelancer

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _usernameController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  // Get total step count based on role
  int get _totalSteps =>
      _selectedRole == 3 ? 5 : 4; // Freelancer = 5, Client = 4

  // Get actual step content type based on visual step and role
  String _getStepType(int visualStep) {
    if (_selectedRole == 3) {
      // Freelancer: 0=Role, 1=Categories, 2=Name, 3=Account, 4=Contact
      switch (visualStep) {
        case 0:
          return 'role';
        case 1:
          return 'categories';
        case 2:
          return 'name';
        case 3:
          return 'account';
        case 4:
          return 'contact';
        default:
          return 'role';
      }
    } else {
      // Client: 0=Role, 1=Name, 2=Account, 3=Contact
      switch (visualStep) {
        case 0:
          return 'role';
        case 1:
          return 'name';
        case 2:
          return 'account';
        case 3:
          return 'contact';
        default:
          return 'role';
      }
    }
  }

  bool _validateStep(int step) {
    final stepType = _getStepType(step);

    switch (stepType) {
      case 'role':
        if (_selectedRole == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Please select a role')));
          return false;
        }
        return true;
      case 'categories':
        if (_selectedRole == 3 && _selectedCategories.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select at least one category'),
            ),
          );
          return false;
        }
        return true;
      case 'name':
        final firstNameValid =
            Validators.required(
              _firstNameController.text,
              fieldName: 'First name',
            ) ==
            null;
        final lastNameValid =
            Validators.required(
              _lastNameController.text,
              fieldName: 'Last name',
            ) ==
            null;
        if (!firstNameValid || !lastNameValid) {
          _formKey.currentState?.validate();
          return false;
        }
        return true;
      case 'account':
        final usernameValid =
            Validators.required(
              _usernameController.text,
              fieldName: 'Username',
            ) ==
            null;
        final emailValid =
            Validators.email(_emailController.text.trim()) == null;
        final passwordValid =
            Validators.password(_passwordController.text) == null;
        final confirmPasswordValid =
            Validators.match(
              _confirmPasswordController.text,
              _passwordController.text,
              fieldName: 'Password',
            ) ==
            null;
        if (!usernameValid ||
            !emailValid ||
            !passwordValid ||
            !confirmPasswordValid) {
          _formKey.currentState?.validate();
          return false;
        }
        return true;
      case 'contact':
        final countryValid =
            Validators.required(
              _countryController.text,
              fieldName: 'Country',
            ) ==
            null;
        if (!countryValid) {
          _formKey.currentState?.validate();
          return false;
        }
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_validateStep(_currentStep)) {
      if (_currentStep < _totalSteps - 1) {
        setState(() {
          _currentStep++;
        });
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _handleRegister() async {
    // Validate all steps before submitting
    bool allValid = true;
    for (int i = 0; i < _totalSteps; i++) {
      if (!_validateStep(i)) {
        allValid = false;
        if (i != _currentStep) {
          setState(() {
            _currentStep = i;
          });
        }
        break;
      }
    }

    if (!allValid) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a role')));
      return;
    }

    // Validate categories for Freelancer
    if (_selectedRole == 3 && _selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }

    final authNotifier = ref.read(authStateProvider.notifier);
    final referralCode = _referralCodeController.text.trim().toUpperCase();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final payload = SignupPayload(
      roleId: _selectedRole!,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: email,
      password: _passwordController.text.trim(),
      phoneNumber: phone.isEmpty ? null : phone,
      country: _countryController.text.trim(),
      username: _usernameController.text.trim(),
      categoryIds: _selectedRole == 3 ? _selectedCategories : null,
      referralCode: referralCode.isNotEmpty ? referralCode : null,
    );

    // Step A: Request OTP only (no account created yet)
    final success = await authNotifier.startSignup(payload);

    if (!mounted) return;

    if (success) {
      ref.read(pendingSignupPayloadProvider.notifier).state = payload;
      context.go('/verify-email?email=${Uri.encodeComponent(email)}');
    } else {
      final error = ref.read(authStateProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ??
                'Could not send verification code. Check your email or try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final l10n = AppLocalizations.of(context)!;
    final heroD = 100.r.clamp(88.0, 112.0);
    final heroIcon = 50.r.clamp(44.0, 56.0);

    return Scaffold(
      backgroundColor: AppColors.background, // Pure white
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppContentLayout.contentMaxWidth(context),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  // Step indicator at top
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        // Step text (dynamic based on role)
                        Text(
                          'Step ${_currentStep + 1} of $_totalSteps',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: const Color(0xFF8A8A95), // Muted gray
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Progress bars (dynamic count)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_totalSteps, (index) {
                            final isActive = index <= _currentStep;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Container(
                                width: isActive ? 40 : 20,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFFFB923C)
                                      : const Color(
                                          0xFFE8E8EE,
                                        ), // Orange active, light gray inactive
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  // Form content (scrollable)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: AppSpacing.xl),
                            // Top circle with icon
                            Center(
                              child: Container(
                                width: heroD,
                                height: heroD,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(
                                    255,
                                    255,
                                    215,
                                    182,
                                  ), // Light pink
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.send_rounded,
                                  size: heroIcon,
                                  color: const Color(0xFFEF4444), // Coral-red
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            // Title
                            Text(
                              l10n.signUp,
                              style: AppTextStyles.displayMedium.copyWith(
                                color: const Color(
                                  0xFF0B0B0F,
                                ), // Near-black primary
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            // Subtitle
                            Text(
                              _getStepSubtitle(l10n),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: const Color(0xFF8A8A95), // Neutral gray
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            // Step content
                            _buildStepContent(),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom buttons (pinned)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "Already have an account? Sign In" link
                        InkWell(
                          onTap: () {
                            context.go('/login');
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: const Color(
                                      0xFF8A8A95,
                                    ), // Neutral gray
                                  ),
                                ),
                                Text(
                                  l10n.login,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: const Color(
                                      0xFFFB923C,
                                    ), // Red accent
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Buttons row
                        Row(
                          children: [
                            // Back button (show on steps > 0)
                            if (_currentStep > 0)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _previousStep,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFFB923C),
                                    minimumSize: const Size(0, 52),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: 12,
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFFFB923C),
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.arrow_back_ios_rounded,
                                        size: 16,
                                        color: Color(0xFFFB923C),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          l10n.back,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.labelLarge
                                              .copyWith(
                                                color: const Color(0xFFFB923C),
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (_currentStep > 0)
                              const SizedBox(width: AppSpacing.md),
                            // Next/Sign Up button
                            Expanded(
                              flex: _currentStep > 0 ? 1 : 1,
                              child: GradientButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : (_currentStep == _totalSteps - 1
                                          ? _handleRegister
                                          : _nextStep),
                                label: _currentStep == _totalSteps - 1
                                    ? l10n.signUp
                                    : l10n.next,
                                isLoading: authState.isLoading,
                                height: 52,
                                borderRadius: 30, // Pill shape
                              ),
                            ),
                          ],
                        ),
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

  String _getStepSubtitle(AppLocalizations l10n) {
    final stepType = _getStepType(_currentStep);
    switch (stepType) {
      case 'role':
        return 'Choose your role';
      case 'categories':
        return 'Select your categories';
      case 'name':
        return 'Enter your name';
      case 'account':
        return 'Create your account';
      case 'contact':
        return 'Add your contact information';
      default:
        return l10n.loading;
    }
  }

  Widget _buildStepContent() {
    final stepType = _getStepType(_currentStep);
    switch (stepType) {
      case 'role':
        return _buildStep1Role();
      case 'categories':
        return _buildStepCategories();
      case 'name':
        return _buildStepName();
      case 'account':
        return _buildStepAccount();
      case 'contact':
        return _buildStepContact();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1Role() {
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            role: 'Client',
            icon: Icons.business_center_rounded,
            value: 2,
            isSelected: _selectedRole == 2,
            onTap: () {
              setState(() {
                _selectedRole = 2;
                // Reset to step 0 if role changes
                if (_currentStep > 0) {
                  _currentStep = 0;
                }
                // Clear categories if switching from Freelancer
                _selectedCategories = [];
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RoleCard(
            role: 'Freelancer',
            icon: Icons.laptop_mac_rounded,
            value: 3,
            isSelected: _selectedRole == 3,
            onTap: () {
              setState(() {
                _selectedRole = 3;
                // Reset to step 0 if role changes
                if (_currentStep > 0) {
                  _currentStep = 0;
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStepCategories() {
    final categoriesAsync = ref.watch(exploreCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'No categories available',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF8A8A95), // Neutral gray
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Helper text
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                'Select at least one category',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF8A8A95), // Neutral gray
                ),
              ),
            ),
            // Categories grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategories.contains(category.id);
                return _CategoryCard(
                  category: category,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCategories.remove(category.id);
                      } else {
                        _selectedCategories.add(category.id);
                      }
                    });
                  },
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(
            color: Color(0xFFFB923C), // Orange accent
          ),
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Text(
                'Failed to load categories',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFFFB923C), // Red accent for errors
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryGradientButton(
                onPressed: () {
                  ref.invalidate(exploreCategoriesProvider);
                },
                label: 'Retry',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepName() {
    return Column(
      children: [
        _StyledTextField(
          controller: _firstNameController,
          hint: 'First Name',
          prefixIcon: Icons.person_outline,
          validator: (v) => Validators.required(v, fieldName: 'First name'),
        ),
        const SizedBox(height: AppSpacing.md),
        _StyledTextField(
          controller: _lastNameController,
          hint: 'Last Name',
          prefixIcon: Icons.person_outline,
          validator: (v) => Validators.required(v, fieldName: 'Last name'),
        ),
      ],
    );
  }

  Widget _buildStepAccount() {
    return Column(
      children: [
        _StyledTextField(
          controller: _usernameController,
          hint: 'Username',
          prefixIcon: Icons.person_outline,
          validator: (v) => Validators.required(v, fieldName: 'Username'),
        ),
        const SizedBox(height: AppSpacing.md),
        _StyledTextField(
          controller: _emailController,
          hint: 'Email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
        ),
        const SizedBox(height: AppSpacing.md),
        _StyledTextField(
          controller: _passwordController,
          hint: 'Password',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF8A8A95), // Neutral gray
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          validator: Validators.password,
        ),
        const SizedBox(height: AppSpacing.md),
        _StyledTextField(
          controller: _confirmPasswordController,
          hint: 'Confirm Password',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF8A8A95), // Neutral gray
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          validator: (v) => Validators.match(
            v,
            _passwordController.text,
            fieldName: 'Password',
          ),
        ),
      ],
    );
  }

  Widget _buildStepContact() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StyledTextField(
          controller: _phoneController,
          hint: 'Phone Number (Optional)',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: null,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.phoneNumberWhyWeCollectHint,
          style: AppTextStyles.bodySmall.copyWith(
            color: const Color(0xFF8A8A95),
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _StyledTextField(
          controller: _countryController,
          hint: 'Country',
          prefixIcon: Icons.location_on_outlined,
          validator: (v) => Validators.required(v, fieldName: 'Country'),
        ),
        const SizedBox(height: AppSpacing.md),
        // Optional referral code field
        _StyledTextField(
          controller: _referralCodeController,
          hint: 'Referral Code (Optional)',
          prefixIcon: Icons.card_giftcard_outlined,
          textCapitalization: TextCapitalization.characters,
          validator: null, // Optional field
        ),
      ],
    );
  }
}

// Role selection card
class _RoleCard extends StatelessWidget {
  final String role;
  final IconData icon;
  final int value;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.icon,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = 28.r.clamp(24.0, 32.0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        // Do not cap maxHeight: parent Row can pass ~100px on wide layouts; min>max caused overflow.
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white, // White background
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFB923C)
                : const Color(
                    0xFFE8E8EE,
                  ), // Red accent when selected, light gray when not
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFB923C).withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                    spreadRadius: 0,
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              icon,
              size: iconSize,
              color: isSelected
                  ? const Color(0xFFFB923C)
                  : const Color(
                      0xFF8A8A95,
                    ), // Red accent when selected, neutral gray when not
            ),
            const SizedBox(height: 8),
            // Role title
            Text(
              role,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected
                    ? const Color(0xFF0B0B0F)
                    : const Color(
                        0xFF8A8A95,
                      ), // Near-black when selected, neutral gray when not
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            // Radio indicator
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFB923C)
                      : const Color(0xFFD1D5DB), // Red accent when selected
                  width: 1.5,
                ),
                color: isSelected
                    ? const Color(0xFFFB923C)
                    : Colors.transparent, // Red accent when selected
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 10, color: Colors.white),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// Category selection card
class _CategoryCard extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white, // White background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFB923C)
                : const Color(
                    0xFFE8E8EE,
                  ), // Red accent when selected, light gray when not
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFB923C).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                    spreadRadius: 0,
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected
                      ? const Color(0xFF0B0B0F)
                      : const Color(
                          0xFF8A8A95,
                        ), // Near-black when selected, neutral gray when not
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(left: AppSpacing.sm),
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFFFB923C), // Orange accent
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Styled text field matching reference design
class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextCapitalization? textCapitalization;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.textCapitalization,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        textCapitalization: textCapitalization ?? TextCapitalization.none,
        style: AppTextStyles.bodyLarge.copyWith(
          color: const Color(0xFF0B0B0F), // Near-black primary
        ),
        cursorColor: const Color(0xFFFB923C), // Red accent for cursor
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF9A9AA4), // Gray hint text
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: const Color(0xFF8A8A95), // Neutral gray for icons
            size: 20,
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFE8E8EE), // Very light gray border
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFE8E8EE), // Very light gray border
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFFB923C), // Orange accent for focus
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFFB923C), // Orange accent for errors
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFFB923C), // Orange accent for focused errors
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}
