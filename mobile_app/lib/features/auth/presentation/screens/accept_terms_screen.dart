// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user.dart';
import '../../../../core/ui/screenutil_helpers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/models/terms_content.dart';
import '../../../../core/providers/locale_provider.dart';
import '../providers/auth_provider.dart';

class AcceptTermsScreen extends ConsumerStatefulWidget {
  const AcceptTermsScreen({super.key});

  @override
  ConsumerState<AcceptTermsScreen> createState() => _AcceptTermsScreenState();
}

class _AcceptTermsScreenState extends ConsumerState<AcceptTermsScreen> {
  bool _agreed = false;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final locale = ref.watch(localeProvider);
        final termsContent = TermsContent.getContent(locale.languageCode);
        final isArabic = locale.languageCode == 'ar';

        return PopScope(
          canPop: false, // Block back navigation
          onPopInvoked: (bool didPop) {
            // Prevent back navigation - user must accept terms
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: AppContentLayout.contentMaxWidth(context),
                  ),
                  child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        // No back button - user must accept terms
                        const Spacer(),
                        Text(
                          isArabic ? 'الشروط والأحكام' : 'Terms & Conditions',
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fundamental Terms Section (unchanged)
                          _buildSection(
                            title: termsContent.fundamentalTerms.title,
                            content: termsContent.fundamentalTerms.terms.join(
                              '\n\n',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          // Refund Policy Section
                          _buildSection(
                            title: isArabic
                                ? 'سياسة الاسترداد'
                                : 'Refund Policy',
                            content: _getRefundPolicyContent(isArabic),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          // Agreement Checkbox
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _agreed,
                                onChanged: (value) {
                                  setState(() {
                                    _agreed = value ?? false;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    isArabic
                                        ? 'لقد قرأت وأوافق على الشروط والأحكام وسياسة الاسترداد'
                                        : 'I have read and agree to the Terms & Conditions and Refund Policy',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ),
                  // Accept Button
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: PrimaryGradientButton(
                      label: isArabic ? 'قبول والمتابعة' : 'Accept & Continue',
                      onPressed: _agreed && !_isSubmitting
                          ? _handleAccept
                          : null,
                      isLoading: _isSubmitting,
                      height: 54,
                      borderRadius: 16,
                    ),
                  ),
                ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF374151),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAccept() async {
    setState(() => _isSubmitting = true);

    final authNotifier = ref.read(authStateProvider.notifier);
    final success = await authNotifier.acceptTerms();

    if (!mounted) return;

    if (success) {
      final user = ref.read(authStateProvider).user;
      final role = ref.read(authStateProvider).userRole;
      if (user?.isAdmin == true) {
        context.go('/admin');
      } else if (role == 'freelancer') {
        context.go('/freelancer');
      } else if (role == 'client') {
        context.go('/client');
      } else {
        context.go('/client');
      }
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authStateProvider).error ?? 'Failed to accept terms',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getRefundPolicyContent(bool isArabic) {
    if (isArabic) {
      return '''سياسة الاسترداد – ORDERZHOUSE

في ORDERZHOUSE، نسعى لتوفير سوق آمن وعادل لكل من العملاء ومقدمي الخدمات. تعمل ORDERZHOUSE كوسيط رقمي ينظم الطلبات، ويؤمن المدفوعات، ويدير النزاعات. توضح هذه السياسة كيفية عمل الاستردادات، مع المبدأ الرئيسي أن الاستردادات المعتمدة تُعاد إلى محفظة ORDERZHOUSE للمستخدم لاستخدامها في المشتريات المستقبلية.

1) التعريفات
العميل: المستخدم الذي يشتري/يطلب خدمة.
مقدم الخدمة: المستخدم الذي يقدم الخدمة المطلوبة.
الطلب: أي خدمة يتم شراؤها من خلال ORDERZHOUSE.
المحفظة: رصيد ائتماني داخل المنصة متاح للطلبات المستقبلية.

2) الاحتفاظ بالدفع (نمط الضمان)
عندما يدفع العميل مقابل طلب، يتم الاحتفاظ بالمبلغ داخل المنصة لحماية الطرفين. يتم تحرير الأموال لمقدم الخدمة بعد تأكيد التسليم أو بعد انتهاء نافذة النزاع (حسب ما ينطبق من قواعد حالة الطلب في المنصة).

3) طريقة الاسترداد الأساسية (رصيد المحفظة)
إذا تم اعتماد استرداد، يتم إضافة المبلغ المسترد (كامل أو جزئي) إلى محفظة ORDERZHOUSE للعميل.
يمكن استخدام رصيد المحفظة فورًا لأي طلب مستقبلي على المنصة.
لا تتم معالجة الاستردادات كتحويلات نقدية/خارج المنصة إلا إذا قررت ORDERZHOUSE خلاف ذلك في حالات استثنائية.

4) حالات الاسترداد المؤهلة
يمكن للعميل طلب استرداد/نزاع في الحالات التالية:
- عدم تسليم الخدمة خلال الإطار الزمني المتفق عليه دون سبب مقبول.
- التسليم الذي لا يتطابق بشكل كبير مع الوصف في قائمة الخدمة.
- رفض مقدم الخدمة المتابعة أو التوقف عن العمل دون إكمال النطاق المتفق عليه.
- إلغاء الطلب قبل بدء العمل، حسب حالة الطلب.
- شحنة مكررة أو خطأ في معالجة الدفع.

5) حالات غير قابلة للاسترداد / غير مغطاة
قد يتم رفض الاستردادات في هذه الحالات:
- تم تسليم الخدمة كما تم الاتفاق والمشكلة مبنية على التفضيل الشخصي.
- متطلبات غير صحيحة أو غير مكتملة قدمها العميل.
- خدمات مخصصة للغاية حيث بدأ العمل بالفعل دون سبب مقبول.
- انتهت فترة النزاع دون تقديم مطالبة.

6) كيفية تقديم نزاع
انتقل إلى طلباتي → اختر الطلب → فتح نزاع / طلب استرداد.
قدم تفاصيل واضحة وأدلة إن أمكن.

7) الجدول الزمني لمراجعة النزاع (21 يومًا)
تصدر ORDERZHOUSE قرارًا نهائيًا في غضون 21 يومًا كحد أقصى.
يتم إضافة الاستردادات المعتمدة إلى المحفظة بعد المراجعة (أو في وقت أقرب إذا تم الحل عاجلاً).

8) الاستردادات الجزئية
قد تنطبق الاستردادات الجزئية عندما يتم تسليم جزء من الخدمة بشكل صحيح.
يتم تحديد مبلغ الاسترداد بناءً على الأدلة والتقييم.

9) منع الإساءة والاحتيال
قد ترفض ORDERZHOUSE الطلبات المسيئة، أو تعليق الحسابات، أو اتخاذ إجراءات لحماية المنصة.

10) الدعم
اتصل بالدعم مع رقم الطلب، وسبب النزاع، والأدلة.''';
    }

    return '''Refund Policy – ORDERZHOUSE

At ORDERZHOUSE, we aim to provide a safe and fair marketplace for both Clients and Service Providers. ORDERZHOUSE acts as a digital intermediary that organizes orders, secures payments, and manages disputes. This policy explains how refunds work, with the main principle that approved refunds are returned to the user's ORDERZHOUSE Wallet to be used for future purchases.

1) Definitions
Client: The user who purchases/requests a service.
Service Provider: The user who delivers the requested service.
Order: Any service purchased through ORDERZHOUSE.
Wallet: An in-platform credit balance available for future orders.

2) Payment Holding (Escrow-Style)
When a Client pays for an order, the amount is held within the platform to protect both parties. Funds are released to the Service Provider after delivery confirmation or after the dispute window ends (as applicable by the platform's order status rules).

3) Primary Refund Method (Wallet Credit)
If a refund is approved, the refunded amount (full or partial) is credited to the Client's ORDERZHOUSE Wallet.
Wallet credit can be used immediately for any future order on the platform.
Refunds are not processed as cash-out/off-platform transfers unless ORDERZHOUSE decides otherwise in exceptional cases.

4) Eligible Refund Cases
A Client may request a refund/dispute in the following situations:
- Non-delivery of the service within the agreed timeframe without a valid reason.
- Delivery that is materially not as described in the service listing.
- The Service Provider refuses to proceed or stops working without completing the agreed scope.
- Order cancellation before work begins, depending on the order status.
- Duplicate charge or payment processing error.

5) Non-Refundable / Not Covered Cases
Refunds may be declined in these cases:
- The service was delivered as agreed and the issue is based on personal preference.
- Incorrect or incomplete requirements provided by the Client.
- Highly customized services where work has already started without a valid reason.
- Dispute period expired without a submitted claim.

6) How to Submit a Dispute
Go to My Orders → Select order → Open Dispute / Request Refund.
Provide clear details and evidence if available.

7) Dispute Review Timeline (21 Days)
ORDERZHOUSE issues a final decision within a maximum of 21 days.
Approved refunds are credited to the Wallet after review (or earlier if resolved sooner).

8) Partial Refunds
Partial refunds may apply when part of the service is delivered correctly.
The refund amount is determined based on evidence and assessment.

9) Abuse & Fraud Prevention
ORDERZHOUSE may reject abusive requests, suspend accounts, or take action to protect the platform.

10) Support
Contact support with order number, dispute reason, and evidence.''';
  }
}
