part of 'package:OrderzHouse/features/common/presentation/screens/project_details_screen.dart';

extension _ProjectDetailsInitExtension on _ProjectDetailsScreenState {
  /// Called from [_ProjectDetailsScreenState.initState] after [State.initState].
  void projectDetailsHandleInitState() {
    // If project is provided, use it immediately
    if (widget.project != null) {
      _currentProject = widget.project;
      initializeWithProject();
    }
    // If only projectId is provided, we'll fetch in build method using provider
  }

  /// Called from [_ProjectDetailsScreenState.didChangeDependencies].
  void projectDetailsHandleDidChangeDependencies() {
    // Note: Project initialization is now handled in the build method
    // when the project loads from the provider. This ensures reactive updates.
  }

  void initializeWithProject() {
    final project = _project;
    if (project == null) return;

    // Prevent double initialization
    if (_projectInitialized) {
      if (AppConfig.isDevelopment) {
        debugPrint(
          '⚠️ [ProjectDetails] initializeWithProject() called but already initialized, skipping',
        );
      }
      return;
    }
    _projectInitialized = true;

    if (AppConfig.isDevelopment) {
      debugPrint(
        '✅ [ProjectDetails] initializeWithProject() called for project ${project.id}',
      );
    }

    // Get user role reactively to determine what to fetch
    final authState = ref.read(authStateProvider);
    final userRoleId = authState.user?.roleId;
    final isFreelancerRole = userRoleId == 3;

    checkIfApplied();
    fetchRawProjectData();

    // Only fetch assignment for freelancers (clients don't need it)
    if (isFreelancerRole) {
      fetchAssignment(); // This will call fetchDeliveriesIfNeeded() after assignment loads
    } else {
      // For clients, skip assignment fetch entirely
      _isLoadingAssignment = false;
      // Fetch deliveries if we're the owner (to show Receive button state)
      final currentUserId = authState.user?.id;
      if (currentUserId != null && project.userId == currentUserId) {
        fetchDeliveriesIfNeeded();
      } else {
        _isLoadingDeliveries = false;
      }
    }

    // Handle deep-link parameters after first frame
    if (widget.openApplicants ||
        widget.openReceiveModal ||
        widget.showDeliveries) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleDeepLinkNavigation();
      });
    }
  }

  /// Handle deep-link navigation from notifications
  void handleDeepLinkNavigation() {
    if (_deepLinkHandled) return;
    _deepLinkHandled = true;

    // Delay to ensure data is loaded
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      if (widget.openApplicants) {
        openApplicantsSheetDeepLink();
      } else if (widget.openReceiveModal) {
        openReceiveModalDeepLink();
      } else if (widget.showDeliveries) {
        openDeliveriesSheetDeepLink();
      }
    });
  }

  /// Open applicants bottom sheet (for clients) - deep-link version
  void openApplicantsSheetDeepLink() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final project = _project;
        if (project == null) return const SizedBox.shrink();
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setSheetState) => ApplicationsBottomSheet(
            project: project,
            applications: _applications,
            isLoading: _isLoading,
            isSubmitting: isSubmitting,
            onClose: () => Navigator.pop(context),
            onAction: (assignmentId, projectId, action) async {
              setSheetState(() => isSubmitting = true);
              try {
                final repository = ref.read(projectsRepositoryProvider);
                await repository.acceptRejectApplication(
                  assignmentId,
                  projectId,
                  action,
                );
                if (!mounted || !sheetContext.mounted) return;
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Application ${action == 'accept' ? 'accepted' : 'rejected'}',
                    ),
                  ),
                );
                await fetchRawProjectData();
                ref.invalidate(myProjectsProvider);
              } catch (e) {
                setSheetState(() => isSubmitting = false);
                if (mounted) {
                  ScaffoldMessenger.of(
                    this.context,
                  ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              }
            },
          ),
        );
      },
    );
  }

  /// Open receive modal (for clients to review deliveries) - deep-link version
  void openReceiveModalDeepLink() {
    if (!mounted) return;

    if (_deliveries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No deliveries to review yet')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final project = _project;
        if (project == null) return const SizedBox.shrink();
        return ReviewDeliveryBottomSheet(
          project: project,
          deliveries: _deliveries,
          isLoading: _isLoadingDeliveries,
          onClose: () => Navigator.pop(sheetContext),
          onApprove: (projectId) async {
            final repository = ref.read(projectsRepositoryProvider);
            await repository.approveDelivery(projectId);
            if (!mounted || !sheetContext.mounted) return;
            Navigator.pop(sheetContext);
            ScaffoldMessenger.of(
              sheetContext,
            ).showSnackBar(const SnackBar(content: Text('Delivery approved!')));
            await fetchRawProjectData();
            await fetchDeliveriesIfNeeded();
            // Invalidate providers
            ref.invalidate(myProjectsProvider);
          },
          onRequestChanges: (projectId, message) async {
            final repository = ref.read(projectsRepositoryProvider);
            await repository.requestChanges(projectId, message);
            if (!mounted || !sheetContext.mounted) return;
            Navigator.pop(sheetContext);
            ScaffoldMessenger.of(
              sheetContext,
            ).showSnackBar(const SnackBar(content: Text('Changes requested')));
            await fetchDeliveriesIfNeeded();
          },
          onRefresh: () {
            fetchDeliveriesIfNeeded();
          },
        );
      },
    );
  }

  /// Open deliveries sheet (for freelancers to see change requests) - deep-link version
  void openDeliveriesSheetDeepLink() {
    if (!mounted) return;

    // Build change requests from deliveries that have changes_requested status
    final changeRequests = _deliveries
        .where(
          (d) =>
              (d['status'] ?? '').toString().toLowerCase() ==
              'changes_requested',
        )
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ChangeRequestsBottomSheet(
        requests: changeRequests,
        isLoading: _isLoadingDeliveries,
      ),
    );
  }
}
