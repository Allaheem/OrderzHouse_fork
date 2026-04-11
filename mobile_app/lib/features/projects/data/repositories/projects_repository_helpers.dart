import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/models/project.dart';
import '../../../../core/utils/app_debug_log.dart';

String? projectsRepositoryExtractErrorMessage(Object? data) {
  if (data is Map<String, dynamic>) {
    final value = data['message'];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }
  if (data is String && data.trim().isNotEmpty) {
    final t = data.trim();
    return t.length > 160 ? '${t.substring(0, 160)}…' : t;
  }
  return null;
}

String projectsRepositoryDioErrorMessage(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      return 'Connection timeout. Check your internet connection.';
    case DioExceptionType.sendTimeout:
      return 'Request timeout. Please try again.';
    case DioExceptionType.receiveTimeout:
      return 'Response timeout. Please try again.';
    case DioExceptionType.badResponse:
      if (e.response?.statusCode == 403) {
        return 'Access denied. Please verify your account and subscribe.';
      }
      return 'Server error. Please try again later.';
    case DioExceptionType.cancel:
      return 'Request cancelled.';
    case DioExceptionType.unknown:
      return 'Network error. Check your connection.';
    default:
      return 'Failed to fetch projects.';
  }
}

/// Normalizes API project JSON so [Project.fromJson] accepts tender/exposure shapes.
Map<String, dynamic> projectsRepositoryNormalizeProjectJson(
  Map<String, dynamic> raw,
) {
  final normalized = Map<String, dynamic>.from(raw);

  int? asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  final fallbackId =
      asInt(normalized['exposure_id']) ??
      asInt(normalized['tender_vault_project_id']) ??
      asInt(normalized['project_id']) ??
      asInt(normalized['id']);
  if (fallbackId != null) {
    normalized['id'] = fallbackId;
  }

  normalized['user_id'] = asInt(normalized['user_id']) ?? 0;
  normalized['project_type'] =
      (normalized['project_type'] as String?)?.trim().isNotEmpty == true
      ? normalized['project_type']
      : 'bidding';
  normalized['status'] =
      (normalized['status'] as String?)?.trim().isNotEmpty == true
      ? normalized['status']
      : 'open';
  if ((normalized['title'] as String?)?.trim().isEmpty ?? true) {
    normalized['title'] = 'Project';
  }
  normalized['description'] = (normalized['description'] as String?) ?? '';
  normalized['created_at'] =
      (normalized['created_at'] as String?)?.trim().isNotEmpty == true
      ? normalized['created_at']
      : DateTime.now().toIso8601String();

  final coverPic = normalized['cover_pic'];
  final coverPicMissing =
      coverPic == null || (coverPic is String && coverPic.trim().isEmpty);
  if (coverPicMissing &&
      normalized['attachments'] is List &&
      (normalized['attachments'] as List).isNotEmpty) {
    final first = (normalized['attachments'] as List).first;
    if (first is Map<String, dynamic>) {
      final url = first['url'];
      if (url is String && url.trim().isNotEmpty) {
        normalized['cover_pic'] = url.trim();
      }
    }
  }

  if (normalized['duration_days'] == null &&
      normalized['duration'] != null &&
      normalized['duration_unit'] != null) {
    final duration = asInt(normalized['duration']);
    final unit = (normalized['duration_unit'] as String?)?.toLowerCase();
    if (duration != null) {
      if (unit == 'week' || unit == 'weeks') {
        normalized['duration_days'] = duration * 7;
      } else if (unit == 'day' || unit == 'days') {
        normalized['duration_days'] = duration;
      } else if (unit == 'hour' || unit == 'hours') {
        normalized['duration_hours'] = duration;
      }
    }
  }

  return normalized;
}

/// Parses a typical `/projects/...` list payload into [Project] models.
ApiResponse<List<Project>> projectsRepositoryParseProjectsListResponse(
  Response<dynamic> response,
) {
  final data = response.data as Map<String, dynamic>;

  List<dynamic>? projectsList;

  if (data['projects'] != null && data['projects'] is List) {
    projectsList = data['projects'] as List<dynamic>;
  } else if (data['data'] != null && data['data'] is List) {
    projectsList = data['data'] as List<dynamic>;
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

  if (AppConfig.isDevelopment) {
    appDebugLog('📊 Projects raw count: ${projectsList.length}');
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
}
