// ??? ????????
/// Policy document loaded from assets (privacy_en.json / privacy_ar.json).
class PolicyDocument {
  final String heroTitle;
  final String heroSubtitle;
  final List<PolicyQuickTile> quickTiles;
  final String dataLifecycleTitle;
  final String dataLifecycleSubtitle;
  final List<PolicyLifecycleStep> lifecycle;
  final List<PolicySection> sections;
  final String lastUpdated;
  final String footerNote;

  const PolicyDocument({
    required this.heroTitle,
    required this.heroSubtitle,
    required this.quickTiles,
    required this.dataLifecycleTitle,
    required this.dataLifecycleSubtitle,
    required this.lifecycle,
    required this.sections,
    required this.lastUpdated,
    required this.footerNote,
  });

  factory PolicyDocument.fromJson(Map<String, dynamic> json) {
    return PolicyDocument(
      heroTitle: json['heroTitle'] as String? ?? '',
      heroSubtitle: json['heroSubtitle'] as String? ?? '',
      quickTiles:
          (json['quickTiles'] as List<dynamic>?)
              ?.map((e) => PolicyQuickTile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dataLifecycleTitle: json['dataLifecycleTitle'] as String? ?? '',
      dataLifecycleSubtitle: json['dataLifecycleSubtitle'] as String? ?? '',
      lifecycle:
          (json['lifecycle'] as List<dynamic>?)
              ?.map(
                (e) => PolicyLifecycleStep.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      sections:
          (json['sections'] as List<dynamic>?)
              ?.map((e) => PolicySection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: json['lastUpdated'] as String? ?? '',
      footerNote: json['footerNote'] as String? ?? '',
    );
  }
}

class PolicyQuickTile {
  final String label;
  final String icon;

  const PolicyQuickTile({required this.label, required this.icon});

  factory PolicyQuickTile.fromJson(Map<String, dynamic> json) {
    return PolicyQuickTile(
      label: json['label'] as String? ?? '',
      icon: json['icon'] as String? ?? 'shield',
    );
  }
}

class PolicyLifecycleStep {
  final String title;
  final String desc;

  const PolicyLifecycleStep({required this.title, required this.desc});

  factory PolicyLifecycleStep.fromJson(Map<String, dynamic> json) {
    return PolicyLifecycleStep(
      title: json['title'] as String? ?? '',
      desc: json['desc'] as String? ?? '',
    );
  }
}

class PolicySection {
  final String id;
  final String title;
  final String icon;
  final List<String> bullets;
  final String body;

  const PolicySection({
    required this.id,
    required this.title,
    required this.icon,
    required this.bullets,
    required this.body,
  });

  factory PolicySection.fromJson(Map<String, dynamic> json) {
    final bulletsList = json['bullets'] as List<dynamic>?;
    return PolicySection(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      icon: json['icon'] as String? ?? 'shield',
      bullets: bulletsList?.map((e) => e.toString()).toList() ?? [],
      body: json['body'] as String? ?? '',
    );
  }
}
