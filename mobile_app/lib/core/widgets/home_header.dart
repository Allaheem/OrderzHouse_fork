// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Clean home header with avatar, greeting, and notifications bell (no background)
/// Reference layout: Avatar + "Hello, Name!" on left, Bell icon on right
/// Data source: User from authStateProvider, unread count from unreadCountProvider
class HomeHeader extends ConsumerWidget {
  final String roleRoute; // "/freelancer" or "/client"

  const HomeHeader({super.key, required this.roleRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final unreadCountAsync = ref.watch(unreadCountProvider);
    final unreadCount = unreadCountAsync.valueOrNull ?? 0;

    // Get user's first name, fallback to username
    final firstName = user?.firstName ?? user?.username ?? 'User';
    final profilePicUrl = user?.profilePicUrl;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Left: Avatar + Greeting
            Expanded(
              child: GestureDetector(
                onTap: () {
                  context.push('$roleRoute/profile');
                },
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.borderLight,
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowColorLight,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child:
                            profilePicUrl != null &&
                                profilePicUrl.isNotEmpty &&
                                AppConfig.baseUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: profilePicUrl.startsWith('http')
                                    ? profilePicUrl
                                    : '${AppConfig.baseUrl}$profilePicUrl',
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppColors.surfaceVariant,
                                  child: const Icon(
                                    Icons.person_outline_rounded,
                                    color: AppColors.accentOrange,
                                    size: 22,
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    _buildAvatarFallback(),
                              )
                            : _buildAvatarFallback(),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Greeting Text
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context)!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.helloUser(firstName),
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.welcomeBack,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right: Notification Bell with Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.iconBlack,
                    size: 26,
                  ),
                  onPressed: () {
                    context.push('$roleRoute/notifications');
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accentOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Icon(
        Icons.person_outline_rounded,
        color: AppColors.accentOrange,
        size: 22,
      ),
    );
  }
}
