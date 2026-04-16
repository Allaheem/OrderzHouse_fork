// ignore_for_file: invalid_use_of_protected_member — see project_details_build.mixin.dart

part of 'package:OrderzHouse/features/common/presentation/screens/project_details_screen.dart';

extension _ProjectDetailsSheetsExtension on _ProjectDetailsScreenState {
  // Open deliver modal (freelancer)
  Future<void> openDeliverModal(BuildContext context) async {
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
              _deliveriesAwaitingClientReview = true;
              _projectData = {
                ...?_projectData,
                'completion_status': 'pending_review',
                'status': 'pending_review',
              };
            });

            // Refresh deliveries
            await fetchDeliveriesIfNeeded();

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
  Future<void> handleApproveDelivery(BuildContext context) async {
    if (_isLoading) return;
    final project = _project;
    if (project == null) return;

    await fetchRawProjectData();
    if (!awaitingClientReviewForApprove) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Work must be submitted for review before it can be approved. '
              'Ask the freelancer to use Submit delivery.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(projectsRepositoryProvider);
      final response = await repository.approveDelivery(project.id);

      if (!response.success) {
        throw Exception(response.message ?? 'Failed to approve delivery');
      }

      // Update local state immediately
      setState(() {
        _deliveriesAwaitingClientReview = false;
        _projectData = {
          ...?_projectData,
          'completion_status': 'completed',
          'status': 'completed',
        };
        _isLoading = false;
      });

      // Refresh deliveries
      await fetchDeliveriesIfNeeded();

      // Refresh projects list
      ref.invalidate(myProjectsProvider);
      await ref.read(myProjectsProvider.future);

      // Refresh raw project data
      await fetchRawProjectData();

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
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Open Request Changes Modal (client)
  Future<void> openRequestChangesModal(BuildContext context) async {
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
                            await handleRequestChanges(
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
  Future<void> handleRequestChanges(
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
      await fetchDeliveriesIfNeeded();

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
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
