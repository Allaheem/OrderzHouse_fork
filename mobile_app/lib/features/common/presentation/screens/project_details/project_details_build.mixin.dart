// setState is valid at runtime when the extension receiver is this State; the analyzer
// does not treat extension methods as instance members for @protected.
// ignore_for_file: invalid_use_of_protected_member

part of 'package:OrderzHouse/features/common/presentation/screens/project_details_screen.dart';

extension _ProjectDetailsBuildExtension on _ProjectDetailsScreenState {
  /// Called from [_ProjectDetailsScreenState.build].
  Widget projectDetailsRootBuild(BuildContext context) {
    // If we're fetching by ID, show loading/error states
    if (_currentProject == null && widget.projectId != null) {
      final projectAsync = ref.watch(projectByIdProvider(widget.projectId!));
      return projectAsync.when(
        data: (project) {
          if (project == null) {
            final l10n = AppLocalizations.of(context)!;
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(title: Text(l10n.projectNotFound)),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.projectNotFound,
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.projectNotFoundMessage,
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/client');
                          }
                        },
                        child: Text(l10n.backToNotifications),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          // Project loaded, update state and initialize
          if (mounted) {
            setState(() {
              _currentProject = project;
            });
            // Initialize project data (fetch assignments, deliveries, etc.)
            // Use post-frame callback to avoid calling async methods during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _currentProject == project) {
                initializeWithProject();
              }
            });
          }
          // Return normal build with project
          return buildProjectContent(context, project);
        },
        loading: () {
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.loadingProject,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        error: (error, stackTrace) {
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(title: Text(l10n.error)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.failedToLoadProjects,
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString().replaceAll('Exception: ', ''),
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/client');
                        }
                      },
                      child: Text(l10n.back),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // Project is available, render normally
    return buildProjectContent(context, _project!);
  }

  /// Messages icon (chat bubble) with red dot when unread. Same UI; dot visibility from projectUnreadProvider.
  Widget buildMessagesIconWithUnread(int projectId) {
    final unreadAsync = ref.watch(projectUnreadProvider(projectId));
    final unreadCount = unreadAsync.valueOrNull ?? 0;
    final hasUnread = unreadCount > 0;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            color: AppColors.accentOrange,
            iconSize: 20,
            onPressed: () {
              context.push('/project/$projectId/messages');
            },
          ),
          if (hasUnread)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Change requests icon (chat bubble) with red dot when unread. Same UI; dot from changeRequestsUnreadCountProvider.
  Widget buildChangeRequestsIconWithUnread(int projectId) {
    final unreadAsync = ref.watch(changeRequestsUnreadCountProvider(projectId));
    final unreadCount = unreadAsync.valueOrNull ?? 0;
    final hasUnread = unreadCount > 0;
    final project = _project;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            color: AppColors.accentOrange,
            iconSize: 20,
            onPressed: () {
              final title = project?.title ?? '';
              context.push(
                '/project/$projectId/change-requests?title=${Uri.encodeComponent(title)}',
              );
            },
          ),
          if (hasUnread)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildProjectContent(BuildContext context, Project project) {
    // Build image URL
    final imageUrl = project.coverPic != null && project.coverPic!.isNotEmpty
        ? (project.coverPic!.startsWith('http')
              ? project.coverPic!
              : '${AppConfig.baseUrl}${project.coverPic}')
        : null;

    // Get duration text
    String durationText = 'N/A';
    if (project.durationDays != null) {
      durationText =
          '${project.durationDays} ${project.durationDays == 1 ? 'day' : 'days'}';
    } else if (project.durationHours != null) {
      durationText =
          '${project.durationHours} ${project.durationHours == 1 ? 'hour' : 'hours'}';
    }

    // Check if current user is freelancer (role_id == 3)
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final isFreelancer = user?.roleId == 3;

    // Determine button label and action based on project type
    final projectTypeLower = project.projectType.toLowerCase();
    final isBidding = projectTypeLower == 'bidding';
    final isFixed = projectTypeLower == 'fixed';
    final isHourly = projectTypeLower == 'hourly';

    // Determine button label (null if project type is unknown)
    String? buttonLabel;
    if (_hasApplied) {
      buttonLabel = AppLocalizations.of(context)!.applied;
    } else if (isBidding) {
      buttonLabel = AppLocalizations.of(context)!.submitOffer;
    } else if (isFixed || isHourly) {
      buttonLabel = AppLocalizations.of(context)!.apply;
    }

    // Show button only for freelancers, and only if project type is known (bidding/fixed/hourly)
    final hasValidProjectType = isBidding || isFixed || isHourly;
    // Note: Actual visibility is controlled by _shouldShowStickyCTA which checks assignment
    final shouldShowButton = isFreelancer && hasValidProjectType;

    // Badge: show in_progress for assigned freelancer when offer accepted but status not yet updated.
    String? statusBadgeOverride;
    if (isFreelancer && isAssignedToMe) {
      final ps = project.status.toLowerCase();
      if (ps == 'pending_admin_approval') {
        statusBadgeOverride = 'in_progress';
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background gradient layer (top glow only)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.25],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            child: ProjectDetailsScrollContent(
              project: project,
              imageUrl: imageUrl,
              durationText: durationText,
              statusBadgeOverride: statusBadgeOverride,
              headerTrailing: isFreelancerRole && isAssignedToMe
                  ? buildChangeRequestsIconWithUnread(project.id)
                  : isAdminRole
                      ? buildMessagesIconWithUnread(project.id)
                      : null,
            ),
          ),
        ],
      ),
      bottomNavigationBar: buildBottomBar(
        context,
        isFreelancer,
        isBidding,
        shouldShowButton,
        buttonLabel,
      ),
    );
  }
}
