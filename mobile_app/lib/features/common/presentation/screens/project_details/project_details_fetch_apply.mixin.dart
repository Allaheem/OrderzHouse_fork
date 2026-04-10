// ignore_for_file: invalid_use_of_protected_member — see project_details_build.mixin.dart

part of 'package:OrderzHouse/features/common/presentation/screens/project_details_screen.dart';

/// Apply / offer flows (uses fetch APIs from [_ProjectDetailsFetchExtension]).
extension _ProjectDetailsFetchApplyExtension on _ProjectDetailsScreenState {
  Future<void> checkIfApplied() async {
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

  Future<void> handleSendOffer(double bidAmount, String? proposal) async {
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

        // Assignment exists only after the client accepts; sync pending-offer / applied state instead.
        await checkIfApplied();
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

  Future<void> handleApply() async {
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
        await fetchAssignment();
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

  void showSendOfferModal() {
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
                          handleSendOffer(bidAmount, proposal);
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
}
