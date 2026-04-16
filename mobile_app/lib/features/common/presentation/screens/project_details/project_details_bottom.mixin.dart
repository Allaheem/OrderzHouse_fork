part of 'package:OrderzHouse/features/common/presentation/screens/project_details_screen.dart';

extension _ProjectDetailsBottomExtension on _ProjectDetailsScreenState {
  // Build bottom bar (Actions or Apply/Send Offer CTA). Always visible; disabled + spinner while loading (no flicker).
  Widget buildBottomBar(
    BuildContext context,
    bool isFreelancer,
    bool isBidding,
    bool shouldShowButton,
    String? buttonLabel,
  ) {
    final project = _project;
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.user;
    final currentUserId = currentUser?.id;
    final userRoleId = currentUser?.roleId;
    final isClientRole = userRoleId == 2;
    final isFreelancerRole = userRoleId == 3;
    final isOwner =
        project != null &&
        currentUserId != null &&
        project.userId == currentUserId;

    // Single flag: show same bar disabled + small spinner until data ready
    final isLoadingActions =
        (project == null) ||
        (currentUserId == null || userRoleId == null) ||
        (isFreelancerRole && _isLoadingAssignment) ||
        (isClientRole && isOwner && _isLoadingDeliveries);

    // Always show a bar (no flicker). Skeleton when project/user not ready.
    if (project == null || currentUserId == null || userRoleId == null) {
      return buildSkeletonBar(context, loading: true);
    }

    // Compute assignment status (only for freelancers)
    bool isAssignedToMe = false;
    bool isAssignedToSomeone = false;
    if (isFreelancerRole && _assignment != null) {
      final assignmentFreelancerId = _assignment!['freelancer_id'] as int?;
      final assignmentStatus =
          (_assignment!['assignment_status'] ?? _assignment!['status'] ?? '')
              .toString()
              .toLowerCase();
      isAssignedToMe =
          assignmentFreelancerId == currentUserId &&
          [
            'active',
            'assigned',
            'accepted',
            'pending_admin_approval',
          ].contains(assignmentStatus);
      isAssignedToSomeone = [
        'active',
        'assigned',
        'accepted',
        'pending_admin_approval',
      ].contains(assignmentStatus);
    }

    // Compute project status
    final projectStatus = project.status.toLowerCase();
    final completionStatus =
        (_projectData?['completion_status'] ?? project.status ?? '')
            .toString()
            .toLowerCase();
    var statusKey = completionStatus.isNotEmpty
        ? completionStatus
        : projectStatus;
    // Bidding: client accepted offer but DB/API may still say pending_admin — freelancer should work.
    if (isFreelancerRole &&
        isAssignedToMe &&
        (statusKey == 'pending_admin_approval' ||
            projectStatus == 'pending_admin_approval')) {
      statusKey = 'in_progress';
    }
    final isProjectCompleted =
        projectStatus == 'completed' || completionStatus == 'completed';

    // Show Client Action Bar (Receive + Applicants) for client-owned projects
    if (isClientRole && isOwner) {
      return buildClientActionBar(
        context,
        isProjectCompleted,
        loading: isLoadingActions,
      );
    }

    // Apply created a `project_assignments` row (pending_client_approval) but
    // work/delivery is only after client accepts — avoid greyed "Apply" with no deliver CTA.
    if (isFreelancerRole && !isOwner && isFreelancerAssignmentAwaitingConfirmation) {
      return buildFreelancerAwaitingConfirmationBar(
        context,
        loading: isLoadingActions,
      );
    }

    // Show Freelancer Actions (Deliver or Waiting status) if assigned
    if (isFreelancerRole && !isOwner && isAssignedToMe) {
      return buildFreelancerActionsBottomBar(
        context,
        statusKey,
        loading: isLoadingActions,
      );
    }

    // Show Apply/Send Offer CTA if applicable (not owner, not assigned)
    if (isFreelancerRole &&
        !isOwner &&
        !isAssignedToMe &&
        !isAssignedToSomeone) {
      final isOpen = [
        'open',
        'active',
        'pending',
        'in_progress',
        'bidding',
      ].contains(projectStatus);
      if (isOpen) {
        final label = isBidding ? 'Send Offer' : 'Apply';
        return SafeArea(
          top: false,
          bottom: true,
          child: ProjectDetailsFreelancerCtaBar(
            label: label,
            isBidding: isBidding,
            requestLoading: isLoadingActions,
            hasApplied: _hasApplied,
            isLoading: _isLoading,
            isCheckingApplied: _isCheckingApplied,
            onSendOffer: showSendOfferModal,
            onApply: handleApply,
          ),
        );
      }
    }

    return buildSkeletonBar(context, loading: false);
  }

  /// Skeleton bar: same container/height; when loading shows disabled buttons + small spinner.
  Widget buildSkeletonBar(BuildContext context, {required bool loading}) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: loading
            ? Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.people_outline_rounded, size: 20),
                      label: Text(AppLocalizations.of(context)!.applicants),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryGradientButton(
                      onPressed: null,
                      label: AppLocalizations.of(context)!.receive,
                      icon: Icons.download_rounded,
                      height: 48,
                      borderRadius: 12,
                      width: double.infinity,
                      isEnabled: false,
                      isLoading: true,
                    ),
                  ),
                ],
              )
            : const SizedBox(height: 48),
      ),
    );
  }

  // Build Client Action Bar (Receive + Applicants OR Files + Request Changes)
  Widget buildClientActionBar(
    BuildContext context,
    bool isProjectCompleted, {
    bool loading = false,
  }) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: isProjectCompleted
            ? buildCompletedActionsRow(context, loading: loading)
            : buildActiveActionsRow(context, loading: loading),
      ),
    );
  }

  // Build Active Actions Row (Offers for bidding / Applicants for fixed-hourly + Receive) - for in-progress projects
  Widget buildActiveActionsRow(BuildContext context, {bool loading = false}) {
    final isBidding =
        (_project?.projectType ?? '').toString().toLowerCase() == 'bidding';
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: loading
                ? null
                : () => isBidding
                      ? openOffers(context)
                      : openApplications(context),
            icon: const Icon(Icons.people_outline_rounded, size: 20),
            label: Text(isBidding ? l10n.offers : l10n.applicants),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PrimaryGradientButton(
            onPressed: loading ? null : () => openReceivePanel(context),
            label: AppLocalizations.of(context)!.receive,
            icon: Icons.download_rounded,
            height: 48,
            borderRadius: 12,
            width: double.infinity,
            isEnabled: !loading,
            isLoading: loading,
          ),
        ),
      ],
    );
  }

  // Build Completed Actions Row (Request Changes + Files) - for completed projects
  Widget buildCompletedActionsRow(
    BuildContext context, {
    bool loading = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: loading ? null : () => openRequestChangesModal(context),
            icon: const Icon(Icons.edit_rounded, size: 20),
            label: Text(AppLocalizations.of(context)!.requestChanges),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PrimaryGradientButton(
            onPressed: loading ? null : () => openFilesView(context),
            label: AppLocalizations.of(context)!.files,
            icon: Icons.folder_outlined,
            height: 52,
            borderRadius: 28,
            width: double.infinity,
            isEnabled: !loading,
            isLoading: loading,
          ),
        ),
      ],
    );
  }

  /// Application sent or invite not yet accepted — not the same as "assigned to work".
  Widget buildFreelancerAwaitingConfirmationBar(
    BuildContext context, {
    required bool loading,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final status = (_assignment?['assignment_status'] ?? _assignment?['status'] ?? '')
        .toString()
        .toLowerCase();
    final isInvite = status == 'pending_acceptance';
    final title = isInvite
        ? l10n.freelancerInvitePendingAcceptTitle
        : l10n.freelancerApplicationWaitingClientTitle;
    final body = isInvite
        ? l10n.freelancerInvitePendingAcceptBody
        : l10n.freelancerApplicationWaitingClientBody;

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: loading
            ? const SizedBox(
                height: 48,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.hourglass_top_rounded,
                          color: Color(0xFFF59E0B),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: const Color(0xFFB45309),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      body,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF92400E),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // Build Freelancer Actions Bottom Bar (Deliver or Waiting status)
  Widget buildFreelancerActionsBottomBar(
    BuildContext context,
    String statusKey, {
    bool loading = false,
  }) {
    final project = _project;
    if (project == null) return buildSkeletonBar(context, loading: true);

    final shouldShowDeliver = [
      'in_progress',
      'not_started',
    ].contains(statusKey);
    final shouldShowWaiting =
        statusKey == 'pending_review' ||
        (_pendingLocal && statusKey != 'completed');

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: shouldShowDeliver
            ? GradientButton(
                onPressed: loading ? null : () => openDeliverModal(context),
                label: AppLocalizations.of(context)!.submitDelivery,
                icon: Icons.send_rounded,
                height: 48,
                borderRadius: 12,
                isEnabled: !loading,
                isLoading: loading,
              )
            : shouldShowWaiting
            ? Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.hourglass_empty_rounded,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Waiting for client review',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: const Color(0xFFF59E0B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : statusKey == 'completed'
            ? Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Approved ✅',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
