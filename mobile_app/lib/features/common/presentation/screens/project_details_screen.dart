// ??? ????????
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/project.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
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
import '../widgets/project_details/project_details_formatters.dart';
import '../widgets/project_details/project_details_freelancer_cta_bar.dart';
import '../widgets/project_details/project_details_scroll_content.dart';

part 'project_details/project_details_init.mixin.dart';
part 'project_details/project_details_fetch.mixin.dart';
part 'project_details/project_details_fetch_apply.mixin.dart';
part 'project_details/project_details_build.mixin.dart';
part 'project_details/project_details_bottom.mixin.dart';
part 'project_details/project_details_sheets.mixin.dart';
part 'project_details/project_details_sheets_more.mixin.dart';
part 'project_details/project_details_sheets_deliveries.mixin.dart';

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

/// Holds state fields so mixins can use `on _ProjectDetailsScreenBase` without
/// recursive inheritance (`on _ProjectDetailsScreenState` would cycle with `with`).
abstract class _ProjectDetailsScreenBase extends ConsumerState<ProjectDetailsScreen> {
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
}

class _ProjectDetailsScreenState extends _ProjectDetailsScreenBase {
  @override
  void initState() {
    super.initState();
    projectDetailsHandleInitState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    projectDetailsHandleDidChangeDependencies();
  }

  @override
  Widget build(BuildContext context) => projectDetailsRootBuild(context);
}
