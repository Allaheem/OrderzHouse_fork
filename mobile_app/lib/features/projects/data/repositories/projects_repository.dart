import 'package:dio/dio.dart';
import '../../../../core/utils/app_debug_log.dart';
import '../../../../core/models/project.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/repositories/projects_repository.dart';
import '../datasources/remote/projects_remote_datasource.dart';
import '../models/change_request_model.dart';
import 'projects_repository_helpers.dart';
import 'projects_repository_apply_assignment.dart';
import 'projects_repository_project_lifecycle.dart';
import 'projects_repository_changes_delivery.dart';
import 'projects_repository_offers_applications.dart';

class ProjectsRepository implements IProjectsRepository {
  factory ProjectsRepository({
    Dio? dio,
    ApiClient? apiClient,
    int? Function()? currentUserRoleReader,
    ProjectsRemoteDataSource? exploreRemote,
  }) {
    final d = dio ?? DioClient.instance;
    final a = apiClient ?? ApiClient.instance;
    return ProjectsRepository._(
      dio: d,
      api: a,
      currentUserRoleReader: currentUserRoleReader,
      exploreRemote: exploreRemote ?? ProjectsRemoteDataSource(d),
      applyAssignment: ProjectsRepositoryApplyAssignment(d),
      projectLifecycle: ProjectsRepositoryProjectLifecycle(d),
      changesDelivery: ProjectsRepositoryChangesDelivery(d, a),
      offersApplications: ProjectsRepositoryOffersApplications(d),
    );
  }

  ProjectsRepository._({
    required Dio dio,
    required ApiClient api,
    required int? Function()? currentUserRoleReader,
    required ProjectsRemoteDataSource exploreRemote,
    required ProjectsRepositoryApplyAssignment applyAssignment,
    required ProjectsRepositoryProjectLifecycle projectLifecycle,
    required ProjectsRepositoryChangesDelivery changesDelivery,
    required ProjectsRepositoryOffersApplications offersApplications,
  }) : _dio = dio,
       _api = api,
       _currentUserRoleReader = currentUserRoleReader,
       _exploreRemote = exploreRemote,
       _applyAssignment = applyAssignment,
       _projectLifecycle = projectLifecycle,
       _changesDelivery = changesDelivery,
       _offersApplications = offersApplications;

  final Dio _dio;
  final ApiClient _api;
  final int? Function()? _currentUserRoleReader;
  final ProjectsRemoteDataSource _exploreRemote;
  final ProjectsRepositoryApplyAssignment _applyAssignment;
  final ProjectsRepositoryProjectLifecycle _projectLifecycle;
  final ProjectsRepositoryChangesDelivery _changesDelivery;
  final ProjectsRepositoryOffersApplications _offersApplications;

  /// Get user's projects as raw JSON (for additional fields)
  /// Endpoint: GET /projects/myprojects
  Future<ApiResponse<List<Map<String, dynamic>>>> getMyProjectsRaw({
    int page = 1,
    int limit = 20,
    String? statusKey,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (statusKey != null && statusKey.isNotEmpty) {
        params['status'] = statusKey;
      }
      final response = await _dio.get(
        '/projects/myprojects',
        queryParameters: params,
      );

      final data = response.data as Map<String, dynamic>;
      List<dynamic>? projectsList;

      if (data['projects'] != null && data['projects'] is List) {
        projectsList = data['projects'] as List<dynamic>;
      } else if (data['data'] != null) {
        if (data['data'] is List) {
          projectsList = data['data'] as List<dynamic>;
        } else if (data['data'] is Map && data['data']['projects'] is List) {
          projectsList =
              (data['data'] as Map<String, dynamic>)['projects']
                  as List<dynamic>;
        }
      } else if (data['rows'] != null && data['rows'] is List) {
        projectsList = data['rows'] as List<dynamic>;
      } else if (response.data is List) {
        projectsList = response.data as List<dynamic>;
      }

      if (projectsList == null || projectsList.isEmpty) {
        return const ApiResponse(
          success: true,
          data: [],
          message: 'No projects found',
        );
      }

      final rawProjects = projectsList
          .map((e) => e as Map<String, dynamic>)
          .toList();

      return ApiResponse(
        success: true,
        data: rawProjects,
        message: 'Projects fetched successfully',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: [],
        message:
            projectsRepositoryExtractErrorMessage(e.response?.data) ??
            'Failed to fetch projects',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        data: [],
        message: 'Failed to fetch projects: ${e.toString()}',
      );
    }
  }

  /// Get user's projects (client or freelancer)
  Future<ApiResponse<List<Project>>> getMyProjects({
    int page = 1,
    int limit = 20,
    String? statusKey,
  }) async {
    try {
      final response = await _api.getMyProjects(
        page: page,
        limit: limit,
        statusKey: statusKey,
      );

      final data = response.data as Map<String, dynamic>;

      List<dynamic>? projectsList;

      if (data['projects'] != null && data['projects'] is List) {
        projectsList = data['projects'] as List<dynamic>;
      } else if (data['data'] != null) {
        if (data['data'] is List) {
          projectsList = data['data'] as List<dynamic>;
        } else if (data['data'] is Map && data['data']['projects'] is List) {
          projectsList =
              (data['data'] as Map<String, dynamic>)['projects']
                  as List<dynamic>;
        }
      } else if (data['rows'] != null && data['rows'] is List) {
        projectsList = data['rows'] as List<dynamic>;
      } else if (response.data is List) {
        projectsList = response.data as List<dynamic>;
      }

      if (projectsList == null || projectsList.isEmpty) {
        if (AppConfig.isDevelopment) {
          appDebugLog('⚠️ RESPONSE: No projects found in response');
        }
        return const ApiResponse(
          success: true,
          data: [],
          message: 'No projects found',
        );
      }

      final projects = <Project>[];
      for (var i = 0; i < projectsList.length; i++) {
        try {
          final json = projectsRepositoryNormalizeProjectJson(
            projectsList[i] as Map<String, dynamic>,
          );
          final project = Project.fromJson(json);
          projects.add(project);
        } catch (e) {
          if (AppConfig.isDevelopment) {
            appDebugLog('⚠️ Failed to parse project at index $i: $e');
            appDebugLog('⚠️ Project data: ${projectsList[i]}');
          }
        }
      }

      if (AppConfig.isDevelopment) {
        appDebugLog(
          '✅ Parsed ${projects.length}/${projectsList.length} projects successfully',
        );
      }

      return ApiResponse(
        success: true,
        data: projects,
        message: 'Projects fetched successfully',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: [],
        message:
            projectsRepositoryExtractErrorMessage(e.response?.data) ??
            projectsRepositoryDioErrorMessage(e),
        error: e.response?.data is Map<String, dynamic>
            ? e.response?.data as Map<String, dynamic>
            : null,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        data: [],
        message: 'Failed to fetch projects: ${e.toString()}',
      );
    }
  }

  int? _getCurrentUserRole() {
    try {
      return _currentUserRoleReader?.call();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ApiResponse<List<Project>>> fetchExploreProjects({
    String? query,
    int? categoryId,
    int? subCategoryId,
    int? subSubCategoryId,
    int page = 1,
    int limit = 20,
    int? userRoleId,
    String sortBy = 'newest',
  }) {
    return _exploreRemote.fetchExploreProjects(
      query: query,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      subSubCategoryId: subSubCategoryId,
      page: page,
      limit: limit,
      userRoleId: userRoleId ?? _getCurrentUserRole(),
      sortBy: sortBy,
    );
  }

  Future<ApiResponse<void>> applyForProject({
    required int projectId,
    String? message,
  }) =>
      _applyAssignment.applyForProject(projectId: projectId, message: message);

  Future<ApiResponse<Map<String, dynamic>?>> getMyAssignment(int projectId) =>
      _applyAssignment.getMyAssignment(projectId);

  Future<ApiResponse<bool>> checkIfAssigned(int projectId) =>
      _applyAssignment.checkIfAssigned(projectId);

  Future<ApiResponse<Map<String, dynamic>>> createProject({
    required int categoryId,
    int? subCategoryId,
    required int subSubCategoryId,
    required String title,
    required String description,
    required String projectType,
    double? budget,
    double? hourlyRate,
    double? budgetMin,
    double? budgetMax,
    required String durationType,
    int? durationDays,
    int? durationHours,
    List<String>? preferredSkills,
    String? coverPicPath,
  }) =>
      _projectLifecycle.createProject(
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        subSubCategoryId: subSubCategoryId,
        title: title,
        description: description,
        projectType: projectType,
        budget: budget,
        hourlyRate: hourlyRate,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        durationType: durationType,
        durationDays: durationDays,
        durationHours: durationHours,
        preferredSkills: preferredSkills,
        coverPicPath: coverPicPath,
      );

  Future<ApiResponse<void>> uploadProjectFiles(
    int projectId,
    List<String> filePaths,
  ) =>
      _projectLifecycle.uploadProjectFiles(projectId, filePaths);

  Future<ApiResponse<Map<String, dynamic>>> getProjectSuccess(int projectId) =>
      _projectLifecycle.getProjectSuccess(projectId);

  Future<ApiResponse<void>> setProjectOfflinePayment(
    int projectId,
    String method,
  ) =>
      _projectLifecycle.setProjectOfflinePayment(projectId, method);

  Future<ApiResponse<void>> requestProjectChanges({
    required int projectId,
    required String message,
  }) =>
      _changesDelivery.requestProjectChanges(
        projectId: projectId,
        message: message,
      );

  Future<ApiResponse<List<ChangeRequest>>> getProjectChangeRequests(
    int projectId,
  ) =>
      _changesDelivery.getProjectChangeRequests(projectId);

  Future<void> markChangeRequestsRead(
    int projectId, {
    List<int>? ids,
    DateTime? lastSeenAt,
  }) =>
      _changesDelivery.markChangeRequestsRead(
        projectId,
        ids: ids,
        lastSeenAt: lastSeenAt,
      );

  Future<ApiResponse<void>> deliverProject(
    int projectId,
    List<String> filePaths,
  ) =>
      _changesDelivery.deliverProject(projectId, filePaths);

  Future<ApiResponse<List<Map<String, dynamic>>>> getProjectDeliveries(
    int projectId,
  ) =>
      _changesDelivery.getProjectDeliveries(projectId);

  Future<ApiResponse<void>> approveDelivery(int projectId) =>
      _changesDelivery.approveDelivery(projectId);

  Future<ApiResponse<void>> requestChanges(int projectId, String message) =>
      _changesDelivery.requestChanges(projectId, message);

  Future<ApiResponse<List<Map<String, dynamic>>>> getProjectOffers(
    int projectId,
  ) =>
      _offersApplications.getProjectOffers(projectId);

  Future<ApiResponse<Map<String, dynamic>?>> approveRejectOffer(
    int offerId,
    String action,
  ) =>
      _offersApplications.approveRejectOffer(offerId, action);

  Future<ApiResponse<List<Map<String, dynamic>>>> getProjectApplications(
    int projectId,
  ) =>
      _offersApplications.getProjectApplications(projectId);

  Future<ApiResponse<void>> acceptRejectApplication(
    int assignmentId,
    int projectId,
    String action,
  ) =>
      _offersApplications.acceptRejectApplication(
        assignmentId,
        projectId,
        action,
      );

  Future<ApiResponse<void>> downloadFile({
    required String url,
    required String savePath,
    void Function(int received, int total)? onReceiveProgress,
  }) =>
      _offersApplications.downloadFile(
        url: url,
        savePath: savePath,
        onReceiveProgress: onReceiveProgress,
      );
}
