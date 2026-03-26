// ??? ????????
/// In-memory legal content matching web Policy.jsx, Terms.jsx, and Faq.jsx.
/// Use [getPrivacyContent], [getTermsContent], and [defaultFaqs].
library;

class LegalSection {
  final String id;
  final String title;
  final List<String> bullets;
  final String body;

  const LegalSection({
    required this.id,
    required this.title,
    this.bullets = const [],
    this.body = '',
  });
}

/// FAQ item: question and answer (from Faq.jsx DEFAULT_FAQS).
class FaqItem {
  final String q;
  final String a;

  const FaqItem({required this.q, required this.a});
}

class DataLifecycleStep {
  final String title;
  final String desc;

  const DataLifecycleStep({required this.title, required this.desc});
}

class PrivacyContent {
  final List<LegalSection> sections;
  final String lifecycleTitle;
  final String lifecycleSubtitle;
  final List<DataLifecycleStep> lifecycleSteps;
  final String lastUpdated;

  const PrivacyContent({
    required this.sections,
    required this.lifecycleTitle,
    required this.lifecycleSubtitle,
    required this.lifecycleSteps,
    required this.lastUpdated,
  });
}

class TermsContentData {
  final List<LegalSection> sections;
  final String lastUpdated;
  final String version;
  final String callout;

  const TermsContentData({
    required this.sections,
    required this.lastUpdated,
    required this.version,
    required this.callout,
  });
}

// --- Privacy Policy (EN) - matches Policy.jsx ---
const List<LegalSection> privacyPolicyEn = [
  LegalSection(
    id: 'intro',
    title: 'Introduction',
    body:
        'We keep things concise and human-friendly. We never sell your data. We only process what is necessary to run the platform, improve reliability, and keep your account secure.',
    bullets: [
      'We respect your privacy and aim for full transparency.',
      'This policy explains what we collect, why, and how we use it.',
      'Using our platform means you agree to this policy.',
    ],
  ),
  LegalSection(
    id: 'collection',
    title: 'What We Collect',
    body:
        'We collect the minimum data required to create your account, personalize your experience, and protect the system from abuse. Certain features store preferences locally in your browser.',
    bullets: [
      'Account data: name, email, role (Admin / Client / Freelancer).',
      'Usage data: pages viewed, preferences, diagnostics.',
      'Files: profile images and attachments related to projects.',
    ],
  ),
  LegalSection(
    id: 'cookies',
    title: 'Cookies & Preferences',
    body:
        'Cookies simplify your experience (remembering language, dark mode) and secure sessions. You can refuse some cookies, but a few features may not work as expected.',
    bullets: [
      'Session cookies to keep you signed in securely.',
      'Preference cookies for language and theme.',
      'You can control them from your browser settings.',
    ],
  ),
  LegalSection(
    id: 'sharing',
    title: 'Sharing & Third Parties',
    body:
        'We may rely on reputable vendors to deliver parts of the service. They are bound by data-protection agreements and only receive data required to perform their tasks.',
    bullets: [
      'We do not sell your data to advertisers.',
      'Trusted providers for email, storage, and analytics only.',
      'We share the least amount of information necessary.',
    ],
  ),
  LegalSection(
    id: 'security',
    title: 'Security & Access',
    body:
        'We secure traffic with TLS, restrict staff access by role, apply logging/alerting, and review our controls regularly. If a breach occurs, we will notify affected users where required by law.',
    bullets: [
      'Encryption in transit (HTTPS).',
      'Role-based internal access (principle of least privilege).',
      'Periodic reviews and abuse monitoring.',
    ],
  ),
  LegalSection(
    id: 'rights',
    title: 'Your Rights',
    body:
        'Contact us to exercise your rights. We will verify your identity and respond within a reasonable timeframe according to applicable regulations.',
    bullets: [
      'Access and receive a copy of your data.',
      'Request correction or deletion where possible.',
      'Withdraw consent and exercise data portability.',
    ],
  ),
];

const String _privacyLifecycleTitleEn = 'Data Lifecycle';
const String _privacyLifecycleSubtitleEn =
    'How your data travels through our system — from collection to deletion.';
const List<DataLifecycleStep> _privacyLifecycleStepsEn = [
  DataLifecycleStep(
    title: 'Collect (Minimal)',
    desc:
        'We only ask for the essentials to create your account and deliver core features.',
  ),
  DataLifecycleStep(
    title: 'Store (Encrypted in transit)',
    desc:
        'Traffic uses TLS (HTTPS). Storage uses secure, access-controlled services.',
  ),
  DataLifecycleStep(
    title: 'Use (Purpose-bound)',
    desc:
        'We use data solely to operate the platform, improve quality, and prevent abuse.',
  ),
  DataLifecycleStep(
    title: 'Share (When necessary)',
    desc:
        'Limited sharing with trusted providers under data-protection agreements.',
  ),
  DataLifecycleStep(
    title: 'Delete / Export (Your control)',
    desc:
        'You can request deletion or a portable copy; we respect applicable regulations.',
  ),
];
const String _privacyLastUpdatedEn = "Jan 2025 — We'll post updates here.";

// --- Privacy Policy (AR) ---
const List<LegalSection> privacyPolicyAr = [
  LegalSection(
    id: 'intro',
    title: 'المقدمة',
    body:
        'نحافظ على وضوح وسلاسة النص. لا نبيع بياناتك أبداً. نعالج فقط ما يلزم لتشغيل المنصة وتحسين الموثوقية وحماية حسابك.',
    bullets: [
      'نحترم خصوصيتك ونسعى للشفافية الكاملة.',
      'توضح هذه السياسة ما نجمع ولماذا وكيف نستخدمه.',
      'استخدام المنصة يعني موافقتك على هذه السياسة.',
    ],
  ),
  LegalSection(
    id: 'collection',
    title: 'ما الذي نجمع',
    body:
        'نجمع الحد الأدنى من البيانات اللازمة لإنشاء حسابك وتخصيص تجربتك وحماية النظام من سوء الاستخدام. بعض الميزات تخزن التفضيلات محلياً في متصفحك.',
    bullets: [
      'بيانات الحساب: الاسم، البريد الإلكتروني، الدور (مسؤول / عميل / مستقل).',
      'بيانات الاستخدام: الصفحات المعروضة، التفضيلات، التشخيصات.',
      'الملفات: صور الملف الشخصي والمرفقات المتعلقة بالمشاريع.',
    ],
  ),
  LegalSection(
    id: 'cookies',
    title: 'ملفات تعريف الارتباط والتفضيلات',
    body:
        'ملفات تعريف الارتباط تسهّل تجربتك (تذكر اللغة، الوضع الداكن) وتؤمن الجلسات. يمكنك رفض بعضها، لكن بعض الميزات قد لا تعمل كما هو متوقع.',
    bullets: [
      'ملفات جلسة لإبقائك مسجلاً الدخول بشكل آمن.',
      'ملفات تفضيلات للغة والمظهر.',
      'يمكنك التحكم بها من إعدادات المتصفح.',
    ],
  ),
  LegalSection(
    id: 'sharing',
    title: 'المشاركة والأطراف الثالثة',
    body:
        'قد نعتمد على مزودين موثوقين لتقديم أجزاء من الخدمة. هم ملتزمون باتفاقيات حماية البيانات ويستلمون فقط البيانات اللازمة لأداء مهامهم.',
    bullets: [
      'لا نبيع بياناتك للمعلنين.',
      'مزودون موثوقون للبريد والتخزين والتحليلات فقط.',
      'نشارك أقل قدر ضروري من المعلومات.',
    ],
  ),
  LegalSection(
    id: 'security',
    title: 'الأمان والوصول',
    body:
        'نؤمن الحركة عبر TLS، ونقيّد وصول الموظفين حسب الدور، ونطبق التسجيل والتنبيهات، ونراجع ضوابطنا بانتظام. في حال حدوث خرق، سنُعلم المستخدمين المتأثرين حيث يقتضي القانون.',
    bullets: [
      'تشفير أثناء النقل (HTTPS).',
      'وصول داخلي قائم على الأدوار (مبدأ أقل صلاحية).',
      'مراجعات دورية ومراقبة إساءة الاستخدام.',
    ],
  ),
  LegalSection(
    id: 'rights',
    title: 'حقوقك',
    body:
        'تواصل معنا لممارسة حقوقك. سنتحقق من هويتك ونرد في غضون فترة معقولة وفقاً للأنظمة المعمول بها.',
    bullets: [
      'الوصول والحصول على نسخة من بياناتك.',
      'طلب التصحيح أو الحذف حيثما أمكن.',
      'سحب الموافقة وممارسة إمكانية نقل البيانات.',
    ],
  ),
];

const String _privacyLifecycleTitleAr = 'دورة حياة البيانات';
const String _privacyLifecycleSubtitleAr =
    'كيف تنتقل بياناتك في نظامنا — من الجمع إلى الحذف.';
const List<DataLifecycleStep> _privacyLifecycleStepsAr = [
  DataLifecycleStep(
    title: 'الجمع (الحد الأدنى)',
    desc: 'نطلب فقط الأساسيات لإنشاء حسابك وتقديم الميزات الأساسية.',
  ),
  DataLifecycleStep(
    title: 'التخزين (مشفّر أثناء النقل)',
    desc:
        'الحركة تستخدم TLS (HTTPS). التخزين يستخدم خدمات آمنة ومُتحكم بالوصول إليها.',
  ),
  DataLifecycleStep(
    title: 'الاستخدام (مرتبط بالغرض)',
    desc: 'نستخدم البيانات فقط لتشغيل المنصة وتحسين الجودة ومنع الإساءة.',
  ),
  DataLifecycleStep(
    title: 'المشاركة (عند الضرورة)',
    desc: 'مشاركة محدودة مع مزودين موثوقين بموجب اتفاقيات حماية البيانات.',
  ),
  DataLifecycleStep(
    title: 'الحذف / التصدير (تحكمك)',
    desc: 'يمكنك طلب الحذف أو نسخة قابلة للنقل؛ نحترم الأنظمة المعمول بها.',
  ),
];
const String _privacyLastUpdatedAr = 'كانون الثاني 2025';

// --- Terms & Conditions (EN) - matches Terms.jsx ---
const String termsLastUpdatedEn = 'Oct 5, 2025';
const String termsVersionEn = 'v1.0';
const String termsCalloutEn =
    "This page provides general terms for a freelance marketplace. It's not legal advice. Please consult a qualified attorney to adapt these terms for your jurisdiction and business.";
const List<LegalSection> termsEn = [
  LegalSection(
    id: 'definitions',
    title: '1) Definitions',
    body: '',
    bullets: [
      'Platform: the website/app operated by Your Company.',
      'Client: a user who purchases services via the Platform.',
      'Freelancer: a user who offers services via the Platform.',
      'Order: an agreement between a Client and a Freelancer formed within the Platform, including deliverables and price.',
    ],
  ),
  LegalSection(
    id: 'accounts',
    title: '2) Accounts & Eligibility',
    body:
        'You must be at least 18 years old (or the age of majority in your country) to create an account. You agree to provide accurate information and keep your credentials secure. We may require identity or payment verification to help prevent fraud.',
    bullets: [],
  ),
  LegalSection(
    id: 'acceptable-use',
    title: '3) Acceptable Use',
    body: '',
    bullets: [
      'No unlawful, harmful, or hateful content or activities.',
      'No intellectual property infringement or spam.',
      'All negotiations and payments must remain inside the Platform. Attempting to circumvent fees may result in account suspension.',
    ],
  ),
  LegalSection(
    id: 'orders',
    title: '4) Orders, Offers & Communication',
    body:
        'Freelancers must describe services clearly (scope, timeline, deliverables). Clients must provide timely and complete requirements. Platform messaging is the primary channel for agreements and changes related to an Order.',
    bullets: [],
  ),
  LegalSection(
    id: 'payments',
    title: '5) Payments, Fees & Escrow',
    body:
        'Payments are processed via our payment partner and may be held in escrow until delivery is confirmed or a grace period elapses. The Platform charges a service fee of 10% on each successful transaction.',
    bullets: [],
  ),
  LegalSection(
    id: 'delivery',
    title: '6) Delivery, Revisions & Cancellation',
    body: '',
    bullets: [
      'Work is delivered through the Order page in the agreed format.',
      'Clients may request up to 2 revisions when within the agreed scope.',
      'Orders can be canceled before work starts or as per the service policy, considering work already performed.',
    ],
  ),
  LegalSection(
    id: 'refunds',
    title: '7) Refunds & Disputes',
    body:
        'If a dispute arises, either party may open a case. We review the conversation and files to decide fairly. If work wasn\'t delivered as described, a refund may be issued; otherwise, funds may be released to the Freelancer. Our dispute decisions are final within reasonable limits.',
    bullets: [],
  ),
  LegalSection(
    id: 'ip',
    title: '8) Intellectual Property & Confidentiality',
    body: '',
    bullets: [
      'Unless stated otherwise, intellectual property in the final deliverables transfers to the Client upon full payment.',
      'Freelancers warrant originality and non-infringement and accept responsibility for third-party claims.',
      'Both parties must protect confidential information shared during the Order.',
    ],
  ),
  LegalSection(
    id: 'reviews',
    title: '9) Ratings & Reviews',
    body:
        'Reviews must be honest, respectful, and based on real experience. We may remove feedback that is abusive, irrelevant, or violates these Terms.',
    bullets: [],
  ),
  LegalSection(
    id: 'suspension',
    title: '10) Suspension & Termination',
    body:
        'We may suspend or terminate accounts for violations, suspected fraud, or attempts to circumvent the Platform\'s processes and fees.',
    bullets: [],
  ),
  LegalSection(
    id: 'liability',
    title: '11) Disclaimer & Liability',
    body:
        'The Platform is provided on an "as is" basis. To the maximum extent permitted by law, we disclaim warranties and limit liability for indirect or consequential losses. Any liability is capped at the total fees we received for the transaction in dispute.',
    bullets: [],
  ),
  LegalSection(
    id: 'changes',
    title: '12) Changes & Governing Law',
    body:
        'We may update these Terms. For material changes, we will notify users and may request re-acceptance. These Terms are governed by the laws of Jordan and subject to its courts.',
    bullets: [],
  ),
  LegalSection(
    id: 'contact',
    title: '13) Contact',
    body: 'Questions? Contact us at info@battechno.com.',
    bullets: [],
  ),
];

// --- Terms & Conditions (AR) ---
const String termsLastUpdatedAr = '5 تشرين الأول 2025';
const String termsVersionAr = 'v1.0';
const String termsCalloutAr =
    'هذه الصفحة تقدّم شروطاً عامة لسوق عمل حر. ليست استشارة قانونية. يُرجى استشارة محامٍ مؤهل لملاءمة هذه الشروط لاختصاصك ونشاطك.';
const List<LegalSection> termsAr = [
  LegalSection(
    id: 'definitions',
    title: '١) التعريفات',
    body: '',
    bullets: [
      'المنصة: الموقع/التطبيق الذي تديره شركتك.',
      'العميل: مستخدم يشتري الخدمات عبر المنصة.',
      'المستقل: مستخدم يقدم الخدمات عبر المنصة.',
      'الطلب: اتفاق بين عميل ومستقل يتم داخل المنصة، ويشمل المخرجات والسعر.',
    ],
  ),
  LegalSection(
    id: 'accounts',
    title: '٢) الحسابات والأهلية',
    body:
        'يجب أن يكون عمرك 18 عاماً على الأقل (أو سن الرشد في بلدك) لإنشاء حساب. أنت توافق على تقديم معلومات دقيقة والحفاظ على أمان بيانات الدخول. قد نطلب التحقق من الهوية أو الدفع للمساعدة في منع الاحتيال.',
    bullets: [],
  ),
  LegalSection(
    id: 'acceptable-use',
    title: '٣) الاستخدام المقبول',
    body: '',
    bullets: [
      'لا محتوى أو أنشطة غير قانونية أو ضارة أو تحض على الكراهية.',
      'لا انتهاك للملكية الفكرية أو رسائل مزعجة.',
      'يجب أن تبقى جميع المفاوضات والمدفوعات داخل المنصة. محاولة التحايل على الرسوم قد تؤدي إلى تعليق الحساب.',
    ],
  ),
  LegalSection(
    id: 'orders',
    title: '٤) الطلبات والعروض والتواصل',
    body:
        'على المستقلين وصف الخدمات بوضوح (النطاق، الجدول الزمني، المخرجات). على العملاء تقديم المتطلبات في الوقت المناسب وبشكل كامل. رسائل المنصة هي القناة الأساسية للاتفاقيات والتغييرات المتعلقة بالطلب.',
    bullets: [],
  ),
  LegalSection(
    id: 'payments',
    title: '٥) المدفوعات والرسوم والضمان',
    body:
        'تُعالج المدفوعات عبر شريك الدفع وقد تُحتجز في الضمان حتى يتم تأكيد التسليم أو انتهاء فترة السماح. تفرض المنصة رسوم خدمة 10٪ على كل معاملة ناجحة.',
    bullets: [],
  ),
  LegalSection(
    id: 'delivery',
    title: '٦) التسليم والمراجعات والإلغاء',
    body: '',
    bullets: [
      'يُسلّم العمل عبر صفحة الطلب بالصيغة المتفق عليها.',
      'يمكن للعملاء طلب حتى مراجعتين عند الالتزام بالنطاق المتفق عليه.',
      'يمكن إلغاء الطلبات قبل بدء العمل أو وفق سياسة الخدمة، مع مراعاة العمل المنفذ مسبقاً.',
    ],
  ),
  LegalSection(
    id: 'refunds',
    title: '٧) الاسترداد والنزاعات',
    body:
        'إذا نشأ نزاع، يمكن لأي طرف فتح قضية. نراجع المحادثة والملفات للبت بعدالة. إن لم يُسلّم العمل كما هو موصوف، قد يُصدر استرداد؛ وإلا قد تُطلق الأموال للمستقل. قراراتنا في النزاعات نهائية ضمن حدود معقولة.',
    bullets: [],
  ),
  LegalSection(
    id: 'ip',
    title: '٨) الملكية الفكرية والسرية',
    body: '',
    bullets: [
      'ما لم يُذكر خلاف ذلك، تنتقل الملكية الفكرية في المخرجات النهائية إلى العميل عند الدفع الكامل.',
      'المستقلون يضمنون الأصالة وعدم الانتهاك ويقبلون المسؤولية عن مطالبات الأطراف الثالثة.',
      'على الطرفين حماية المعلومات السرية المتبادلة أثناء الطلب.',
    ],
  ),
  LegalSection(
    id: 'reviews',
    title: '٩) التقييمات والمراجعات',
    body:
        'يجب أن تكون المراجعات صادقة ومحترمة ومبنية على تجربة حقيقية. قد نزيل التعليقات المسيئة أو غير ذات الصلة أو المخالفة لهذه الشروط.',
    bullets: [],
  ),
  LegalSection(
    id: 'suspension',
    title: '١٠) التعليق والإنهاء',
    body:
        'قد نعلق الحسابات أو ننهيها بسبب المخالفات أو الاشتباه بالاحتيال أو محاولات التحايل على إجراءات المنصة ورسومها.',
    bullets: [],
  ),
  LegalSection(
    id: 'liability',
    title: '١١) إخلاء المسؤولية والمسؤولية القانونية',
    body:
        'تُقدّم المنصة "كما هي". إلى أقصى حد يسمح به القانون، نتنصل من الضمانات ونحد المسؤولية عن الخسائر غير المباشرة أو التبعية. أي مسؤولية محدودة بإجمالي الرسوم التي تلقيناها عن المعاملة محل النزاع.',
    bullets: [],
  ),
  LegalSection(
    id: 'changes',
    title: '١٢) التغييرات والقانون الحاكم',
    body:
        'قد نحدّث هذه الشروط. للتغييرات الجوهرية سنُعلم المستخدمين وقد نطلب إعادة القبول. تخضع هذه الشروط لقوانين الأردن ومحاكمها.',
    bullets: [],
  ),
  LegalSection(
    id: 'contact',
    title: '١٣) التواصل',
    body: 'أسئلة؟ تواصل معنا على info@battechno.com',
    bullets: [],
  ),
];

PrivacyContent getPrivacyContent(String languageCode) {
  final isAr = languageCode.toLowerCase().startsWith('ar');
  return PrivacyContent(
    sections: isAr ? privacyPolicyAr : privacyPolicyEn,
    lifecycleTitle: isAr ? _privacyLifecycleTitleAr : _privacyLifecycleTitleEn,
    lifecycleSubtitle: isAr
        ? _privacyLifecycleSubtitleAr
        : _privacyLifecycleSubtitleEn,
    lifecycleSteps: isAr ? _privacyLifecycleStepsAr : _privacyLifecycleStepsEn,
    lastUpdated: isAr ? _privacyLastUpdatedAr : _privacyLastUpdatedEn,
  );
}

TermsContentData getTermsContent(String languageCode) {
  final isAr = languageCode.toLowerCase().startsWith('ar');
  return TermsContentData(
    sections: isAr ? termsAr : termsEn,
    lastUpdated: isAr ? termsLastUpdatedAr : termsLastUpdatedEn,
    version: isAr ? termsVersionAr : termsVersionEn,
    callout: isAr ? termsCalloutAr : termsCalloutEn,
  );
}

// --- FAQ (from Faq.jsx DEFAULT_FAQS) - exact same Q/A strings ---
const List<FaqItem> defaultFaqs = [
  FaqItem(
    q: 'Do you offer a free trial?',
    a: 'No, a free trial is not necessary because we already provide a free plan.',
  ),
  FaqItem(
    q: 'Can I upgrade or downgrade my plan?',
    a: 'Yes, but only after your current subscription period ends.',
  ),
  FaqItem(
    q: 'Can I freeze my plan subscription?',
    a: 'No, plans cannot be frozen.',
  ),
  FaqItem(
    q: 'When does my plan period start?',
    a: 'The plan time counter starts after you receive your first project.',
  ),
  FaqItem(
    q: 'Can I deactivate my account?',
    a: 'Yes, you can deactivate your account, but only if you do not have any in-progress projects.',
  ),
  FaqItem(
    q: 'What happens if I miss a project deadline?',
    a: 'If project deadlines are not met, the contract may be terminated.',
  ),
  FaqItem(
    q: 'Do I need to pay for additional services?',
    a: 'Any additional services outside your selected plan may require extra fees, which will be clearly communicated before purchase.',
  ),
  FaqItem(
    q: 'Are refunds available?',
    a: 'No refunds or returns are offered once a subscription is active.',
  ),
  FaqItem(
    q: 'Is the free plan truly free?',
    a: 'Yes, the free plan includes limited features to get started with no payment required.',
  ),
  FaqItem(
    q: 'Can I switch between monthly and annual billing?',
    a: 'You can choose your billing cycle when subscribing, but changes can only occur at the end of the current subscription period.',
  ),
  FaqItem(
    q: 'Are there any hidden fees?',
    a: 'No, all fees including the one-time verification fee are clearly stated during the subscription process.',
  ),
  FaqItem(
    q: 'What if I want to cancel my subscription?',
    a: 'You may cancel at any time, but no refunds are provided and your current plan will remain active until the end of the subscription period.',
  ),
  FaqItem(
    q: 'Can I have multiple projects under the same plan?',
    a: 'Yes, your plan supports multiple projects, but the plan time counter starts when your first project is assigned.',
  ),
];
