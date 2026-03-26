// ??? ????????
/// Model for referral information
class ReferralInfo {
  final String code;
  final String? link;
  final int invited;
  final int successful;
  final double earned;
  final int weeklyRemaining;

  /// Referral reward percentage (e.g., 0.05 = 5% of registration fee)
  final double referrerRewardPercent;
  final String currency;

  const ReferralInfo({
    required this.code,
    this.link,
    this.invited = 0,
    this.successful = 0,
    this.earned = 0.0,
    this.weeklyRemaining = 0,
    this.referrerRewardPercent = 0.05, // 5% of registration fee
    this.currency = 'JOD',
  });

  /// Get reward percent as display string (e.g., "5%")
  String get rewardPercentDisplay =>
      '${(referrerRewardPercent * 100).toStringAsFixed(0)}%';

  /// Check if referral code is valid (not empty or placeholder)
  bool get hasValidCode =>
      code.isNotEmpty && code != 'N/A' && code != 'Loading...';

  /// Create from JSON with null-safe defaults
  /// Handles API response format:
  /// { code: null|string, referralCode: null|string, invitedCount: int, successfulCount: int, earnedAmount: double, weeklyRemaining: int, stats: {...}, rules: {...} }
  factory ReferralInfo.fromJson(Map<String, dynamic> json) {
    // Parse code - prefer json['code'], then json['referralCode'], fallback to ""
    String code = '';
    if (json['code'] != null && json['code'] is String) {
      code = (json['code'] as String).trim();
    } else if (json['referralCode'] != null && json['referralCode'] is String) {
      code = (json['referralCode'] as String).trim();
    }

    // Parse link - can be empty string from API
    String? link;
    if (json['link'] != null && json['link'] is String) {
      final linkValue = (json['link'] as String).trim();
      if (linkValue.isNotEmpty) {
        link = linkValue;
      }
    }

    // Parse stats object if present
    Map<String, dynamic> stats = {};
    if (json['stats'] != null && json['stats'] is Map) {
      stats = json['stats'] as Map<String, dynamic>;
    }

    // Parse rules object if present
    Map<String, dynamic> rules = {};
    if (json['rules'] != null && json['rules'] is Map) {
      rules = json['rules'] as Map<String, dynamic>;
    }

    // Safe parsing with defaults
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    // Parse fields according to priority:
    // invited: invitedCount (root) > stats.invited > 0
    final invited = parseInt(
      json['invitedCount'] ?? stats['invited'] ?? json['invited'] ?? 0,
    );

    // successful: successfulCount (root) > stats.completed > stats.successful > 0
    final successful = parseInt(
      json['successfulCount'] ??
          stats['completed'] ??
          stats['successful'] ??
          json['completed'] ??
          json['successful'] ??
          0,
    );

    // earned: earnedAmount (root) > stats.earned > 0.0
    final earned = parseDouble(
      json['earnedAmount'] ?? stats['earned'] ?? json['earned'] ?? 0,
    );

    // weeklyRemaining: weeklyRemaining (root) > 0
    final weeklyRemaining = parseInt(
      json['weeklyRemaining'] ?? json['weekly_remaining'] ?? 0,
    );

    // currency: rules.currency > "JOD" (default)
    final currency = (rules['currency'] ?? json['currency'] ?? 'JOD') as String;

    return ReferralInfo(
      code: code,
      link: link,
      invited: invited,
      successful: successful,
      earned: earned,
      weeklyRemaining: weeklyRemaining,
      referrerRewardPercent: parseDouble(
        rules['referrerRewardPercent'] ??
            json['referrerRewardPercent'] ??
            rules['referrerReward'] ??
            json['referrerReward'] ??
            0.05,
      ),
      currency: currency,
    );
  }

  /// Convert to JSON (for debugging/logging)
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'link': link,
      'invited': invited,
      'successful': successful,
      'earned': earned,
      'weeklyRemaining': weeklyRemaining,
      'referrerRewardPercent': referrerRewardPercent,
      'currency': currency,
    };
  }
}
