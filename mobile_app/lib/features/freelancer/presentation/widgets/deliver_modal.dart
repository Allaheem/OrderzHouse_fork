// ??? ????????
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/models/project.dart';
import '../../../../core/widgets/gradient_button.dart';

/// Modal for delivering project files
class DeliverModal extends StatefulWidget {
  final Project project;
  final VoidCallback onClose;
  final Future<void> Function(Project project, List<String> filePaths) onSubmit;
  final bool isSubmitting;

  const DeliverModal({
    super.key,
    required this.project,
    required this.onClose,
    required this.onSubmit,
    required this.isSubmitting,
  });

  @override
  State<DeliverModal> createState() => _DeliverModalState();
}

class _DeliverModalState extends State<DeliverModal> {
  final List<String> _selectedFiles = [];

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          // Get file paths - handle both mobile (path) and web (bytes) platforms
          final newFiles = result.files
              .where((file) => file.path != null)
              .map((file) => file.path!)
              .toList();

          // Add to existing files (allow multiple picks)
          _selectedFiles.addAll(newFiles);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick files. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  Future<void> _submit() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one file'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await widget.onSubmit(widget.project, _selectedFiles);
      // Do not pop here: parent callback already closes the dialog to avoid double-pop (NavigatorState.dispose crash)
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit delivery. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Deliver Project — ${widget.project.title}',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: widget.isSubmitting ? null : widget.onClose,
                    color: const Color(0xFF111827),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Pick files button
                    OutlinedButton.icon(
                      onPressed: widget.isSubmitting ? null : _pickFiles,
                      icon: const Icon(Icons.attach_file_rounded),
                      label: const Text('Select Files'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF111827),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Selected files list
                    if (_selectedFiles.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open_rounded,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No files selected',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._selectedFiles.asMap().entries.map((entry) {
                        final index = entry.key;
                        final filePath = entry.value;
                        final file = File(filePath);
                        final fileSize = file.existsSync()
                            ? file.lengthSync()
                            : 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.insert_drive_file_rounded,
                                color: Color(0xFF6B7280),
                                size: 24,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getFileName(filePath),
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: const Color(0xFF111827),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _formatFileSize(fileSize),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: const Color(0xFF6B7280),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: widget.isSubmitting
                                    ? null
                                    : () => _removeFile(index),
                                color: const Color(0xFF6B7280),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Footer buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.isSubmitting ? null : widget.onClose,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF111827),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: PrimaryGradientButton(
                      onPressed: widget.isSubmitting ? null : _submit,
                      label: 'Submit Delivery',
                      isLoading: widget.isSubmitting,
                      height: 48,
                      borderRadius: 12,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
