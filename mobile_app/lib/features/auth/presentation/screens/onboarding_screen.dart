// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/ui/screenutil_helpers.dart' show AppContentLayout;
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../l10n/app_localizations.dart';

/// Onboarding page model
class OnboardingPage {
  final String title;
  final String description;
  final String imageAsset;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.imageAsset,
  });
}

/// Onboarding Screen with PageView
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Get localized onboarding pages
  List<OnboardingPage> _getPages(AppLocalizations l10n) {
    return [
      OnboardingPage(
        title: l10n.onboardingTitle1New,
        description: l10n.onboardingDesc1New,
        imageAsset: '',
      ),
      OnboardingPage(
        title: l10n.onboardingTitle2New,
        description: l10n.onboardingDesc2New,
        imageAsset: '',
      ),
      OnboardingPage(
        title: l10n.onboardingTitle3New,
        description: l10n.onboardingDesc3New,
        imageAsset: '',
      ),
      OnboardingPage(
        title: l10n.onboardingTitle4New,
        description: l10n.onboardingDesc4New,
        imageAsset: '',
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _getPages(l10n);

    return Scaffold(
      backgroundColor: AppColors.background, // Pure white
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Spacer to reserve space where Skip button was (maintains exact layout)
                // Height calculation: Padding (AppSpacing.md = 16px on all sides) + TextButton (~40px) = ~72px total
                // Using 72px to match: top padding (16px) + button height (~40px) + bottom padding (16px)
                const SizedBox(height: 72),

                // PageView with illustrations and content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      return _OnboardingPageContent(
                        page: pages[index],
                        pageIndex: index,
                      );
                    },
                  ),
                ),

                // Dots indicator
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: AppContentLayout.contentMaxWidth(context),
                      ),
                      child: _DotsIndicator(
                        currentPage: _currentPage,
                        pageCount: pages.length,
                      ),
                    ),
                  ),
                ),

                // Bottom buttons
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: AppContentLayout.contentMaxWidth(context),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Register button (filled)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: PrimaryGradientButton(
                              onPressed: () {
                                context.go('/register');
                              },
                              label: l10n.register,
                              height: 56,
                              borderRadius: AppRadius.lg,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Sign in button (outlined)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () {
                                context.go('/login');
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFFB923C),
                                side: const BorderSide(
                                  color: Color(0xFFFB923C),
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
                                ),
                              ),
                              child: Text(
                                l10n.signIn,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: const Color(0xFFFB923C),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Individual onboarding page content
class _OnboardingPageContent extends StatefulWidget {
  final OnboardingPage page;
  final int pageIndex;

  const _OnboardingPageContent({required this.page, required this.pageIndex});

  @override
  State<_OnboardingPageContent> createState() => _OnboardingPageContentState();
}

class _OnboardingPageContentState extends State<_OnboardingPageContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildIllustrationPlaceholder(int pageIndex) {
    // Placeholder illustrations with icons matching the theme
    final icons = [
      Icons.handshake_outlined, // Connect Talent
      Icons.chat_bubble_outline, // Collaboration
      Icons.security_outlined, // Secure Payments
      Icons.rocket_launch_outlined, // Start Journey
    ];

    // Ensure pageIndex is within bounds
    final safeIndex = pageIndex.clamp(0, icons.length - 1);

    final iconSize = 140.r.clamp(110.0, 180.0);
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Icon(
          icons[safeIndex],
          size: iconSize,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final illustrationHeight = 320.h.clamp(260.0, 400.0);
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppContentLayout.contentMaxWidth(context),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.xl),
                // Illustration card with gradient
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: double.infinity,
                    height: illustrationHeight,
                    margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFB923C), Color(0xFFEF4444)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(
                            255,
                            251,
                            119,
                            141,
                          ).withOpacity(0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: _buildIllustrationPlaceholder(widget.pageIndex),
                    ),
                  ),
                ),

                // Title with animation
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      widget.page.title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.displayMedium.copyWith(
                        color: const Color(0xFF1A1A1A),
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Description with animation
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      widget.page.description,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: const Color(0xFF6B7280),
                        height: 1.6,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated dots indicator
class _DotsIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const _DotsIndicator({required this.currentPage, required this.pageCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        final activeW = 24.w.clamp(20.0, 32.0);
        final inactiveW = 8.w.clamp(6.0, 12.0);
        final dotH = 8.h.clamp(7.0, 10.0);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: isActive ? activeW : inactiveW,
          height: dotH,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFFB923C)
                : const Color(0xFFFB923C).withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
