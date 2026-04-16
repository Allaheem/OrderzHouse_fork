// ??? ????????
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/models/project.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/utils/safe_url_launch.dart';

/// Bottom sheet for client to review delivery and approve/request changes
class ReviewDeliveryBottomSheet extends StatefulWidget {
  final Project project;
  final List<Map<String, dynamic>> deliveries;
  final bool isLoading;
  final VoidCallback onClose;
  final Future<void> Function(int projectId) onApprove;
  final Future<void> Function(int projectId, String message) onRequestChanges;
  final VoidCallback? onRefresh;

  const ReviewDeliveryBottomSheet({
    super.key,
    required this.project,
    required this.deliveries,
    required this.isLoading,
    required this.onClose,
    required this.onApprove,
    required this.onRequestChanges,
    this.onRefresh,
  });

  @override
  State<ReviewDeliveryBottomSheet> createState() =>
      _ReviewDeliveryBottomSheetState();
}

class _ReviewDeliveryBottomSheetState extends State<ReviewDeliveryBottomSheet> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;
  Map<String, dynamic>? _latestDelivery;

  @override
  void initState() {
    super.initState();
    _updateLatestDelivery();
  }

  @override
  void didUpdateWidget(ReviewDeliveryBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.deliveries != oldWidget.deliveries) {
      _updateLatestDelivery();
    }
  }

  void _updateLatestDelivery() {
    if (widget.deliveries.isNotEmpty) {
      // Sort by sent_at descending and get the latest
      final sorted = List<Map<String, dynamic>>.from(widget.deliveries);
      sorted.sort((a, b) {
        final aTime = _parseDate(a['sent_at'] ?? a['sentAt'] ?? a['at']);
        final bTime = _parseDate(b['sent_at'] ?? b['sentAt'] ?? b['at']);
        return bTime.compareTo(aTime);
      });
      setState(() {
        _latestDelivery = sorted.first;
      });
    } else {
      setState(() {
        _latestDelivery = null;
      });
    }
  }

  DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime(1970);
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime(1970);
      }
    }
    return DateTime(1970);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> _getAttachments(Map<String, dynamic>? delivery) {
    if (delivery == null) return [];
    final files = delivery['files'] ?? delivery['attachments'] ?? [];
    if (files is List) {
      return files.map((f) => f as Map<String, dynamic>).toList();
    }
    return [];
  }

  Future<void> _handleApprove() async {
    setState(() => _isSubmitting = true);
    try {
      await widget.onApprove(widget.project.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project approved ✅'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve delivery. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleRequestChanges() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onRequestChanges(widget.project.id, message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Change request sent ✉️'),
            backgroundColor: Colors.blue,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send change request. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attachments = _getAttachments(_latestDelivery);
    final sentAt = _latestDelivery != null
        ? _parseDate(
            _latestDelivery!['sent_at'] ??
                _latestDelivery!['sentAt'] ??
                _latestDelivery!['at'],
          )
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Review Delivery — ${widget.project.title}',
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
                  onPressed: widget.onClose,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Latest delivery section
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
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
                                color: const Color(0xFF111827),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (widget.onRefresh != null)
                              IconButton(
                                icon: widget.isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.refresh_rounded,
                                        size: 20,
                                      ),
                                onPressed: widget.isLoading
                                    ? null
                                    : widget.onRefresh,
                                color: const Color(0xFF111827),
                              ),
                          ],
                        ),

                        if (widget.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(AppSpacing.xl),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_latestDelivery == null)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: Text(
                              'No deliveries yet.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          )
                        else ...[
                          if (sentAt != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Delivered on ${_formatDate(sentAt)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: const Color(0xFF6B7280),
                                fontSize: 11,
                              ),
                            ),
                          ],

                          // Links (if any)
                          if (_latestDelivery!['links'] != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            _buildLinkField(
                              'Primary',
                              _latestDelivery!['links']['primary'],
                            ),
                            if (_latestDelivery!['links']['secondary'] != null)
                              _buildLinkField(
                                'Secondary',
                                _latestDelivery!['links']['secondary'],
                              ),
                          ],

                          // Notes (if any)
                          if (_latestDelivery!['notes'] != null &&
                              (_latestDelivery!['notes'] as String)
                                  .isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Notes:',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: const Color(0xFF111827),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _latestDelivery!['notes'] as String,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ],

                          // Attachments
                          if (attachments.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Attachments:',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: const Color(0xFF111827),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...attachments.map((file) => _buildFileItem(file)),
                          ],
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Request changes input
                  Text(
                    'Request Changes (optional):',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter your feedback or change requests...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFF9CA3AF),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFFB923C),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
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
                    onPressed: _isSubmitting ? null : _handleRequestChanges,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF111827),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Request Changes'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: GradientButton(
                    onPressed: _isSubmitting ? null : _handleApprove,
                    label: 'Approve',
                    isLoading: _isSubmitting,
                    height: 48,
                    borderRadius: 12,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: MediaQuery.of(context).padding.bottom + AppSpacing.md,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkField(String label, String? url) {
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: AppTextStyles.labelSmall.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () async {
              await safeLaunchExternalUrl(
                context,
                url,
                fallbackMessage: 'Invalid link',
              );
            },
            child: Text(
              url,
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFF3B82F6),
                decoration: TextDecoration.underline,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(Map<String, dynamic> file) {
    final fileName =
        file['file_name'] ?? file['name'] ?? file['filename'] ?? 'File';
    final fileUrl = file['file_url'] ?? file['url'] ?? file['path'];
    final fileSize = file['file_size'] ?? file['size'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.insert_drive_file_rounded,
            size: 20,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (fileSize > 0)
                  Text(
                    _formatFileSize(fileSize),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFF6B7280),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          if (fileUrl != null)
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded, size: 18),
              onPressed: () async {
                await safeLaunchExternalUrl(
                  context,
                  fileUrl.toString(),
                  fallbackMessage: 'Invalid attachment link',
                );
              },
              color: const Color(0xFF3B82F6),
            ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
