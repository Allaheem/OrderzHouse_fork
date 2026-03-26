// ??? ????????
/// Response from POST /stripe/project-checkout-session.
/// Matches web: { url }, or { skipPayment: true, project_id? }.
class ProjectCheckoutResult {
  final String? url;
  final bool skipPayment;
  final int? projectId;

  const ProjectCheckoutResult({
    this.url,
    this.skipPayment = false,
    this.projectId,
  });

  factory ProjectCheckoutResult.fromJson(Map<String, dynamic> json) {
    return ProjectCheckoutResult(
      url: json['url'] as String?,
      skipPayment: json['skipPayment'] == true,
      projectId: json['project_id'] != null
          ? (json['project_id'] is int
                ? json['project_id'] as int
                : int.tryParse(json['project_id'].toString()))
          : null,
    );
  }
}
