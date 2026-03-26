// ??? ????????
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../providers/project_wizard_provider.dart';

class ProjectFilesStepView extends ConsumerWidget {
  final VoidCallback? onNext;

  const ProjectFilesStepView({super.key, this.onNext});

  Future<void> _pickFiles(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final draft = ref.read(projectWizardProvider);
        final currentFiles = List<File>.from(draft.projectFiles);
        final newFiles = result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();

        final totalFiles = currentFiles.length + newFiles.length;
        if (totalFiles > 5) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.maxFilesAllowed(5)),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        currentFiles.addAll(newFiles);
        ref
            .read(projectWizardProvider.notifier)
            .updateProjectFiles(currentFiles);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToPickFiles}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final draft = ref.watch(projectWizardProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.projectFiles,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.projectFilesDescription,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Add Files Button
          OutlinedButton.icon(
            onPressed: draft.projectFiles.length >= 5
                ? null
                : () => _pickFiles(context, ref),
            icon: const Icon(Icons.add),
            label: Text(l10n.addFilesCount(draft.projectFiles.length, 5)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Files List
          if (draft.projectFiles.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Text(
                  l10n.noFilesAddedYet,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: draft.projectFiles.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final file = draft.projectFiles[index];
                final fileName = file.path.split('/').last;
                final fileSize = file.lengthSync();

                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF111827),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _formatFileSize(fileSize),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          final updatedFiles = List<File>.from(
                            draft.projectFiles,
                          );
                          updatedFiles.removeAt(index);
                          ref
                              .read(projectWizardProvider.notifier)
                              .updateProjectFiles(updatedFiles);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
