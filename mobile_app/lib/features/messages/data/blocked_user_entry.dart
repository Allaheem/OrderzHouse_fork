// ??? ????????
class BlockedUserEntry {
  final int userId;
  final String displayName;

  const BlockedUserEntry({required this.userId, required this.displayName});

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
      };

  factory BlockedUserEntry.fromJson(Map<String, dynamic> json) {
    return BlockedUserEntry(
      userId: json['userId'] as int,
      displayName: (json['displayName'] as String?)?.trim() ?? '',
    );
  }

  /// Backend GET /moderation/blocks: `user_id`, `display_name`
  factory BlockedUserEntry.fromApiJson(Map<String, dynamic> json) {
    final id = (json['user_id'] as num?)?.toInt() ?? (json['userId'] as num?)?.toInt() ?? 0;
    final name = (json['display_name'] as String? ?? json['displayName'] as String?)?.trim() ?? '';
    return BlockedUserEntry(
      userId: id,
      displayName: name.isEmpty ? 'User #$id' : name,
    );
  }
}
