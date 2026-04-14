// ignore_for_file: invalid_use_of_protected_member — see project_details_build.mixin.dart

part of 'package:OrderzHouse/features/common/presentation/screens/project_details_screen.dart';

extension _ProjectDetailsFetchExtension on _ProjectDetailsScreenState {
  // Fetch deliveries if user is owner or assigned freelancer
  Future<void> fetchDeliveriesIfNeeded() async {
    final project = _project;
    if (project == null) return;

    // Check ownership and assignment
    final authState = ref.read(authStateProvider);
    final currentUserId = authState.user?.id;
    final isOwnerCheck =
        currentUserId != null && project.userId == currentUserId;

    // Check if assigned (need to check assignment data)
    bool isAssignedCheck = false;
    if (_assignment != null && currentUserId != null) {
      final assignmentFreelancerId = _assignment!['freelancer_id'] as int?;
      final assignmentStatus =
          (_assignment!['assignment_status'] ?? _assignment!['status'] ?? '')
              .toString()
              .toLowerCase();
      isAssignedCheck =
          assignmentFreelancerId == currentUserId &&
          [
            'active',
            'assigned',
            'accepted',
            'pending_admin_approval',
          ].contains(assignmentStatus);
    }

    if (!isOwnerCheck && !isAssignedCheck) {
      return;
    }

    // Prevent multiple simultaneous calls
    if (_isLoadingDeliveries) {
      return;
    }

    setState(() {
      _isLoadingDeliveries = true;
    });

    try {
      final repository = ref.read(projectsRepositoryProvider);
      final project = _project;
      if (project == null) return;
      final response = await repository.getProjectDeliveries(project.id);

      if (mounted && response.success && response.data != null) {
        final payload = response.data!;
        setState(() {
          _deliveries = payload.deliveries;
          _deliveriesAwaitingClientReview = payload.awaitingClientReview;
          _isLoadingDeliveries = false;
        });
      } else if (mounted) {
        setState(() {
          _deliveriesAwaitingClientReview = false;
          _isLoadingDeliveries = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDeliveries = false;
        });
      }
    }
  }

  // Fetch assignment details (ONLY for freelancers)
  Future<void> fetchAssignment() async {
    final project = _currentProject;
    if (project == null) return;

    // Double-check: only fetch for freelancers
    if (!isFreelancerRole) {
      setState(() {
        _assignment = null;
        _isLoadingAssignment = false;
      });
      await fetchDeliveriesIfNeeded();
      return;
    }

    try {
      final repository = ref.read(projectsRepositoryProvider);
      final response = await repository.getMyAssignment(project.id);

      if (mounted) {
        setState(() {
          _assignment = response.data;
          _isLoadingAssignment = false;
        });

        // Fetch deliveries after assignment is loaded
        await fetchDeliveriesIfNeeded();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _assignment = null;
          _isLoadingAssignment = false;
        });

        // Still try to fetch deliveries (might be owner)
        await fetchDeliveriesIfNeeded();
      }
    }
  }

  // Compute visibility booleans
  bool get isFreelancerRole {
    final authState = ref.read(authStateProvider);
    return authState.user?.roleId == 3; // FREELANCER_ROLE_ID
  }

  bool get isAdminRole {
    final authState = ref.read(authStateProvider);
    return authState.user?.roleId == 1; // ADMIN_ROLE_ID
  }

  /// Same idea as backend chat participants: project owner, or freelancer assigned / who applied.
  bool canOpenProjectMessagesFor(Project project) {
    final uid = ref.read(authStateProvider).user?.id;
    if (uid == null) return false;
    if (project.userId == uid) return true;
    if (isFreelancerRole && (isAssignedToMe || _hasApplied)) return true;
    return false;
  }

  bool get isAssignedToMe {
    if (_assignment == null) return false;
    final authState = ref.read(authStateProvider);
    final currentUserId = authState.user?.id;
    if (currentUserId == null) return false;

    final assignmentFreelancerId = _assignment!['freelancer_id'] as int?;
    final assignmentStatus =
        (_assignment!['assignment_status'] ?? _assignment!['status'] ?? '')
            .toString()
            .toLowerCase();

    final isMyAssignment = assignmentFreelancerId == currentUserId;
    final isActiveStatus = [
      'active',
      'assigned',
      'accepted',
      'pending_admin_approval',
    ].contains(assignmentStatus);

    return isMyAssignment && isActiveStatus;
  }

  // Fetch raw project data for additional fields
  Future<void> fetchRawProjectData() async {
    final project = _project;
    if (project == null) return;

    try {
      final repository = ref.read(projectsRepositoryProvider);
      final response = await repository.getMyProjectsRaw();

      if (response.success && response.data != null) {
        final projectData = response.data!.firstWhere(
          (p) => (p['id'] as int?) == project.id,
          orElse: () => {},
        );
        if (projectData.isNotEmpty) {
          setState(() {
            final incoming = Map<String, dynamic>.from(projectData);
            final prev = _projectData;
            // "My projects" list can lag behind; don't downgrade after formal delivery.
            if (prev != null) {
              for (final key in ['status', 'completion_status']) {
                final inc =
                    (incoming[key] ?? '').toString().toLowerCase();
                final pr = (prev[key] ?? '').toString().toLowerCase();
                if (pr == 'pending_review' && inc != 'pending_review') {
                  incoming[key] = prev[key];
                }
              }
            }
            _projectData = incoming;
          });
        }
      }
    } catch (e) {
      // Silently fail
    }
  }

  // Fetch offers for a project (client)
  Future<void> fetchOffers() async {
    final project = _project;
    if (project == null) return;
    try {
      final repository = ref.read(projectsRepositoryProvider);
      final response = await repository.getProjectOffers(project.id);

      if (response.success && response.data != null) {
        setState(() {
          _offers = response.data!;
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  // Fetch applications for a project (client)
  Future<void> fetchApplications() async {
    try {
      final repository = ref.read(projectsRepositoryProvider);
      final project = _project;
      if (project == null) return;
      final response = await repository.getProjectApplications(project.id);

      if (response.success && response.data != null) {
        setState(() {
          _applications = response.data!;
        });
      }
    } catch (e) {
      // Silently fail
    }
  }
}
