// =============================================================================
// نَذْر - جميع النصوص العربية
// =============================================================================
class S {
  // التطبيق
  static const appName = 'نَذْر';
  static const appTagline = 'استطلاع سطح الهجوم الخارجي';
  static const appVersion = 'الإصدار 1.0.0';

  // التبويبات
  static const tabTargets = 'الأهداف';
  static const tabSubdomains = 'النطاقات الفرعية';
  static const tabPorts = 'المنافذ';
  static const tabVulns = 'الثغرات';
  static const tabLog = 'السجل';
  static const tabSettings = 'الإعدادات';

  // الأزرار العامة
  static const add = 'إضافة';
  static const cancel = 'إلغاء';
  static const save = 'حفظ';
  static const delete = 'حذف';
  static const run = 'بدء الفحص';
  static const stop = 'إيقاف';
  static const scanning = 'جاري الفحص...';
  static const retry = 'إعادة المحاولة';
  static const exportJson = 'تصدير JSON';
  static const exportAudit = 'تصدير السجل الموقّع';
  static const clearLogs = 'مسح السجل';
  static const heartbeat = 'فحص النبض';
  static const interfaces = 'واجهات الشبكة';

  // الحالات
  static const statusIdle = 'خامل';
  static const statusScanning = 'قيد الفحص';
  static const statusUp = 'متاح';
  static const statusDown = 'غير متاح';
  static const statusError = 'خطأ';
  static const statusBlocked = 'محظور';

  // Onboarding
  static const onboardingTitle = 'قبل أن تبدأ';
  static const onboardingB1 = 'هذا التطبيق مخصص فقط للشبكات التي تملكها أو المصرّح لك بفحصها كتابيًا.';
  static const onboardingB2 = 'الفحص غير المصرّح به جريمة يعاقب عليها القانون في اليمن (قانون 5/2006) ومعظم الدول.';
  static const onboardingB3 = 'قائمة بيضاء إلزامية تمنع فحص أي نطاق خارج النطاقات المصرّح بها.';
  static const onboardingB4 = 'كل عملية تُسجَّل في سجل موقّع ببصمة تشفيرية لأغراض قانونية.';
  static const onboardingB5 = 'أنت تتحمل المسؤولية القانونية الكاملة عن أي استخدام لهذا التطبيق.';
  static const onboardingAgree = 'أوافق على الشروط';
  static const onboardingFooter = 'بالضغط على "أوافق" أنت تقر بأنك قرأت هذه الشروط وتوافق عليها، وأنك ستستخدم نَذْر فقط على الأهداف المصرّح بها.';

  // القائمة البيضاء
  static const whitelistTitle = 'القائمة البيضاء (إلزامية)';
  static const whitelistDesc = 'يمكن فحص هذه النطاقات فقط. أضف نطاقاتك المملوكة.';
  static const whitelistEmpty = '(فارغة — أضف نطاقًا واحدًا على الأقل)';
  static const addDomain = 'إضافة نطاق';
  static const addCidr = 'إضافة نطاق IP';
  static const domainHint = 'مثال: example.com';
  static const cidrHint = 'مثال: 192.168.1.0/24';
  static const notInWhitelist = 'هذا النطاق غير موجود في القائمة البيضاء. أضفه أولًا من الإعدادات.';

  // الأهداف
  static const noTargetsYet = 'لا توجد أهداف بعد.\n\nاضغط + لإضافة نطاق والبدء.';
  static const addTarget = 'إضافة هدف';
  static const hostLabel = 'النطاق أو عنوان IP';
  static const scanType = 'نوع الفحص';
  static const portsLabel = 'المنافذ (مفصولة بفواصل)';
  static const targetAdded = 'تمت الإضافة';
  static const targetBlocked = 'محظور — النطاق غير مصرّح به';

  // أنواع الفحص
  static const scanFull = 'فحص شامل';
  static const scanSubdomain = 'اكتشاف النطاقات الفرعية';
  static const scanDns = 'استعلام DNS';
  static const scanPort = 'فحص المنافذ';
  static const scanHttp = 'فحص HTTP';
  static const scanTls = 'فحص شهادة TLS';

  // السجل
  static const logEmpty = 'السجل فارغ.';
  static const logPurged = 'تم مسح السجل';

  // السجل الموقّع
  static const auditTitle = 'السجل الموقّع';
  static const auditEntries = 'عدد السجلات';
  static const auditIntegrity = 'سلامة السلسلة';
  static const auditValid = 'سليمة';
  static const auditBroken = 'مخترقة عند المؤشر';
  static const auditLastHash = 'آخر بصمة';

  // منطقة الخطر
  static const dangerZone = 'منطقة الخطر';
  static const wipeKeys = 'مسح مفاتيح التشفير';
  static const wipeKeysConfirm = 'سيتم حذف مفاتيح التشفير. سيعاد توليدها عند إعادة التشغيل.';

  // رسائل النظام
  static const coreOnline = 'الخادم المحلي يعمل على المنفذ';
  static const coreOffline = 'الخادم المحلي متوقف';
  static const bootFailed = 'فشل التشغيل';
  static const heartbeatOk = 'النبض سليم';
  static const heartbeatFail = 'فشل النبض';
  static const rateLimit = 'تم تجاوز حد المعدل';

  // نتائج الفحص
  static const foundSubdomains = 'تم اكتشاف النطاقات الفرعية';
  static const openPorts = 'المنافذ المفتوحة';
  static const discoveredTech = 'التقنيات المكتشفة';
  static const detectedCves = 'الثغرات المكتشفة';
  static const tlsExpiry = 'أيام متبقية للشهادة';
  static const scanComplete = 'اكتمل الفحص';
  static const scanError = 'حدث خطأ أثناء الفحص';

  // إضافات
  static const protocol = 'البروتوكول';
  static const service = 'الخدمة';
  static const server = 'الخادم';
  static const issuer = 'المُصدر';
  static const subject = 'الموضوع';
  static const severity = 'الخطورة';
  static const description = 'الوصف';
  static const schedule = 'جدولة';
  static const unschedule = 'إلغاء الجدولة';
  static const every30s = 'كل 30 ثانية';
  static const every1m = 'كل دقيقة';
  static const every5m = 'كل 5 دقائق';
  static const every15m = 'كل 15 دقيقة';
  static const every1h = 'كل ساعة';

  // الحقول
  static const target = 'الهدف';
  static const type = 'النوع';
  static const status = 'الحالة';
  static const progress = 'التقدم';
  static const error = 'خطأ';
  static const enabled = 'مُفعّل';
  static const disabled = 'مُعطّل';
}