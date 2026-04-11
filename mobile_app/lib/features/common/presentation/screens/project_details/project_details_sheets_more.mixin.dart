// ignore_for_file: invalid_use_of_protected_member — see project_details_build.mixin.dart

part of 'package:OrderzHouse/features/common/presentation/screens/project_details_screen.dart';

/// Receive sheet, file rows, history, downloads, offers & applications.
extension _ProjectDetailsSheetsMoreExtension on _ProjectDetailsScreenState {
  /// `project_files.id` from API — used for authenticated proxy download.
  int? _deliveryFileDbId(dynamic file) {
    if (file is! Map) return null;
    final raw = file['id'] ?? file['file_id'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  // Build File Item
  Widget buildFileItem(dynamic file) {
    final fileName = file is Map
        ? (file['filename'] ??
            file['name'] ??
            file['file_name'] ??
            'File')
        : file.toString();
    final fileUrl = file is Map
        ? (file['url'] ?? file['file_url'] ?? file['path'])
        : null;
    final fileSize = file is Map ? (file['size'] ?? file['size_bytes']) : null;
    final rowId = _deliveryFileDbId(file);

    // Check if URL is valid
    final hasValidUrl =
        fileUrl != null &&
        fileUrl.toString().isNotEmpty &&
        fileUrl.toString() != 'null' &&
        fileUrl.toString() != 'N/A';
    final canUseProxy =
        _project != null && rowId != null && rowId > 0;
    final canDownload = hasValidUrl || canUseProxy;

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
                    projectDetailsFormatFileSize(fileSize),
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
              color: canDownload
                  ? AppColors.accentOrange
                  : AppColors.textTertiary,
            ),
            onPressed: canDownload
                ? () => downloadFile(
                      hasValidUrl ? fileUrl.toString() : '',
                      fileName,
                      fileId: rowId,
                    )
                : null,
            tooltip: canDownload ? 'Download' : 'File not available',
          ),
        ],
      ),
    );
  }

  // Build Actions Card
  Widget buildActionsCard(Map<String, dynamic>? latestDelivery) {
    final hasDelivery = latestDelivery != null;
    final canReviewWork =
        hasDelivery && awaitingClientReviewForApprove;

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
          if (hasDelivery && !awaitingClientReviewForApprove) ...[
            Text(
              'Approve opens after the freelancer submits work for review (status: pending review). Chat files alone are not a formal delivery.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: canReviewWork
                        ? () {
                            Navigator.pop(context);
                            openRequestChangesModal(context);
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(
                        color: canReviewWork
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
                    onPressed: canReviewWork
                        ? () async {
                            Navigator.pop(context);
                            await handleApproveDelivery(context);
                          }
                        : null,
                    label: AppLocalizations.of(context)!.approve,
                    isEnabled: canReviewWork,
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
  Widget buildHistoryCard() {
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
            ...history.map((delivery) => buildHistoryItem(delivery)),
        ],
      ),
    );
  }

  // Build History Item (with downloadable files)
  Widget buildHistoryItem(Map<String, dynamic> delivery) {
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
                projectDetailsHistoryIcon(status),
                color: projectDetailsHistoryColor(status),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      projectDetailsHistoryTitle(status),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      projectDetailsFormatDeliveryDate(createdAt),
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
            ...files.map((file) => buildFileItem(file)),
          ],
        ],
      ),
    );
  }

  // Helper: Download file with authorization (no permissions needed)
  Future<void> downloadFile(
    String url,
    String fileName, {
    int? fileId,
  }) async {
    final project = _project;
    final useProxy =
        project != null && fileId != null && fileId > 0;
    final downloadPath = useProxy
        ? '/projects/${project.id}/files/$fileId/download'
        : url.trim();

    if (!useProxy &&
        (downloadPath.isEmpty ||
            downloadPath == 'N/A' ||
            downloadPath == 'null')) {
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

      final safeName = LocalDownloadOpen.safeFileName(fileName);
      final savePath = '${orderzHouseDir.path}/$safeName';

      final repository = ref.read(projectsRepositoryProvider);
      var downloadResult = await repository.downloadFile(
        url: downloadPath,
        savePath: savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            debugPrint('Download progress: $progress%');
          }
        },
      );
      // If production API has not shipped the proxy route yet (HTTP 404), retry direct URL.
      final fallbackUrl = url.trim();
      final canFallback = useProxy &&
          fallbackUrl.isNotEmpty &&
          fallbackUrl != 'N/A' &&
          fallbackUrl != 'null' &&
          fallbackUrl != downloadPath;
      if (!downloadResult.success && canFallback) {
        final msg = (downloadResult.message ?? '').toLowerCase();
        if (msg.contains('404') || msg.contains('not found')) {
          downloadResult = await repository.downloadFile(
            url: fallbackUrl,
            savePath: savePath,
            onReceiveProgress: (received, total) {
              if (total != -1) {
                final progress = (received / total * 100).toStringAsFixed(0);
                debugPrint('Download progress (fallback): $progress%');
              }
            },
          );
        }
      }
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
                  'Downloaded: $safeName',
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
                final err = await LocalDownloadOpen.openSavedDownload(savePath);
                if (!mounted) return;
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err),
                      backgroundColor: Colors.orange.shade800,
                    ),
                  );
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

  // Open offers (client)
  Future<void> openOffers(BuildContext context) async {
    if (_offers.isEmpty) {
      await fetchOffers();
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
  Future<void> openApplications(BuildContext context) async {
    if (_applications.isEmpty) {
      await fetchApplications();
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
}
