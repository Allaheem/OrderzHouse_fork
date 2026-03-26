// ??? ????????
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/project.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../offers/presentation/providers/offers_provider.dart';
import '../../../freelancer/presentation/widgets/change_requests_bottom_sheet.dart';
import '../../../freelancer/presentation/widgets/deliver_modal.dart';
import '../../../client/presentation/widgets/review_delivery_bottom_sheet.dart';
import '../../../client/presentation/widgets/offers_bottom_sheet.dart';
import '../../../client/presentation/widgets/applications_bottom_sheet.dart';
import '../../../messages/presentation/providers/messages_provider.dart';
import '../../../projects/presentation/providers/change_requests_provider.dart';
import '../../../../l10n/app_localizations.dart';

class ProjectDetailsScreen extends ConsumerStatefulWidget {
  final Project? project;
  final int? projectId; // For fetching when project is not provided

  /// Deep-link parameters for notification navigation
  final bool openApplicants;
  final bool openReceiveModal;
  final bool showDeliveries;

  const ProjectDetailsScreen({
    this.project,
    this.projectId,
    this.openApplicants = false,
    this.openReceiveModal = false,
    this.showDeliveries = false,
    super.key,
  }) : assert(
         project != null || projectId != null,
         'Either project or projectId must be provided',
       );

  @override
  ConsumerState<ProjectDetailsScreen> createState() =>
      _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends ConsumerState<ProjectDetailsScreen> {
  Project? _currentProject;

  bool _hasApplied = false;
  bool _isLoading = false;
  bool _isCheckingApplied = true;

  // Store raw project data for additional fields
  Map<String, dynamic>? _projectData;

  // Assignment data
  Map<String, dynamic>? _assignment;
  bool _isLoadingAssignment = true;

  // Local state for pending deliveries (freelancer)
  bool _pendingLocal = false;

  // Store offers and applications data (client)
  List<Map<String, dynamic>> _offers = [];
  List<Map<String, dynamic>> _applications = [];

  // Deliveries data
  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoadingDeliveries = false;

  // Flag to track if deep-link actions have been handled
  bool _deepLinkHandled = false;

  // Flag to track if project has been initialized (prevents double initialization)
  bool _projectInitialized = false;

  Project? get _project => _currentProject ?? widget.project;

  @override
  void initState() {
    super.initState();

    // If project is provided, use it immediately
    if (widget.project != null) {
      _currentProject = widget.project;
      _initializeWithProject();
    }
    // If only projectId is provided, we'll fetch in build method using provider
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Note: Project initialization is now handled in the build method
    // when the project loads from the provider. This ensures reactive updates.
  }

  void _initializeWithProject() {
    final project = _project;
    if (project == null) return;

    // Prevent double initialization
    if (_projectInitialized) {
      if (AppConfig.isDevelopment) {
        debugPrint(
          '⚠️ [ProjectDetails] _initializeWithProject() called but already initialized, skipping',
        );
      }
      return;
    }
    _projectInitialized = true;

    if (AppConfig.isDevelopment) {
      debugPrint(
        '✅ [ProjectDetails] _initializeWithProject() called for project ${project.id}',
      );
    }

    // Get user role reactively to determine what to fetch
    final authState = ref.read(authStateProvider);
    final userRoleId = authState.user?.roleId;
    final isFreelancerRole = userRoleId == 3;

    _checkIfApplied();
    _fetchRawProjectData();

    // Only fetch assignment for freelancers (clients don't need it)
    if (isFreelancerRole) {
      _fetchAssignment(); // This will call _fetchDeliveriesIfNeeded() after assignment loads
    } else {
      // For clients, skip assignment fetch entirely
      _isLoadingAssignment = false;
      // Fetch deliveries if we're the owner (to show Receive button state)
      final currentUserId = authState.user?.id;
      if (currentUserId != null && project.userId == currentUserId) {
        _fetchDeliveriesIfNeeded();
      } else {
        _isLoadingDeliveries = false;
      }
    }

    // Handle deep-link parameters after first frame
    if (widget.openApplicants ||
        widget.openReceiveModal ||
        widget.showDeliveries) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleDeepLinkNavigation();
      });
    }
  }

  /// Handle deep-link navigation from notifications
  void _handleDeepLinkNavigation() {
    if (_deepLinkHandled) return;
    _deepLinkHandled = true;

    // Delay to ensure data is loaded
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      if (widget.openApplicants) {
        _openApplicantsSheetDeepLink();
      } else if (widget.openReceiveModal) {
        _openReceiveModalDeepLink();
      } else if (widget.showDeliveries) {
        _openDeliveriesSheetDeepLink();
      }
    });
  }

  /// Open applicants bottom sheet (for clients) - deep-link version
  void _openApplicantsSheetDeepLink() {
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
                await _fetchRawProjectData();
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
  void _openReceiveModalDeepLink() {
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
            await _fetchRawProjectData();
            await _fetchDeliveriesIfNeeded();
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
            await _fetchDeliveriesIfNeeded();
          },
          onRefresh: () {
            _fetchDeliveriesIfNeeded();
          },
        );
      },
    );
  }

  /// Open deliveries sheet (for freelancers to see change requests) - deep-link version
  void _openDeliveriesSheetDeepLink() {
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

  // Fetch deliveries if user is owner or assigned freelancer
  Future<void> _fetchDeliveriesIfNeeded() async {
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
          ['active', 'assigned', 'accepted'].contains(assignmentStatus);
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
        setState(() {
          _deliveries = response.data!;
          _isLoadingDeliveries = false;
        });
      } else if (mounted) {
        setState(() {
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
  Future<void> _fetchAssignment() async {
    final project = _currentProject;
    if (project == null) return;

    // Double-check: only fetch for freelancers
    if (!_isFreelancerRole) {
      setState(() {
        _assignment = null;
        _isLoadingAssignment = false;
      });
      await _fetchDeliveriesIfNeeded();
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
        await _fetchDeliveriesIfNeeded();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _assignment = null;
          _isLoadingAssignment = false;
        });

        // Still try to fetch deliveries (might be owner)
        await _fetchDeliveriesIfNeeded();
      }
    }
  }

  // Compute visibility booleans
  bool get _isFreelancerRole {
    final authState = ref.read(authStateProvider);
    return authState.user?.roleId == 3; // FREELANCER_ROLE_ID
  }

  bool get _isAdminRole {
    final authState = ref.read(authStateProvider);
    return authState.user?.roleId == 1; // ADMIN_ROLE_ID
  }

  bool get _isAssignedToMe {
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
    ].contains(assignmentStatus);

    return isMyAssignment && isActiveStatus;
  }

  // Fetch raw project data for additional fields
  Future<void> _fetchRawProjectData() async {
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
            _projectData = projectData;
          });
        }
      }
    } catch (e) {
      // Silently fail
    }
  }

  // Fetch offers for a project (client)
  Future<void> _fetchOffers() async {
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
  Future<void> _fetchApplications() async {
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

  Future<void> _checkIfApplied() async {
    final authState = ref.read(authStateProvider);
    final user = authState.user;
    final isFreelancer = user?.roleId == 3;

    if (!isFreelancer) {
      setState(() => _isCheckingApplied = false);
      return;
    }

    final project = _project;
    if (project == null) return;
    final projectTypeLower = project.projectType.toLowerCase();
    final isBidding = projectTypeLower == 'bidding';

    try {
      if (isBidding) {
        // Check pending offer
        final offersRepo = ref.read(offersRepositoryProvider);
        final response = await offersRepo.checkMyPendingOffer(project.id);
        if (mounted) {
          setState(() {
            _hasApplied = response.data ?? false;
            _isCheckingApplied = false;
          });
        }
      } else {
        // Check assignment
        final projectsRepo = ref.read(projectsRepositoryProvider);
        final response = await projectsRepo.checkIfAssigned(project.id);
        if (mounted) {
          setState(() {
            _hasApplied = response.data ?? false;
            _isCheckingApplied = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasApplied = false;
          _isCheckingApplied = false;
        });
      }
    }
  }

  Future<void> _handleSendOffer(double bidAmount, String? proposal) async {
    if (_isLoading) return;
    final project = _project;
    if (project == null) return;

    setState(() => _isLoading = true);

    try {
      final offersRepo = ref.read(offersRepositoryProvider);
      final response = await offersRepo.sendOffer(
        projectId: project.id,
        bidAmount: bidAmount,
        proposal: proposal,
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (response.success) {
        setState(() {
          _hasApplied = true;
          _isLoading = false;
        });

        // Refresh assignment after sending offer
        await _fetchAssignment();
        if (!mounted) return;

        messenger.showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Offer sent successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to send offer'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final messenger = ScaffoldMessenger.of(context);
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to send offer: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleApply() async {
    if (_isLoading) return;
    final project = _project;
    if (project == null) return;

    setState(() => _isLoading = true);

    try {
      final projectsRepo = ref.read(projectsRepositoryProvider);
      final response = await projectsRepo.applyForProject(
        projectId: project.id,
        message: null,
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (response.success) {
        setState(() {
          _hasApplied = true;
          _isLoading = false;
        });

        // Refresh assignment after applying
        await _fetchAssignment();
        if (!mounted) return;

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              response.message ?? 'Application submitted successfully',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to apply to project'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final messenger = ScaffoldMessenger.of(context);
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to apply: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showSendOfferModal() {
    final bidAmountController = TextEditingController();
    final proposalController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Send Offer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: bidAmountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Bid Amount (JOD)',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bid amount is required';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Bid amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: proposalController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Proposal (Optional)',
                  hintText: 'Add a message to your offer...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (formKey.currentState!.validate()) {
                          final bidAmount = double.parse(
                            bidAmountController.text,
                          );
                          final proposal =
                              proposalController.text.trim().isEmpty
                              ? null
                              : proposalController.text.trim();
                          Navigator.pop(context);
                          _handleSendOffer(bidAmount, proposal);
                        }
                      },
                label: 'Send Offer',
                isLoading: _isLoading,
                height: 54,
                borderRadius: 18,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                _initializeWithProject();
              }
            });
          }
          // Return normal build with project
          return _buildProjectContent(context, project);
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
    return _buildProjectContent(context, _project!);
  }

  /// Messages icon (chat bubble) with red dot when unread. Same UI; dot visibility from projectUnreadProvider.
  Widget _buildMessagesIconWithUnread(int projectId) {
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
  Widget _buildChangeRequestsIconWithUnread(int projectId) {
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

  Widget _buildProjectContent(BuildContext context, Project project) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final statusColor = _getStatusColor(project.status);

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
          // Content layer
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            color: AppColors.primary, // Coral-red
                            onPressed: () {
                              // Safe back navigation
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                // Fallback: navigate to explore/home
                                context.go('/client/explore');
                              }
                            },
                          ),
                        ),
                        const Spacer(),
                        // Title
                        Text(
                          AppLocalizations.of(context)!.projectDetails,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const Spacer(),
                        // Change Requests (freelancer) or Messages (admin) icon; red dot when unread
                        if (_isFreelancerRole && _isAssignedToMe)
                          _buildChangeRequestsIconWithUnread(project.id)
                        else if (_isAdminRole)
                          _buildMessagesIconWithUnread(project.id),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Hero Image
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Image or placeholder
                        Container(
                          width: double.infinity,
                          height: 240,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: double.infinity,
                                  height: 240,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.primary.withValues(
                                            alpha: 0.8,
                                          ),
                                          AppColors.primary.withValues(
                                            alpha: 0.6,
                                          ),
                                        ],
                                      ),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      _buildImagePlaceholder(),
                                )
                              : _buildImagePlaceholder(),
                        ),
                        // Status chip overlay (bottom-left)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              project.status.toUpperCase(),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Title + Price row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title (left, flexible)
                      Expanded(
                        child: Text(
                          project.title,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: const Color(0xFF111827),
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Price badge (right)
                      if (project.budgetDisplay != 'Negotiable')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            project.budgetDisplay,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 5),

                // Project type + Created date row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          project.projectType.toUpperCase(),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          dateFormat.format(project.createdAt),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Info Grid (2x2)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.5,
                    children: [
                      _buildInfoCard(
                        icon: Icons.category_rounded,
                        label: AppLocalizations.of(context)!.projectType,
                        value: project.projectType.toUpperCase(),
                      ),
                      _buildInfoCard(
                        icon: Icons.account_balance_wallet_rounded,
                        label: AppLocalizations.of(context)!.projectBudget,
                        value: project.budgetDisplay,
                      ),
                      _buildInfoCard(
                        icon: Icons.schedule_rounded,
                        label: AppLocalizations.of(context)!.estimatedDuration,
                        value: durationText,
                      ),
                      _buildInfoCard(
                        icon: Icons.calendar_today_rounded,
                        label: AppLocalizations.of(context)!.startDate,
                        value: dateFormat.format(project.createdAt),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Description Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.description_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                AppLocalizations.of(context)!.description,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: const Color(0xFF111827),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          project.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: const Color(0xFF374151),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Add bottom padding to prevent content from being hidden under bottom bar
                SizedBox(
                  height:
                      MediaQuery.of(context).padding.bottom +
                      80, // Space for bottom bar
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(
        context,
        isFreelancer,
        isBidding,
        shouldShowButton,
        buttonLabel,
      ),
    );
  }

  // Build bottom bar (Actions or Apply/Send Offer CTA). Always visible; disabled + spinner while loading (no flicker).
  Widget _buildBottomBar(
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
      return _buildSkeletonBar(context, loading: true);
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
          ['active', 'assigned', 'accepted'].contains(assignmentStatus);
      isAssignedToSomeone = [
        'active',
        'assigned',
        'accepted',
      ].contains(assignmentStatus);
    }

    // Compute project status
    final projectStatus = project.status.toLowerCase();
    final completionStatus =
        (_projectData?['completion_status'] ?? project.status ?? '')
            .toString()
            .toLowerCase();
    final statusKey = completionStatus.isNotEmpty
        ? completionStatus
        : projectStatus;
    final isProjectCompleted =
        projectStatus == 'completed' || completionStatus == 'completed';

    // Debug logs
    if (AppConfig.isDevelopment) {
      debugPrint('🔍 [ProjectDetails] Bottom Bar Visibility (REACTIVE):');
      debugPrint('  currentUserId: $currentUserId');
      debugPrint(
        '  userRoleId: $userRoleId (${isClientRole
            ? "CLIENT"
            : isFreelancerRole
            ? "FREELANCER"
            : "OTHER"})',
      );
      debugPrint('  project.userId: ${project.userId}');
      debugPrint('  project.status: $projectStatus');
      debugPrint('  isOwner: $isOwner');
      debugPrint('  isClientRole: $isClientRole');
      debugPrint('  isFreelancerRole: $isFreelancerRole');
      debugPrint('  isAssignedToMe: $isAssignedToMe');
      debugPrint('  isAssignedToSomeone: $isAssignedToSomeone');
      debugPrint('  statusKey: $statusKey');
      debugPrint('  deliveries.length: ${_deliveries.length}');
      debugPrint('  isProjectCompleted: $isProjectCompleted');
      debugPrint('  _isLoadingAssignment: $_isLoadingAssignment');
      debugPrint('  _isLoadingDeliveries: $_isLoadingDeliveries');
      debugPrint('  isLoadingActions: $isLoadingActions');
      debugPrint('  _projectInitialized: $_projectInitialized');
    }

    // Show Client Action Bar (Receive + Applicants) for client-owned projects
    if (isClientRole && isOwner) {
      if (AppConfig.isDevelopment) {
        debugPrint('✅ [ProjectDetails] Showing Client Action Bar');
      }
      return _buildClientActionBar(
        context,
        isProjectCompleted,
        loading: isLoadingActions,
      );
    }

    // Show Freelancer Actions (Deliver or Waiting status) if assigned
    if (isFreelancerRole && !isOwner && isAssignedToMe) {
      if (AppConfig.isDevelopment) {
        debugPrint('✅ [ProjectDetails] Showing Freelancer Actions');
      }
      return _buildFreelancerActionsBottomBar(
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
        if (AppConfig.isDevelopment) {
          debugPrint('✅ [ProjectDetails] Showing Apply/Send Offer CTA');
        }
        final label = isBidding ? 'Send Offer' : 'Apply';
        return SafeArea(
          top: false,
          bottom: true,
          child: _buildBottomActionButton(
            context,
            label,
            isBidding,
            project.id,
            loading: isLoadingActions,
          ),
        );
      }
    }

    if (AppConfig.isDevelopment) {
      debugPrint(
        '❌ [ProjectDetails] No bottom bar shown (empty bar to avoid layout jump)',
      );
    }
    return _buildSkeletonBar(context, loading: false);
  }

  /// Skeleton bar: same container/height; when loading shows disabled buttons + small spinner.
  Widget _buildSkeletonBar(BuildContext context, {required bool loading}) {
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
  Widget _buildClientActionBar(
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
            ? _buildCompletedActionsRow(context, loading: loading)
            : _buildActiveActionsRow(context, loading: loading),
      ),
    );
  }

  // Build Active Actions Row (Offers for bidding / Applicants for fixed-hourly + Receive) - for in-progress projects
  Widget _buildActiveActionsRow(BuildContext context, {bool loading = false}) {
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
                      ? _openOffers(context)
                      : _openApplications(context),
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
            onPressed: loading ? null : () => _openReceivePanel(context),
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
  Widget _buildCompletedActionsRow(
    BuildContext context, {
    bool loading = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: loading ? null : () => _openRequestChangesModal(context),
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
            onPressed: loading ? null : () => _openFilesView(context),
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

  // Build Freelancer Actions Bottom Bar (Deliver or Waiting status)
  Widget _buildFreelancerActionsBottomBar(
    BuildContext context,
    String statusKey, {
    bool loading = false,
  }) {
    final project = _project;
    if (project == null) return _buildSkeletonBar(context, loading: true);

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
                onPressed: loading ? null : () => _openDeliverModal(context),
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

  // Open deliver modal (freelancer)
  Future<void> _openDeliverModal(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        final project = _project;
        if (project == null) return const SizedBox.shrink();
        return DeliverModal(
          project: project,
          onClose: () => Navigator.pop(context),
          onSubmit: (proj, filePaths) async {
            final repository = ref.read(projectsRepositoryProvider);
            final response = await repository.deliverProject(
              proj.id,
              filePaths,
            );

            if (!response.success) {
              throw Exception(response.message ?? 'Failed to deliver project');
            }

            // Update local state immediately
            setState(() {
              _pendingLocal = true;
              _projectData = {
                ...?_projectData,
                'completion_status': 'pending_review',
                'status': 'pending_review',
              };
            });

            // Refresh deliveries
            await _fetchDeliveriesIfNeeded();

            // Refresh projects list
            ref.invalidate(myProjectsProvider);
            await ref.read(myProjectsProvider.future);

            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delivery submitted successfully ✅'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          isSubmitting: false,
        );
      },
    );
  }

  // Handle Approve Delivery (client)
  Future<void> _handleApproveDelivery(BuildContext context) async {
    if (_isLoading) return;
    final project = _project;
    if (project == null) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(projectsRepositoryProvider);
      final response = await repository.approveDelivery(project.id);

      if (!response.success) {
        throw Exception(response.message ?? 'Failed to approve delivery');
      }

      // Update local state immediately
      setState(() {
        _projectData = {
          ...?_projectData,
          'completion_status': 'completed',
          'status': 'completed',
        };
        _isLoading = false;
      });

      // Refresh deliveries
      await _fetchDeliveriesIfNeeded();

      // Refresh projects list
      ref.invalidate(myProjectsProvider);
      await ref.read(myProjectsProvider.future);

      // Refresh raw project data
      await _fetchRawProjectData();

      if (context.mounted) {
        // Close the receive sheet if it's open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project approved and marked as completed ✅'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Force rebuild to show new buttons
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Open Request Changes Modal (client)
  Future<void> _openRequestChangesModal(BuildContext context) async {
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Request Changes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Message',
                  hintText: 'Describe what changes are needed...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Message is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(context);
                            await _handleRequestChanges(
                              context,
                              messageController.text.trim(),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Send Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Handle Request Changes (client)
  Future<void> _handleRequestChanges(
    BuildContext context,
    String message,
  ) async {
    if (_isLoading) return;
    final project = _project;
    if (project == null) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(projectsRepositoryProvider);
      final response = await repository.requestProjectChanges(
        projectId: project.id,
        message: message,
      );

      if (!response.success) {
        throw Exception(response.message ?? 'Failed to send change request');
      }

      // Update local state
      setState(() {
        _projectData = {
          ...?_projectData,
          'status': 'in_progress',
          'completion_status': 'in_progress',
        };
        _isLoading = false;
      });

      // Invalidate providers to refresh data
      ref.invalidate(changeRequestsProvider(project.id));
      ref.invalidate(projectByIdProvider(project.id));

      // Refresh deliveries
      await _fetchDeliveriesIfNeeded();

      // Refresh projects list (so badges update)
      ref.invalidate(myProjectsProvider);
      await ref.read(myProjectsProvider.future);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Change request sent successfully ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Open Files View (client) - read-only view of delivered files for completed projects
  Future<void> _openFilesView(BuildContext context) async {
    // Fetch deliveries first if not already loaded
    if (_deliveries.isEmpty) {
      await _fetchDeliveriesIfNeeded();
    }
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _buildFilesSheet(context),
    );
  }

  // Build Files Sheet UI (read-only, no actions)
  Widget _buildFilesSheet(BuildContext context) {
    final project = _project;
    if (project == null) return const SizedBox.shrink();
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Project Files — ${project.title}',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _deliveries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.folder_open_rounded,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No files available',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _deliveries.length,
                    itemBuilder: (context, index) {
                      final delivery = _deliveries[index];
                      return _buildDeliveryFileCard(delivery, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Build Delivery File Card
  Widget _buildDeliveryFileCard(Map<String, dynamic> delivery, int index) {
    final files = delivery['files'] as List<dynamic>? ?? [];
    final note = delivery['note'] as String? ?? '';
    final createdAt = delivery['created_at'];
    final status = delivery['status'] as String? ?? 'submitted';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Delivery #${index + 1}',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getHistoryColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _getHistoryColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (note.isNotEmpty) ...[
            Text(
              'Note:',
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(note, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
          ],
          if (files.isNotEmpty) ...[
            Text(
              'Files (${files.length}):',
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...files.map((file) => _buildFileItem(file)),
          ],
          const SizedBox(height: 8),
          Text(
            'Submitted: ${_formatDeliveryDate(createdAt)}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // Open Receive Panel (client) - new UI for viewing/approving deliveries
  Future<void> _openReceivePanel(BuildContext context) async {
    // Fetch deliveries first if not already loaded
    if (_deliveries.isEmpty) {
      await _fetchDeliveriesIfNeeded();
    }
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _buildReceiveSheet(context),
    );
  }

  // Build Receive Sheet UI
  Widget _buildReceiveSheet(BuildContext context) {
    final project = _project;
    if (project == null) return const SizedBox.shrink();
    final latestDelivery = _deliveries.isNotEmpty ? _deliveries.first : null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Receive Project — ${project.title}',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Latest Delivery Card
                  _buildLatestDeliveryCard(latestDelivery),

                  const SizedBox(height: 20),

                  // Actions Card
                  _buildActionsCard(latestDelivery),

                  const SizedBox(height: 20),

                  // History Card
                  _buildHistoryCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build Latest Delivery Card
  Widget _buildLatestDeliveryCard(Map<String, dynamic>? latestDelivery) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest delivery',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _fetchDeliveriesIfNeeded,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(AppLocalizations.of(context)!.refresh),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentOrange,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (latestDelivery == null)
            Text(
              AppLocalizations.of(context)!.noDeliveries,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            _buildDeliveryContent(latestDelivery),
        ],
      ),
    );
  }

  // Build Delivery Content
  Widget _buildDeliveryContent(Map<String, dynamic> delivery) {
    final files = delivery['files'] as List<dynamic>? ?? [];
    final note = delivery['note'] as String? ?? '';
    final createdAt = delivery['created_at'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (note.isNotEmpty) ...[
          Text(
            'Note:',
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(note, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 12),
        ],
        if (files.isNotEmpty) ...[
          Text(
            'Files:',
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...files.map((file) => _buildFileItem(file)),
        ],
        const SizedBox(height: 8),
        Text(
          'Submitted: ${_formatDeliveryDate(createdAt)}',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  // Build File Item
  Widget _buildFileItem(dynamic file) {
    final fileName = file is Map
        ? (file['filename'] ?? file['name'] ?? 'File')
        : file.toString();
    final fileUrl = file is Map
        ? (file['url'] ?? file['file_url'] ?? file['path'])
        : null;
    final fileSize = file is Map ? (file['size'] ?? file['size_bytes']) : null;

    // Check if URL is valid
    final hasValidUrl =
        fileUrl != null &&
        fileUrl.toString().isNotEmpty &&
        fileUrl.toString() != 'null' &&
        fileUrl.toString() != 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.insert_drive_file_rounded,
            color: AppColors.accentOrange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (fileSize != null)
                  Text(
                    _formatFileSize(fileSize),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.download_rounded,
              size: 20,
              color: hasValidUrl
                  ? AppColors.accentOrange
                  : AppColors.textTertiary,
            ),
            onPressed: hasValidUrl
                ? () => _downloadFile(fileUrl.toString(), fileName)
                : null,
            tooltip: hasValidUrl ? 'Download' : 'File not available',
          ),
        ],
      ),
    );
  }

  // Helper: Format file size
  String _formatFileSize(dynamic size) {
    try {
      final bytes = size is int ? size : int.tryParse(size.toString()) ?? 0;
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      if (bytes < 1024 * 1024 * 1024) {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } catch (e) {
      return '';
    }
  }

  // Build Actions Card
  Widget _buildActionsCard(Map<String, dynamic>? latestDelivery) {
    final hasDelivery = latestDelivery != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: hasDelivery
                        ? () {
                            Navigator.pop(context);
                            _openRequestChangesModal(context);
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(
                        color: hasDelivery
                            ? AppColors.border
                            : AppColors.borderLight,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Request changes'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: PrimaryGradientButton(
                    onPressed: hasDelivery
                        ? () async {
                            Navigator.pop(context);
                            await _handleApproveDelivery(context);
                          }
                        : null,
                    label: AppLocalizations.of(context)!.approve,
                    isEnabled: hasDelivery,
                    height: 48,
                    borderRadius: 12,
                    width: double.infinity,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build History Card
  Widget _buildHistoryCard() {
    final history = _deliveries.skip(1).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'History',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            Text(
              'No history yet.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...history.map((delivery) => _buildHistoryItem(delivery)),
        ],
      ),
    );
  }

  // Build History Item (with downloadable files)
  Widget _buildHistoryItem(Map<String, dynamic> delivery) {
    final status = delivery['status'] as String? ?? 'submitted';
    final createdAt = delivery['created_at'];
    final files = delivery['files'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getHistoryIcon(status),
                color: _getHistoryColor(status),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getHistoryTitle(status),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDeliveryDate(createdAt),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (files.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Files:',
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            ...files.map((file) => _buildFileItem(file)),
          ],
        ],
      ),
    );
  }

  // Helper: Download file with authorization (no permissions needed)
  Future<void> _downloadFile(String url, String fileName) async {
    // Validate URL
    if (url.isEmpty || url == 'N/A' || url == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No downloadable file available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show downloading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading: $fileName'),
          backgroundColor: AppColors.accentOrange,
          duration: const Duration(seconds: 2),
        ),
      );

      // Get app documents directory (no permissions needed on any platform)
      final directory = await getApplicationDocumentsDirectory();

      // Create OrderzHouse folder inside app documents
      final orderzHouseDir = Directory('${directory.path}/OrderzHouse');
      if (!orderzHouseDir.existsSync()) {
        orderzHouseDir.createSync(recursive: true);
      }

      final savePath = '${orderzHouseDir.path}/$fileName';

      final repository = ref.read(projectsRepositoryProvider);
      final downloadResult = await repository.downloadFile(
        url: url,
        savePath: savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            debugPrint('Download progress: $progress%');
          }
        },
      );
      if (!downloadResult.success) {
        throw Exception(downloadResult.message ?? 'File download failed');
      }

      // Verify file exists
      final file = File(savePath);
      if (!file.existsSync()) {
        throw Exception('File download failed');
      }

      // Print saved path to console
      debugPrint('✅ File saved to: $savePath');

      if (mounted) {
        // Show success message with full path
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Downloaded: $fileName',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Saved: $savePath',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () async {
                try {
                  final fileUri = Uri.file(savePath);
                  if (await canLaunchUrl(fileUri)) {
                    await launchUrl(fileUri);
                  } else {
                    debugPrint('Could not open file: $savePath');
                  }
                } catch (e) {
                  debugPrint('Error opening file: $e');
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Helper: Format delivery date
  String _formatDeliveryDate(dynamic date) {
    if (date == null) return 'Just now';
    try {
      DateTime dateTime;
      if (date is DateTime) {
        dateTime = date;
      } else if (date is String) {
        // Try multiple date formats
        try {
          dateTime = DateTime.parse(date);
        } catch (_) {
          // Try ISO format with timezone
          dateTime = DateFormat(
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
          ).parse(date, true).toLocal();
        }
      } else {
        return 'Just now';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        final minutes = difference.inMinutes;
        return '$minutes ${minutes == 1 ? "minute" : "minutes"} ago';
      } else if (difference.inHours < 24) {
        final hours = difference.inHours;
        return '$hours ${hours == 1 ? "hour" : "hours"} ago';
      } else if (difference.inDays < 7) {
        final days = difference.inDays;
        return '$days ${days == 1 ? "day" : "days"} ago';
      } else {
        return DateFormat('MMM dd, yyyy').format(dateTime);
      }
    } catch (e) {
      debugPrint('Date formatting error: $e for date: $date');
      return 'Recently';
    }
  }

  // Helper: Get history icon
  IconData _getHistoryIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        return Icons.check_circle_rounded;
      case 'changes_requested':
      case 'rejected':
        return Icons.edit_rounded;
      default:
        return Icons.upload_rounded;
    }
  }

  // Helper: Get history color
  Color _getHistoryColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        return Colors.green;
      case 'changes_requested':
      case 'rejected':
        return Colors.orange;
      default:
        return AppColors.accentOrange;
    }
  }

  // Helper: Get history title
  String _getHistoryTitle(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        return 'Delivery approved';
      case 'changes_requested':
      case 'rejected':
        return 'Changes requested';
      default:
        return 'Delivery submitted';
    }
  }

  // Open offers (client)
  Future<void> _openOffers(BuildContext context) async {
    if (_offers.isEmpty) {
      await _fetchOffers();
    }
    if (!context.mounted) return;

    bool isSubmitting = false;
    final offersNotifier = ValueNotifier<List<Map<String, dynamic>>>(
      List.from(_offers),
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final project = _project;
          if (project == null) return const SizedBox.shrink();
          return OffersBottomSheet(
            project: project,
            offersNotifier: offersNotifier,
            isLoading: false,
            isSubmitting: isSubmitting,
            onClose: () => Navigator.pop(context),
            onAction: (offerId, action) async {
              setModalState(() => isSubmitting = true);
              try {
                final repository = ref.read(projectsRepositoryProvider);
                final response = await repository.approveRejectOffer(
                  offerId,
                  action,
                );
                if (!response.success) {
                  throw Exception(
                    response.message ?? 'Failed to process offer',
                  );
                }
                final data = response.data;
                final pendingAdminApproval =
                    data?['pendingAdminApproval'] == true;
                final pid = data?['projectId'];
                final projectId = pid is int
                    ? pid
                    : (pid is num ? pid.toInt() : null);

                final newStatus = action == 'accept' ? 'accepted' : 'rejected';
                final updatedOffers = _offers.map((offer) {
                  final oid =
                      offer['id'] ?? offer['offer_id'] ?? offer['offerId'];
                  if (oid != null && oid.toString() == offerId.toString()) {
                    return {
                      ...offer,
                      'status': newStatus,
                      'offer_status': newStatus,
                    };
                  }
                  return offer;
                }).toList();
                setState(() {
                  _offers = updatedOffers;
                });
                offersNotifier.value = updatedOffers;
                if (mounted) setModalState(() => isSubmitting = false);
                ref.invalidate(myProjectsProvider);
                await ref.read(myProjectsProvider.future);

                if (action == 'accept' &&
                    pendingAdminApproval &&
                    projectId != null &&
                    context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Offer accepted. Choose payment method on the next screen.',
                      ),
                    ),
                  );
                  if (context.mounted) {
                    context.go('/project-success/$projectId');
                  }
                }
              } catch (e) {
                setModalState(() => isSubmitting = false);
                rethrow;
              }
            },
          );
        },
      ),
    );
  }

  // Open applications (client)
  Future<void> _openApplications(BuildContext context) async {
    if (_applications.isEmpty) {
      await _fetchApplications();
    }
    if (!context.mounted) return;

    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final project = _project;
          if (project == null) return const SizedBox.shrink();
          return ApplicationsBottomSheet(
            project: project,
            applications: _applications,
            isLoading: false,
            isSubmitting: isSubmitting,
            onClose: () => Navigator.pop(context),
            onAction: (assignmentId, projectId, action) async {
              setModalState(() => isSubmitting = true);
              try {
                final repository = ref.read(projectsRepositoryProvider);
                final response = await repository.acceptRejectApplication(
                  assignmentId,
                  projectId,
                  action,
                );
                if (!response.success) {
                  throw Exception(
                    response.message ?? 'Failed to process application',
                  );
                }
                setModalState(() {
                  isSubmitting = false;
                  final updatedApplications = _applications.map((app) {
                    final appId =
                        app['assignment_id'] ??
                        app['assignmentId'] ??
                        app['id'];
                    if (appId == assignmentId) {
                      return {
                        ...app,
                        'status': action == 'accept' ? 'active' : 'rejected',
                      };
                    } else if (action == 'accept') {
                      return {...app, 'status': 'not_chosen'};
                    }
                    return app;
                  }).toList();
                  setState(() {
                    _applications = updatedApplications;
                  });
                });
                ref.invalidate(myProjectsProvider);
                await ref.read(myProjectsProvider.future);
              } catch (e) {
                setModalState(() => isSubmitting = false);
                rethrow;
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.primary.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.work_outline_rounded, color: Colors.white, size: 64),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: const Color(0xFF6B7280),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
      case 'active':
        return AppColors.primary; // Use primary color for active
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Bottom Action Button for Freelancer Projects
  Widget _buildBottomActionButton(
    BuildContext context,
    String label,
    bool isBidding,
    int projectId, {
    bool loading = false,
  }) {
    final isDisabled =
        loading || _hasApplied || _isLoading || _isCheckingApplied;
    final showSpinner = loading || _isLoading;

    return Container(
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: isDisabled ? null : AppGradients.primaryButton,
          color: isDisabled ? Colors.grey.shade300 : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled
                ? null
                : () {
                    if (isBidding) {
                      _showSendOfferModal();
                    } else {
                      _handleApply();
                    }
                  },
            borderRadius: BorderRadius.circular(20),
            child: Center(
              child: showSpinner
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        color: isDisabled ? Colors.grey.shade700 : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
