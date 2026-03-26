// ??? ????????
class Payment {
  final int id;
  final double amount;
  final String currency;
  final String status;
  final String? purpose; // Legacy: 'plan' or 'project'
  final int? referenceId; // Legacy
  final String? projectTitle; // Legacy
  final DateTime createdAt;
  // Freelancer wallet transaction fields (legacy)
  final String? type; // 'credit' or 'debit'
  final String? note; // Legacy
  // Additional fields
  final String? method;

  // New enriched fields
  final String? source; // 'plan', 'project', or 'wallet'
  final String? title; // Enriched title
  final String? description; // Enriched description
  final PaymentProject? project; // Project details if source='project'
  final PaymentReference?
  reference; // Reference details (paymentId, purpose, etc.)

  Payment({
    required this.id,
    required this.amount,
    this.currency = 'JOD',
    required this.status,
    this.purpose,
    this.referenceId,
    this.projectTitle,
    required this.createdAt,
    this.type,
    this.note,
    this.method,
    this.source,
    this.title,
    this.description,
    this.project,
    this.reference,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
      return DateTime.now();
    }

    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed ?? 0.0;
      }
      return 0.0;
    }

    // Parse project if available
    PaymentProject? parseProject(Map<String, dynamic>? json) {
      if (json == null) return null;
      return PaymentProject(
        projectId: json['projectId'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        clientId: json['clientId'] as int?,
        freelancerId: json['freelancerId'] as int?,
      );
    }

    // Parse reference if available
    PaymentReference? parseReference(Map<String, dynamic>? json) {
      if (json == null) return null;
      return PaymentReference(
        paymentId: json['paymentId'] as int?,
        purpose: json['purpose'] as String?,
        referenceId: json['referenceId'] as int?,
        stripeSessionId: json['stripeSessionId'] as String?,
        stripePaymentIntent: json['stripePaymentIntent'] as String?,
        transactionId: json['transactionId'] as int?,
        transactionType: json['type'] as String?,
      );
    }

    // Determine source (new enriched field or fallback to legacy purpose)
    final source = json['source'] as String? ?? json['purpose'] as String?;

    // Use enriched title/description if available, otherwise fallback to legacy
    final title =
        json['title'] as String? ??
        json['project_title'] as String? ??
        json['purpose'] as String?;
    final description =
        json['description'] as String? ?? json['note'] as String?;

    // reference can be string (e.g. "Credit") or Map from API
    PaymentReference? ref;
    final refRaw = json['reference'];
    if (refRaw is Map<String, dynamic>) {
      ref = parseReference(refRaw);
    } else if (refRaw is String && refRaw.isNotEmpty) {
      ref = PaymentReference(transactionType: refRaw);
    }

    return Payment(
      id: json['id'] as int? ?? 0,
      amount: parseDouble(json['amount']),
      currency: json['currency'] as String? ?? 'JOD',
      status: json['status'] as String? ?? 'pending',
      purpose: json['purpose'] as String?,
      referenceId: json['reference_id'] as int? ?? json['referenceId'] as int?,
      projectTitle: json['project_title'] as String?,
      createdAt: parseDateTime(
        json['date'] ?? json['createdAt'] ?? json['created_at'],
      ),
      type: json['type'] as String?,
      note: json['note'] as String?,
      method: json['method'] as String?,
      source: source,
      title: title,
      description: description,
      project: parseProject(json['project'] as Map<String, dynamic>?),
      reference: ref,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'status': status,
      'purpose': purpose,
      'reference_id': referenceId,
      'project_title': projectTitle,
      'created_at': createdAt.toIso8601String(),
      'type': type,
      'note': note,
      'method': method,
      'source': source,
      'title': title,
      'description': description,
      'project': project != null
          ? {
              'projectId': project!.projectId,
              'title': project!.title,
              'clientId': project!.clientId,
              'freelancerId': project!.freelancerId,
            }
          : null,
      'reference': reference != null
          ? {
              'paymentId': reference!.paymentId,
              'purpose': reference!.purpose,
              'referenceId': reference!.referenceId,
              'stripeSessionId': reference!.stripeSessionId,
              'stripePaymentIntent': reference!.stripePaymentIntent,
              'transactionId': reference!.transactionId,
              'type': reference!.transactionType,
            }
          : null,
    };
  }
}

class PaymentProject {
  final int projectId;
  final String title;
  final int? clientId;
  final int? freelancerId;

  PaymentProject({
    required this.projectId,
    required this.title,
    this.clientId,
    this.freelancerId,
  });
}

class PaymentReference {
  final int? paymentId;
  final String? purpose;
  final int? referenceId;
  final String? stripeSessionId;
  final String? stripePaymentIntent;
  final int? transactionId; // For wallet transactions
  final String? transactionType; // 'credit' or 'debit' for wallet

  PaymentReference({
    this.paymentId,
    this.purpose,
    this.referenceId,
    this.stripeSessionId,
    this.stripePaymentIntent,
    this.transactionId,
    this.transactionType,
  });
}
