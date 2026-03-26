// ??? ????????
import 'package:url_launcher/url_launcher.dart';

/// WhatsApp number for OrderzHouse support / payment confirmation (same as web).
const String orderzHouseWhatsAppNumber = '962791433341';

/// Opens WhatsApp with a pre-filled text. [message] will be URL-encoded.
Future<bool> launchWhatsAppWithMessage(String message) async {
  final encoded = Uri.encodeComponent(message);
  final candidates = <Uri>[
    Uri.parse('whatsapp://send?phone=$orderzHouseWhatsAppNumber&text=$encoded'),
    Uri.parse('https://wa.me/$orderzHouseWhatsAppNumber?text=$encoded'),
    Uri.parse(
      'https://api.whatsapp.com/send?phone=$orderzHouseWhatsAppNumber&text=$encoded',
    ),
  ];

  for (final uri in candidates) {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return true;
    }
  }

  // Last fallback: allow platform default behavior.
  for (final uri in candidates) {
    if (await launchUrl(uri, mode: LaunchMode.platformDefault)) {
      return true;
    }
  }

  return false;
}

/// Builds the CliQ confirmation message for project success screen.
String buildCliqWhatsAppMessage({
  required int projectId,
  required String title,
  required String amountText,
}) {
  return 'Hello, I paid via CliQ for Project #$projectId ($title). Amount: $amountText JOD. Please find the payment screenshot attached.';
}

/// Builds full project success message (like web) for WhatsApp.
String buildProjectSuccessWhatsAppMessage({
  required int projectId,
  required String title,
  required String budgetText,
  required String paymentMethod,
  required String? approvalStatus,
  required String? categoryInfo,
  required String? durationText,
  required String? skillsJoined,
  required String? shortDescription,
  bool isArabic = false,
}) {
  if (isArabic) {
    var msg =
        'تم إنشاء مشروع جديد بنجاح:\n\nرقم المشروع: #$projectId\nالعنوان: $title\nالميزانية: $budgetText\nطريقة الدفع: $paymentMethod\nحالة موافقة الإدارة: ${approvalStatus ?? "—"}\nالتصنيف: ${categoryInfo ?? "—"}\nالمدة: ${durationText ?? "—"}\nالمهارات: ${skillsJoined ?? "—"}\n\nالوصف: ${shortDescription ?? "—"}';
    if (paymentMethod.toLowerCase().contains('cliq')) {
      msg +=
          '\n\nتم اختيار الدفع عبر CliQ — يرجى إرسال صورة (Screenshot) من الدفعة لتأكيد الدفع.';
    }
    return msg;
  }
  var msg =
      'New project created successfully:\n\nProject ID: #$projectId\nTitle: $title\nBudget: $budgetText\nPayment Method: $paymentMethod\nAdmin Approval: ${approvalStatus ?? "—"}\nCategory: ${categoryInfo ?? "—"}\nDuration: ${durationText ?? "—"}\nSkills: ${skillsJoined ?? "—"}\n\nDescription: ${shortDescription ?? "—"}';
  if (paymentMethod.toLowerCase().contains('cliq')) {
    msg +=
        '\n\nCliQ payment selected — please send a screenshot of your CliQ payment to confirm.';
  }
  return msg;
}
