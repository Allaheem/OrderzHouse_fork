// ignore_for_file: invalid_use_of_protected_member — see project_details_build.mixin.dart

part of 'package:OrderzHouse/features/common/presentation/screens/project_details_screen.dart';

/// Files / deliveries bottom sheets (depends on [buildFileItem], [buildActionsCard], [buildHistoryCard] in other parts).
extension _ProjectDetailsSheetsDeliveriesExtension on _ProjectDetailsScreenState {
  // Open Files View (client) - read-only view of delivered files for completed projects
  Future<void> openFilesView(BuildContext context) async {
    // Fetch deliveries first if not already loaded
    if (_deliveries.isEmpty) {
      await fetchDeliveriesIfNeeded();
    }
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => buildFilesSheet(context),
    );
  }

  // Build Files Sheet UI (read-only, no actions)
  Widget buildFilesSheet(BuildContext context) {
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
                      return buildDeliveryFileCard(delivery, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Build Delivery File Card
  Widget buildDeliveryFileCard(Map<String, dynamic> delivery, int index) {
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
                  color: projectDetailsHistoryColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: projectDetailsHistoryColor(status),
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
            ...files.map((file) => buildFileItem(file)),
          ],
          const SizedBox(height: 8),
          Text(
            'Submitted: ${projectDetailsFormatDeliveryDate(createdAt)}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // Open Receive Panel (client) - new UI for viewing/approving deliveries
  Future<void> openReceivePanel(BuildContext context) async {
    // Fetch deliveries first if not already loaded
    if (_deliveries.isEmpty) {
      await fetchDeliveriesIfNeeded();
    }
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => buildReceiveSheet(context),
    );
  }

  // Build Receive Sheet UI
  Widget buildReceiveSheet(BuildContext context) {
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
                  buildLatestDeliveryCard(latestDelivery),

                  const SizedBox(height: 20),

                  // Actions Card
                  buildActionsCard(latestDelivery),

                  const SizedBox(height: 20),

                  // History Card
                  buildHistoryCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build Latest Delivery Card
  Widget buildLatestDeliveryCard(Map<String, dynamic>? latestDelivery) {
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
                onPressed: fetchDeliveriesIfNeeded,
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
            buildDeliveryContent(latestDelivery),
        ],
      ),
    );
  }

  // Build Delivery Content
  Widget buildDeliveryContent(Map<String, dynamic> delivery) {
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
          ...files.map((file) => buildFileItem(file)),
        ],
        const SizedBox(height: 8),
        Text(
          'Submitted: ${projectDetailsFormatDeliveryDate(createdAt)}',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
