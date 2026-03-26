// ??? ????????
import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan.freezed.dart';
part 'plan.g.dart';

// Helper functions for safe JSON parsing
num _priceFromJson(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return double.tryParse(value?.toString() ?? '0') ?? 0.0;
}

int _durationFromJson(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '0') ?? 0;
}

List<String> _featuresFromJson(dynamic value) {
  if (value == null) {
    return [];
  }
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return [];
}

String? _descriptionFromJson(dynamic value) {
  if (value == null) {
    return null;
  }
  final str = value.toString();
  return str.isEmpty ? null : str;
}

@freezed
class Plan with _$Plan {
  const Plan._();

  const factory Plan({
    required int id,
    required String name,
    @JsonKey(fromJson: _descriptionFromJson) String? description,
    @JsonKey(fromJson: _priceFromJson) required num price,
    @JsonKey(fromJson: _durationFromJson)
    required int duration, // Duration in days
    @JsonKey(name: 'plan_type')
    required String planType, // 'monthly', 'yearly', 'popular'
    @JsonKey(fromJson: _featuresFromJson)
    @Default([])
    List<String> features, // Features list
  }) = _Plan;

  factory Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);

  /// Format price with duration label (matching web behavior)
  String get formattedPrice {
    final durationLabel = planType == 'monthly'
        ? '$duration Month'
        : planType == 'yearly'
        ? '$duration Year'
        : name;
    return '$price JD / $durationLabel';
  }

  /// Check if plan is popular (matching web: plan_type === "popular")
  bool get isPopular => planType == 'popular';
}
