// ??? ????????
/// Reusable Terms & Conditions content structure
/// Supports both Arabic and English localization
class TermsContent {
  final String language;
  final List<TermsSection> sections;
  final FundamentalTerms fundamentalTerms;

  const TermsContent({
    required this.language,
    required this.sections,
    required this.fundamentalTerms,
  });

  static const TermsContent arabic = TermsContent(
    language: 'ar',
    fundamentalTerms: FundamentalTerms.arabic,
    sections: [
      TermsSection(
        number: 1,
        title: 'المقدمة',
        paragraphs: [
          'تُعد مقدمة هذا العقد جزءًا لا يتجزأ منه وتقرأ معه كوحدة واحدة.',
        ],
      ),
      TermsSection(
        number: 2,
        title: 'التزامات الطرف الثاني',
        paragraphs: [
          'يوافق الطرف الثاني على تقديم وإنجاز المهام الموكلة إليه من الطرف الأول أو عملائه، ضمن الوظيفة المحددة في هذا العقد، عبر المنصة الإلكترونية المعتمدة أو أي وسيلة أخرى يحددها الطرف الأول.',
        ],
      ),
      TermsSection(
        number: 3,
        title: 'تفاصيل المهام',
        paragraphs: [
          'يتم إرسال المهام للطرف الثاني مع تحديد تفاصيلها وشروطها، ويُعتبر تنفيذها وفق المواصفات جزءًا أساسيًا من الالتزام التعاقدي.',
        ],
      ),
      TermsSection(
        number: 4,
        title: 'دليل المخالفات',
        paragraphs: [
          'يُعد توقيع الطرف الثاني على هذا العقد بمثابة إقرار منه بالاطلاع والموافقة على دليل المخالفات والإجراءات الداخلية المعتمد من الطرف الأول، ويُعمل بذلك الدليل كملحق أساسي للعقد.',
        ],
      ),
      TermsSection(
        number: 5,
        title: 'حل النزاعات',
        paragraphs: [
          'في حال نشأ خلاف بين الطرفين، يتم حله عن طريق التحكيم وفقًا للقوانين المعمول بها في المملكة الأردنية الهاشمية، ويحتفظ الطرف الأول بحق إنهاء التعاقد بإرادة منفردة وفق ما ورد في دليل المخالفات دون الحاجة لتبرير القرار للطرف الثاني.',
        ],
      ),
      TermsSection(
        number: 6,
        title: 'طبيعة العلاقة',
        paragraphs: [
          'يعلم الطرفان أن العلاقة بينهما هي علاقة تعاقدية بعمل حر وليس تعاقد وظيفي، لا تندرج تحت قانون العمل الأردني، ولا تترتب عليها أي حقوق عمالية كالضمان الاجتماعي أو الإجازات أو أي تبعات أخرى.',
        ],
      ),
      TermsSection(
        number: 7,
        title: 'الأجور',
        paragraphs: [
          'يلتزم الطرف الأول بدفع الأجور للطرف الثاني مقابل المهام التي يتم تنفيذها بشكل معتمد ونهائي، حسب الاتفاق المسبق عند إرسال كل مهمة.',
        ],
      ),
      TermsSection(
        number: 8,
        title: 'حظر المنافسة',
        paragraphs: [
          'يلتزم الطرف الثاني بعدم العمل أو التعاون بأي شكل مع جهات منافسة لنشاط الطرف الأول داخل الأردن أو دول الخليج، طوال مدة العقد ولمدة خمس سنوات بعد انتهاء، إلا إذا توقفت أعمال الطرف الأول نهائيًا.',
        ],
      ),
      TermsSection(
        number: 9,
        title: 'الانقطاع والتخلف عن المهام',
        paragraphs: [
          'إذا انقطع الطرف الثاني عن العمل أو تأخر في تنفيذ المهام لأكثر من ثلاثة أشهر دون سبب مقبول، يُعد العقد منتهيًا تلقائيًا وتسقط كل حقوقه.',
        ],
      ),
      TermsSection(
        number: 10,
        title: 'طبيعة العلاقة التعاقدية',
        paragraphs: [
          'يقر الطرف الثاني أن العلاقة تعاقدية مدنية تخضع لأحكام القانون المدني الأردني، وليست علاقة عمل تخضع لقانون العمل الأردني.',
        ],
      ),
      TermsSection(
        number: 11,
        title: 'السرية',
        paragraphs: [
          'يُمنع على الطرف الثاني نشر أو إفشاء أي معلومات أو بيانات تتعلق بالعمل، سواء كتابة أو شفهيًا أو عبر البريد الإلكتروني أو وسائل التواصل الاجتماعي أو الإنترنت، ويُعد ذلك مخالفة توجب إنهاء التعاقد والمطالبة بالتعويض وفق الأصول القانونية.',
        ],
      ),
      TermsSection(
        number: 12,
        title: 'الإنذارات والإشعارات',
        paragraphs: [
          'لا يُشترط توجيه إنذارات أو إشعارات مسبقة عند الإخلال بأي بند من بنود هذا العقد، وفي حال النزاع، يكون الاختصاص القضائي المحاكم للمملكة الأردنية الهاشمية.',
        ],
      ),
      TermsSection(
        number: 13,
        title: 'الإعلان والنشر',
        paragraphs: [
          'يُمنع على الطرف الثاني الإعلان أو النشر أو الإشارة إلى تعاونه مع موقع "أوردرز هاوس" للعمل الحر، أو أي من كيانات الطرف الأول عبر وسائل التواصل الاجتماعي أو أي وسيلة أخرى دون موافقة خطية مسبقة، ويُستثنى فقط إدراج اسم الموقع ضمن السيرة الذاتية أو المقابلات الوظيفية دون دعاية أو ترويج، ويُعد الإخلال بهذا البند موجبًا للمساءلة القانونية.',
        ],
      ),
      TermsSection(
        number: 14,
        title: 'الجهة المسؤولة',
        paragraphs: [
          'يُعتبر "الرجل الوطواط للتكنولوجيا" الجهة المسؤولة عن تقديم ومتابعة أي دعوى قضائية تتعلق بهذا العقد أمام الجهات المختصة في المملكة الأردنية الهاشمية، ويُعد هذا العقد سندًا تنفيذيًا نافذًا بذاته.',
        ],
      ),
      TermsSection(
        number: 15,
        title: 'الاتصال',
        paragraphs: [
          'للاستفسارات حول هذه الشروط والأحكام، يرجى الاتصال بنا على:',
          'البريد الإلكتروني: info@battechno.com',
          'سوف نرد على استفسارك في غضون فترة زمنية معقولة.',
        ],
      ),
    ],
  );

  static const TermsContent english = TermsContent(
    language: 'en',
    fundamentalTerms: FundamentalTerms.english,
    sections: [
      TermsSection(
        number: 1,
        title: 'Preamble',
        paragraphs: [
          'The preamble of this contract is an integral part of it and shall be read with it as one unit.',
        ],
      ),
      TermsSection(
        number: 2,
        title: 'Second Party Obligations',
        paragraphs: [
          'The second party agrees to provide and complete the tasks assigned to him by the first party or its clients, within the function specified in this contract, through the approved electronic platform or any other means determined by the first party.',
        ],
      ),
      TermsSection(
        number: 3,
        title: 'Task Details',
        paragraphs: [
          'Tasks are sent to the second party with details and conditions specified, and their execution according to specifications is considered an essential part of the contractual commitment.',
        ],
      ),
      TermsSection(
        number: 4,
        title: 'Violations Guide',
        paragraphs: [
          'The second party\'s signature on this contract constitutes an acknowledgment and approval of the violations guide and internal procedures approved by the first party, and this guide shall be applied as an essential annex to the contract.',
        ],
      ),
      TermsSection(
        number: 5,
        title: 'Dispute Resolution',
        paragraphs: [
          'In case of a dispute between the two parties, it shall be resolved through arbitration in accordance with the laws in force in the Hashemite Kingdom of Jordan, and the first party reserves the right to terminate the contract unilaterally in accordance with what is stated in the violations guide without the need to justify the decision to the second party.',
        ],
      ),
      TermsSection(
        number: 6,
        title: 'Nature of Relationship',
        paragraphs: [
          'Both parties acknowledge that the relationship between them is a contractual relationship for freelance work and not an employment contract, does not fall under Jordanian labor law, and does not entail any labor rights such as social security, leave, or any other consequences.',
        ],
      ),
      TermsSection(
        number: 7,
        title: 'Compensation',
        paragraphs: [
          'The first party is committed to paying wages to the second party in exchange for tasks that are executed in an approved and final manner, according to the prior agreement when sending each task.',
        ],
      ),
      TermsSection(
        number: 8,
        title: 'Non-Competition',
        paragraphs: [
          'The second party is committed not to work or cooperate in any way with entities competing with the first party\'s activity within Jordan or the Gulf countries, throughout the contract period and for five years after its end, unless the first party\'s business stops permanently.',
        ],
      ),
      TermsSection(
        number: 9,
        title: 'Absence and Delay in Tasks',
        paragraphs: [
          'If the second party stops working or delays in executing tasks for more than three months without an acceptable reason, the contract is considered automatically terminated and all his rights are forfeited.',
        ],
      ),
      TermsSection(
        number: 10,
        title: 'Nature of Contractual Relationship',
        paragraphs: [
          'The second party acknowledges that the relationship is a civil contractual relationship subject to the provisions of Jordanian civil law, and is not an employment relationship subject to Jordanian labor law.',
        ],
      ),
      TermsSection(
        number: 11,
        title: 'Confidentiality',
        paragraphs: [
          'The second party is prohibited from publishing or disclosing any information or data related to work, whether in writing, verbally, via email, social media, or the Internet, and this is considered a violation that requires termination of the contract and claiming compensation in accordance with legal procedures.',
        ],
      ),
      TermsSection(
        number: 12,
        title: 'Warnings and Notices',
        paragraphs: [
          'No warnings or prior notices are required when violating any clause of this contract, and in case of dispute, the judicial jurisdiction shall be the courts of the Hashemite Kingdom of Jordan.',
        ],
      ),
      TermsSection(
        number: 13,
        title: 'Advertising and Publication',
        paragraphs: [
          'The second party is prohibited from advertising, publishing, or referring to his cooperation with the "OrderzHouse" freelance platform, or any of the first party\'s entities through social media or any other means without prior written approval, except only for including the platform name in a resume or job interviews without advertising or promotion, and violation of this clause is subject to legal accountability.',
        ],
      ),
      TermsSection(
        number: 14,
        title: 'Responsible Entity',
        paragraphs: [
          'Batman Technology is considered the entity responsible for filing and following up on any legal claim related to this contract before the competent authorities in the Hashemite Kingdom of Jordan, and this contract is considered an enforceable executive instrument in itself.',
        ],
      ),
      TermsSection(
        number: 15,
        title: 'Contact',
        paragraphs: [
          'For questions about these Terms & Conditions, please contact us at:',
          'Email: info@battechno.com',
          'We will respond to your inquiry within a reasonable timeframe.',
        ],
      ),
    ],
  );

  static TermsContent getContent(String locale) {
    return locale.startsWith('ar') ? arabic : english;
  }
}

class TermsSection {
  final int number;
  final String title;
  final List<String> paragraphs;
  final List<String>? bulletPoints;

  const TermsSection({
    required this.number,
    required this.title,
    required this.paragraphs,
    this.bulletPoints,
  });
}

class FundamentalTerms {
  final String title;
  final List<String> terms;

  const FundamentalTerms({required this.title, required this.terms});

  static const FundamentalTerms arabic = FundamentalTerms(
    title: 'الشروط الأساسية',
    terms: [
      '1. مسؤولية الحساب: أنت مسؤول عن الحفاظ على أمان حسابك وكلمة المرور.',
      '2. استخدام الخدمة: أنت توافق على استخدام خدمات ORDERZHOUSE وفقًا للقوانين واللوائح المعمول بها.',
      '3. المحتوى: أنت مسؤول عن جميع المحتويات التي تنشرها أو تقدمها من خلال المنصة.',
      '4. الدفع: تتم معالجة جميع المدفوعات بشكل آمن. الاستردادات تخضع لسياسة الاسترداد الخاصة بنا.',
      '5. الأنشطة المحظورة: لا يجوز لك استخدام ORDERZHOUSE لأي غرض غير قانوني أو غير مصرح به.',
      '6. تغييرات المنصة: تحتفظ ORDERZHOUSE بالحق في تعديل أو إيقاف الخدمات في أي وقت.',
      '7. حل النزاعات: سيتم حل النزاعات وفقًا لعملية حل النزاعات الخاصة بنا.',
      '8. الحد من المسؤولية: تعمل ORDERZHOUSE كوسيط وليست مسؤولة عن إجراءات مقدمي الخدمة.',
      '9. إنهاء الحساب: قد تقوم ORDERZHOUSE بتعليق أو إنهاء الحسابات التي تنتهك هذه الشروط.',
      '10. التحديثات: قد يتم تحديث هذه الشروط، ويشكل الاستمرار في الاستخدام قبولًا بالتغييرات.',
    ],
  );

  static const FundamentalTerms english = FundamentalTerms(
    title: 'Fundamental Terms',
    terms: [
      '1. Account Responsibility: You are responsible for maintaining the security of your account and password.',
      '2. Service Usage: You agree to use ORDERZHOUSE services in accordance with applicable laws and regulations.',
      '3. Content: You are responsible for all content you post or submit through the platform.',
      '4. Payment: All payments are processed securely. Refunds are subject to our Refund Policy.',
      '5. Prohibited Activities: You may not use ORDERZHOUSE for any illegal or unauthorized purpose.',
      '6. Platform Changes: ORDERZHOUSE reserves the right to modify or discontinue services at any time.',
      '7. Dispute Resolution: Disputes will be resolved according to our dispute resolution process.',
      '8. Limitation of Liability: ORDERZHOUSE acts as an intermediary and is not liable for service provider actions.',
      '9. Account Termination: ORDERZHOUSE may suspend or terminate accounts that violate these terms.',
      '10. Updates: These terms may be updated, and continued use constitutes acceptance of changes.',
    ],
  );
}
