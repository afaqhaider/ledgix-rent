// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'ليدجكس للإيجار';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get phone => 'الهاتف (+971…)';

  @override
  String get sendOtp => 'إرسال الرمز';

  @override
  String get otpCode => 'رمز التحقق';

  @override
  String get verify => 'تحقق';

  @override
  String get continueWithLedgix => 'المتابعة باستخدام LedGix ID';

  @override
  String get orDivider => 'أو';

  @override
  String get continueWithGoogle => 'المتابعة باستخدام Google';

  @override
  String get continueWithApple => 'المتابعة باستخدام Apple';

  @override
  String get loginTitle => 'تسجيل الدخول إلى LedGix Rent';

  @override
  String get signUpTitle => 'أنشئ حسابك في LedGix Rent';

  @override
  String get loginSubtitle => 'الإيجارات والشيكات والصيانة في مكان واحد.';

  @override
  String get orUseEmail => 'أو استخدم بريدك الإلكتروني';

  @override
  String get orUsePhone => 'أو استخدم رقم هاتفك';

  @override
  String get otherOptions => 'طرق أخرى للمتابعة';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get resetPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get resetPasswordBody =>
      'أدخل البريد الإلكتروني الذي تسجّل الدخول به وسنرسل لك رابطًا لاختيار كلمة مرور جديدة.';

  @override
  String get sendResetLink => 'إرسال الرابط';

  @override
  String resetLinkSent(String email) {
    return 'إذا كان هناك حساب مسجّل بـ $email فسيصلك رابط إعادة التعيين قريبًا.';
  }

  @override
  String get noAccountYet => 'جديد في LedGix Rent؟';

  @override
  String get haveAccount => 'لديك حساب بالفعل؟';

  @override
  String get usePhoneInstead => 'استخدم رقم الهاتف بدلًا من ذلك';

  @override
  String get useEmailInstead => 'استخدم البريد الإلكتروني بدلًا من ذلك';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get brandHeadline => 'الإيجارات والشيكات والصيانة. في مكان واحد هادئ.';

  @override
  String get brandBullet1 => 'تذكير بالإيداع قبل موعد كل شيك';

  @override
  String get brandBullet2 => 'إيجاري وديوا والمستندات محفوظة مع كل وحدة';

  @override
  String get brandBullet3 => 'حوّل طلبات الصيانة ووافق على عروض الأسعار بلمسة';

  @override
  String get partOfLedgix => 'جزء من LedGix';

  @override
  String get emailRequired => 'أدخل بريدك الإلكتروني';

  @override
  String get emailInvalid => 'أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String get passwordRequired => 'أدخل كلمة المرور';

  @override
  String get passwordTooShort => 'استخدم 6 أحرف على الأقل';

  @override
  String get phoneRequired => 'أدخل رقم هاتفك مع رمز الدولة';

  @override
  String get errInvalidCredentials =>
      'البريد الإلكتروني وكلمة المرور غير متطابقين. حاول مجددًا أو أعد تعيين كلمة المرور.';

  @override
  String get errEmailInUse =>
      'يوجد حساب بهذا البريد الإلكتروني بالفعل. سجّل الدخول بدلًا من ذلك.';

  @override
  String get errWeakPassword => 'اختر كلمة مرور أقوى (6 أحرف على الأقل).';

  @override
  String get errInvalidEmail => 'يبدو أن عنوان البريد الإلكتروني غير صحيح.';

  @override
  String get errUserDisabled =>
      'تم تعطيل هذا الحساب. تواصل مع support@getledgix.com.';

  @override
  String get errTooManyRequests =>
      'محاولات كثيرة. انتظر بضع دقائق ثم حاول مجددًا.';

  @override
  String get errNetwork =>
      'تعذّر الاتصال. تحقق من اتصالك بالإنترنت وحاول مجددًا.';

  @override
  String get errMethodDisabled =>
      'طريقة تسجيل الدخول هذه غير متاحة بعد. جرّب طريقة أخرى.';

  @override
  String get errPopupBlocked =>
      'منع المتصفح نافذة تسجيل الدخول. اسمح بالنوافذ المنبثقة لهذا الموقع وحاول مجددًا.';

  @override
  String get errAccountExists =>
      'هذا البريد مسجّل بطريقة تسجيل دخول أخرى. استخدم الطريقة التي أنشأت بها حسابك.';

  @override
  String get errInvalidPhone =>
      'أدخل رقمك مع رمز الدولة، مثل ‎+971 50 123 4567.';

  @override
  String get errInvalidCode =>
      'الرمز غير صحيح أو انتهت صلاحيته. تحقق من الرسالة وحاول مجددًا.';

  @override
  String get errLedgix =>
      'لم يكتمل تسجيل الدخول باستخدام LedGix ID. حاول مجددًا.';

  @override
  String get errGeneric => 'حدث خطأ ما. حاول مجددًا.';

  @override
  String get emailTab => 'البريد';

  @override
  String get phoneTab => 'الهاتف';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get welcomeTitle => 'مرحبًا بك أيها المالك!';

  @override
  String get welcomeSub => 'اختر لغتك وأضف أول عقار لك.';

  @override
  String get yourName => 'اسمك';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get portfolio => 'المحفظة';

  @override
  String get cheques => 'الشيكات';

  @override
  String get maintenance => 'الصيانة';

  @override
  String get more => 'المزيد';

  @override
  String get tenants => 'المستأجرون';

  @override
  String get leases => 'عقود الإيجار';

  @override
  String get vendors => 'المزودون';

  @override
  String get holdRequests => 'طلبات التأجيل';

  @override
  String get directDebits => 'الخصم المباشر';

  @override
  String get documents => 'المستندات';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountTitle => 'حذف حسابك؟';

  @override
  String get deleteAccountBody =>
      'سيؤدي هذا إلى حذف حسابك وكل ما فيه نهائيًا: العقارات والمستأجرين وعقود الإيجار والدفعات وصور الشيكات والمستندات وسجلات الصيانة. لا يمكن التراجع عن ذلك.';

  @override
  String get accountDeleted => 'تم حذف حسابك.';

  @override
  String get collectedMonth => 'المحصّل هذا الشهر';

  @override
  String get outstandingMonth => 'المستحق هذا الشهر';

  @override
  String get collectedYear => 'المحصّل هذا العام';

  @override
  String get outstandingYear => 'المستحق هذا العام';

  @override
  String get upcomingCheques => 'الشيكات القادمة';

  @override
  String get openTickets => 'تذاكر مفتوحة';

  @override
  String get nothingYet => 'لا يوجد شيء بعد';

  @override
  String get addProperty => 'إضافة عقار';

  @override
  String get propertyName => 'اسم العقار';

  @override
  String get propertyType => 'النوع';

  @override
  String get villa => 'فيلا';

  @override
  String get apartment => 'شقة';

  @override
  String get studio => 'استوديو';

  @override
  String get other => 'أخرى';

  @override
  String get address => 'العنوان';

  @override
  String get community => 'المنطقة';

  @override
  String get titleDeedNo => 'رقم سند الملكية';

  @override
  String get dewaAccountNo => 'رقم حساب ديوا';

  @override
  String get occupied => 'مؤجّر';

  @override
  String get vacant => 'شاغر';

  @override
  String get nextDue => 'الاستحقاق القادم';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get required => 'مطلوب';

  @override
  String get addTenant => 'إضافة مستأجر';

  @override
  String get tenantName => 'اسم المستأجر';

  @override
  String get emiratesIdNo => 'رقم الهوية الإماراتية';

  @override
  String get attachPassport => 'إرفاق نسخة الجواز';

  @override
  String get attachEmiratesId => 'إرفاق نسخة الهوية';

  @override
  String get attached => 'تم الإرفاق';

  @override
  String get addLease => 'إضافة عقد إيجار';

  @override
  String get property => 'العقار';

  @override
  String get tenant => 'المستأجر';

  @override
  String get startDate => 'تاريخ البدء';

  @override
  String get endDate => 'تاريخ الانتهاء';

  @override
  String get annualRent => 'الإيجار السنوي (درهم)';

  @override
  String get securityDeposit => 'مبلغ التأمين (درهم)';

  @override
  String get ejariNo => 'رقم إيجاري';

  @override
  String get numberOfCheques => 'عدد الشيكات';

  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String get cheque => 'شيك';

  @override
  String get directDebit => 'خصم مباشر';

  @override
  String get addPropertyFirst => 'أضف عقارًا ومستأجرًا أولًا.';

  @override
  String get scheduleGenerated => 'تم إنشاء جدول الدفعات';

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusDeposited => 'تم الإيداع';

  @override
  String get statusCleared => 'تمت التسوية';

  @override
  String get statusBounced => 'مرتجع';

  @override
  String get statusOnHold => 'مؤجّل';

  @override
  String get markDeposited => 'تحديد كمودع';

  @override
  String get markCleared => 'تحديد كمسوّى';

  @override
  String get markBounced => 'تحديد كمرتجع';

  @override
  String get attachPhoto => 'إرفاق صورة الشيك';

  @override
  String get chequeNo => 'رقم الشيك';

  @override
  String get bankName => 'البنك';

  @override
  String get notes => 'ملاحظات';

  @override
  String get all => 'الكل';

  @override
  String get dueDate => 'الاستحقاق';

  @override
  String get failedDebit => 'فشل الخصم';

  @override
  String get requestHold => 'طلب تأجيل';

  @override
  String get requestedDate => 'التاريخ الجديد';

  @override
  String get reason => 'السبب';

  @override
  String get approve => 'موافقة';

  @override
  String get reject => 'رفض';

  @override
  String get originalDate => 'التاريخ الأصلي';

  @override
  String get response => 'الرد';

  @override
  String get holdPending => 'قيد الانتظار';

  @override
  String get holdApproved => 'تمت الموافقة';

  @override
  String get holdRejected => 'مرفوض';

  @override
  String get newTicket => 'تذكرة جديدة';

  @override
  String get title => 'العنوان';

  @override
  String get description => 'الوصف';

  @override
  String get priority => 'الأولوية';

  @override
  String get low => 'منخفضة';

  @override
  String get medium => 'متوسطة';

  @override
  String get high => 'عالية';

  @override
  String get urgent => 'عاجلة';

  @override
  String get ticketOpen => 'مفتوحة';

  @override
  String get ticketInProgress => 'قيد التنفيذ';

  @override
  String get ticketResolved => 'تم الحل';

  @override
  String get vendor => 'المزود';

  @override
  String get cost => 'التكلفة (درهم)';

  @override
  String get addPhoto => 'إضافة صورة';

  @override
  String get addVendor => 'إضافة مزود';

  @override
  String get vendorName => 'اسم المزود';

  @override
  String get trade => 'المهنة';

  @override
  String get addDocument => 'إضافة مستند';

  @override
  String get docLease => 'عقد الإيجار';

  @override
  String get docEjari => 'إيجاري';

  @override
  String get docTitleDeed => 'سند الملكية';

  @override
  String get docEmiratesId => 'الهوية الإماراتية';

  @override
  String get offlineHint => 'دون اتصال: عرض البيانات المحفوظة';

  @override
  String get ticketRequested => 'تم الطلب';

  @override
  String get ticketQuoted => 'تم التسعير';

  @override
  String get ticketApproved => 'تمت الموافقة';

  @override
  String get ticketScheduled => 'مجدول';

  @override
  String get ticketCompleted => 'مكتمل';

  @override
  String get ticketClosed => 'مغلق';

  @override
  String get category => 'الفئة';

  @override
  String get catAc => 'تكييف';

  @override
  String get catPlumbing => 'سباكة';

  @override
  String get catElectrical => 'كهرباء';

  @override
  String get catAppliances => 'أجهزة';

  @override
  String get catPestControl => 'مكافحة حشرات';

  @override
  String get catPainting => 'دهان';

  @override
  String get urgency => 'الاستعجال';

  @override
  String get emergency => 'طارئ';

  @override
  String get normal => 'عادي';

  @override
  String get visitRequired => 'هل الزيارة مطلوبة؟';

  @override
  String get addTimeSlot => 'إضافة موعد (بحد أقصى 3)';

  @override
  String get accessNotes => 'ملاحظات الدخول';

  @override
  String get addVideo => 'إضافة فيديو';

  @override
  String get ticketDetails => 'طلب الصيانة';

  @override
  String get landlordNote => 'ملاحظة للشركة';

  @override
  String get maintenanceCompany => 'شركة الصيانة';

  @override
  String get requestQuote => 'طلب عرض سعر';

  @override
  String get shareTenantContact => 'مشاركة بيانات اتصال المستأجر';

  @override
  String get forwardedApp => 'أُرسل عبر التطبيق';

  @override
  String get forwardedEmail => 'أُرسل بالبريد برابط آمن (صالح 7 أيام)';

  @override
  String get quotes => 'عروض الأسعار';

  @override
  String get addQuote => 'إضافة عرض سعر';

  @override
  String get amount => 'المبلغ (درهم)';

  @override
  String get vat => 'ضريبة القيمة المضافة (درهم)';

  @override
  String get scope => 'نطاق العمل';

  @override
  String get proposedVisit => 'موعد الزيارة المقترح';

  @override
  String get askQuestion => 'طرح سؤال';

  @override
  String get question => 'السؤال';

  @override
  String get quoteSubmitted => 'مقدّم';

  @override
  String get quoteApproved => 'تمت الموافقة';

  @override
  String get quoteRejected => 'مرفوض';

  @override
  String get quoteQuestion => 'تم طرح سؤال';

  @override
  String get startJob => 'بدء العمل';

  @override
  String get completeJob => 'تحديد كمكتمل';

  @override
  String get closeJob => 'تأكيد المستأجر والتقييم';

  @override
  String get rating => 'التقييم';

  @override
  String get visitConfirmed => 'تم تأكيد الزيارة';

  @override
  String get tradeLicenceNo => 'رقم الرخصة التجارية';

  @override
  String get contactPerson => 'الشخص المسؤول';

  @override
  String get services => 'الخدمات المقدمة (مفصولة بفواصل)';

  @override
  String get areasCovered => 'المناطق المغطاة (مفصولة بفواصل)';

  @override
  String get linkedAccount => 'معرّف حساب ليدجكس (إن وجد)';

  @override
  String get defaultForCategories => 'الشركة الافتراضية لـ';

  @override
  String get defaultCompany => 'شركة الصيانة الافتراضية';

  @override
  String get none => 'لا شيء';

  @override
  String get utilityBills => 'فواتير الخدمات';

  @override
  String get addBill => 'إضافة فاتورة';

  @override
  String get fetchBill => 'جلب أحدث فاتورة';

  @override
  String get provider => 'المزود';

  @override
  String get accountNo => 'رقم الحساب';

  @override
  String get period => 'الفترة';

  @override
  String get paidBy => 'يدفع';

  @override
  String get landlord => 'المالك';

  @override
  String get billUnpaid => 'غير مدفوعة';

  @override
  String get billPaid => 'مدفوعة';

  @override
  String get billOverdue => 'متأخرة';

  @override
  String get markPaid => 'تحديد كمدفوعة';

  @override
  String get attachBill => 'إرفاق صورة الفاتورة';

  @override
  String get noAccountNo => 'أضف رقم حساب ديوا أو التبريد للعقار أولًا.';

  @override
  String get chillerProvider => 'مزود التبريد';

  @override
  String get chillerAccountNo => 'رقم حساب التبريد';

  @override
  String get jointlyOwned => 'مبنى مملوك بالاشتراك';

  @override
  String get mollakUnitRef => 'الرقم المرجعي للوحدة في مُلاك';

  @override
  String get serviceCharges => 'رسوم الخدمات';

  @override
  String get syncMollak => 'مزامنة من مُلاك';

  @override
  String get outstanding => 'المستحق';

  @override
  String get dueStatus => 'مستحقة';

  @override
  String get chargePaid => 'مدفوعة';

  @override
  String get chargeOverdue => 'متأخرة';

  @override
  String get verifyEjari => 'التحقق من إيجاري';

  @override
  String get ejariActive => 'إيجاري ساري';

  @override
  String get ejariExpiring => 'إيجاري ينتهي قريبًا';

  @override
  String get ejariExpired => 'إيجاري منتهي';

  @override
  String get ejariUnknown => 'لم يتم التحقق';

  @override
  String get ejariExpiry => 'انتهاء إيجاري';

  @override
  String get lastSynced => 'آخر مزامنة';

  @override
  String get reports => 'تقارير الوحدات';

  @override
  String get income => 'الدخل';

  @override
  String get expenses => 'المصروفات';

  @override
  String get net => 'الصافي';

  @override
  String get yieldLabel => 'العائد الصافي';

  @override
  String get maintenanceCost => 'الصيانة';

  @override
  String get utilitiesCost => 'الخدمات';

  @override
  String get dewaLabel => 'ديوا';

  @override
  String get chillerLabel => 'التبريد';

  @override
  String get sewaLabel => 'هيئة كهرباء ومياه الشارقة';

  @override
  String get addcLabel => 'أبوظبي للتوزيع';

  @override
  String get aadcLabel => 'العين للتوزيع';

  @override
  String get overview => 'نظرة عامة';

  @override
  String get operations => 'العمليات';

  @override
  String get insights => 'التحليلات';

  @override
  String get properties => 'العقارات';

  @override
  String get rentAgreements => 'عقود الإيجار';

  @override
  String get settings => 'الإعدادات';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get noNotifications => 'لا توجد إشعارات جديدة.';

  @override
  String get openMenu => 'فتح القائمة';

  @override
  String goodMorning(String name) {
    return 'صباح الخير، $name';
  }

  @override
  String goodAfternoon(String name) {
    return 'مساء الخير، $name';
  }

  @override
  String goodEvening(String name) {
    return 'مساء الخير، $name';
  }

  @override
  String get dashboardSubtitle => 'إليك نظرة على أداء عقاراتك اليوم.';

  @override
  String get occupancy => 'نسبة الإشغال';

  @override
  String occupiedOf(int occupied, int total) {
    return '$occupied من $total مشغولة';
  }

  @override
  String get dueNext30 => 'مستحق خلال 30 يومًا';

  @override
  String paymentsCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString دفعة',
      many: '$countString دفعة',
      few: '$countString دفعات',
      two: 'دفعتان',
      one: 'دفعة واحدة',
      zero: 'لا توجد دفعات',
    );
    return '$_temp0';
  }

  @override
  String get collections6m => 'التحصيلات خلال آخر 6 أشهر';

  @override
  String get leaseRenewals => 'تجديد العقود';

  @override
  String get next90Days => 'خلال 90 يومًا';

  @override
  String endsInDays(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'ينتهي خلال $daysString يوم',
      one: 'ينتهي غدًا',
      zero: 'ينتهي اليوم',
    );
    return '$_temp0';
  }

  @override
  String get noRenewals => 'لا توجد عقود تنتهي خلال 90 يومًا.';

  @override
  String get noUpcoming => 'لا توجد شيكات مستحقة قريبًا.';

  @override
  String get noOpenTickets => 'لا توجد طلبات صيانة مفتوحة.';

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get newRentAgreement => 'عقد إيجار جديد';

  @override
  String get recordPayment => 'تسجيل دفعة';

  @override
  String get newMaintenanceRequest => 'طلب صيانة جديد';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get getStartedTitle => 'لنبدأ بإعداد محفظتك العقارية';

  @override
  String get getStartedBody =>
      'أضف عقارًا ثم مستأجرًا وعقد إيجار، وسيتم إنشاء الشيكات والتذكيرات تلقائيًا.';

  @override
  String get account => 'الحساب';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get theme => 'المظهر';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get remindersInfo => 'التذكيرات التي نرسلها';

  @override
  String get reminderDeposit =>
      'تذكير بإيداع الشيك قبل 3 أيام ويوم واحد من تاريخ الاستحقاق';

  @override
  String get reminderRenewal =>
      'تنبيهات تجديد العقد قبل 90 و60 و30 يومًا من تاريخ الانتهاء';

  @override
  String get remindersDelivery =>
      'تُرسل كإشعارات الساعة 8:00 صباحًا بتوقيت الإمارات.';

  @override
  String get securitySignIn => 'الأمان وتسجيل الدخول';

  @override
  String signedInAs(String email) {
    return 'مسجّل الدخول باسم $email';
  }

  @override
  String get legal => 'قانوني';

  @override
  String get dangerZone => 'منطقة الخطر';

  @override
  String get deleteAccountHint => 'حذف حسابك وجميع بياناته نهائيًا.';

  @override
  String get selectPropertyForBills =>
      'اختر عقارًا لعرض فواتير المرافق الخاصة به.';

  @override
  String get serviceChargesHint =>
      'تتم مزامنة رسوم الخدمات من ملاك للعقارات المشتركة.';

  @override
  String unpaidBills(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString فاتورة غير مدفوعة',
      many: '$countString فاتورة غير مدفوعة',
      few: '$countString فواتير غير مدفوعة',
      two: 'فاتورتان غير مدفوعتين',
      one: 'فاتورة واحدة غير مدفوعة',
      zero: 'كلها مدفوعة',
    );
    return '$_temp0';
  }

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get thisYear => 'هذا العام';

  @override
  String get authTagline => 'الإيجارات والشيكات والصيانة في مكان واحد.';

  @override
  String get authSubtagline =>
      'مصمم للملاك في الإمارات: تابع كل شيك، وجدّد العقود في وقتها، وابقَ على تواصل مع المستأجرين.';

  @override
  String get close => 'إغلاق';

  @override
  String get filledFromScan => 'تمت التعبئة من المسح، يرجى المراجعة';

  @override
  String get replaceTypedTitle => 'استبدال ما كتبته؟';

  @override
  String get replaceTypedBody =>
      'وجد المسح قيمًا مختلفة لهذه الحقول. حدّد ما تريد استبداله، وسيبقى الباقي كما كتبته.';

  @override
  String get keepMine => 'إبقاء ما كتبته';

  @override
  String get replaceSelected => 'استبدال المحدد';

  @override
  String scanFilled(int count, String doc) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمت تعبئة $count حقول من $doc، يرجى المراجعة',
      one: 'تمت تعبئة حقل واحد من $doc، يرجى المراجعة',
    );
    return '$_temp0';
  }

  @override
  String scanNothingNew(String doc) {
    return 'تمت قراءة $doc ولكن لم يُعثر على بيانات جديدة.';
  }

  @override
  String get docDewaBill => 'فاتورة ديوا';

  @override
  String get docOwnerEmiratesId => 'الهوية الإماراتية (المالك)';

  @override
  String get docOwnerPassport => 'جواز السفر (المالك)';

  @override
  String get docMollak => 'ملاك / رسوم الخدمات';

  @override
  String get docTenancyContract => 'عقد الإيجار';

  @override
  String get docEmiratesIdCopy => 'الهوية الإماراتية';

  @override
  String get docPassportCopy => 'جواز السفر';

  @override
  String get docOther => 'أخرى';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get chooseImage => 'اختيار صورة';

  @override
  String get choosePdf => 'اختيار ملف PDF';

  @override
  String get fileTooLarge => 'حجم الملف أكبر من 20 ميغابايت. اختر ملفًا أصغر.';

  @override
  String documentsMissing(String list) {
    return 'أرفق: $list';
  }

  @override
  String get noDocumentsYet => 'لا توجد مستندات بعد.';

  @override
  String get notUploadedYet => 'يُرفع عند الحفظ';

  @override
  String get preview => 'معاينة';

  @override
  String get remove => 'إزالة';

  @override
  String get scanToFill => 'امسح للتعبئة';

  @override
  String get scan => 'مسح';

  @override
  String get scanning => 'جارٍ القراءة…';

  @override
  String get scanNotRecognised =>
      'تعذّرت قراءة المستند. جرّب صورة أوضح أو ملف PDF.';

  @override
  String get scanFailed => 'فشل المسح. حاول مرة أخرى أو املأ النموذج يدويًا.';

  @override
  String get scanWebNote => 'المسح متاح في تطبيقي iPhone وAndroid.';

  @override
  String get scanHintProperty =>
      'سند الملكية أو فاتورة ديوا أو إيجاري أو عقد الإيجار';

  @override
  String get scanHintTenant =>
      'الهوية الإماراتية أو جواز السفر أو إيجاري أو عقد الإيجار';

  @override
  String get scanHintAgreement => 'شهادة إيجاري أو عقد الإيجار';

  @override
  String get sectionBasicInfo => 'المعلومات الأساسية';

  @override
  String get sectionDewaMollak => 'ديوا وملاك';

  @override
  String get sectionOwnership => 'الملكية';

  @override
  String get sectionHoa => 'جمعية الملاك';

  @override
  String get sectionMaintenance => 'الصيانة';

  @override
  String get sectionDocuments => 'المستندات';

  @override
  String get dewaPremiseNo => 'رقم مبنى ديوا';

  @override
  String get mollakRegistrationNo => 'رقم التسجيل في ملاك';

  @override
  String get hoaName => 'اسم جمعية الملاك';

  @override
  String get hoaPhone => 'رقم تواصل جمعية الملاك';

  @override
  String get ownerEmiratesIdNo => 'رقم الهوية الإماراتية للمالك';

  @override
  String get ownerPassportNo => 'رقم جواز سفر المالك';

  @override
  String get annualRentLabel => 'الإيجار السنوي';

  @override
  String get depositLabel => 'مبلغ التأمين';

  @override
  String get aed => 'درهم';

  @override
  String get editProperty => 'تعديل العقار';

  @override
  String get edit => 'تعديل';

  @override
  String get propertyNameHelper => 'مثال: مارينا هايتس 1203';

  @override
  String get premiseHelper => '9 أرقام، في فاتورة ديوا';

  @override
  String get firstName => 'الاسم الأول';

  @override
  String get middleName => 'الاسم الأوسط';

  @override
  String get lastName => 'اسم العائلة';

  @override
  String get contactNo => 'رقم التواصل';

  @override
  String get passportNo => 'رقم جواز السفر';

  @override
  String get sectionPersonal => 'البيانات الشخصية';

  @override
  String get sectionContact => 'التواصل';

  @override
  String get sectionIdentity => 'الهوية';

  @override
  String get editTenant => 'تعديل المستأجر';

  @override
  String get invalidEmiratesId => 'استخدم الصيغة 784-XXXX-XXXXXXX-X';

  @override
  String get invalidEmail => 'أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String get ownIdTenantError =>
      'هذه هويتك الشخصية، ولا يمكن استخدامها لمستأجر.';

  @override
  String get ownIdTitle => 'يبدو أن هذه هويتك الإماراتية';

  @override
  String get ownIdBody =>
      'الهوية في هذا المستند تطابق هويتك، لذلك لم تُعبأ كمستأجر.';

  @override
  String get ownIdAgreementBody =>
      'المستأجر في هذا المستند يحمل هويتك، لذلك لم يُعبأ أي مستأجر. اختر المستأجر بنفسك.';

  @override
  String get useForMyProfile => 'حفظ في ملفي';

  @override
  String get ownIdSaved => 'تم الحفظ في ملفك.';

  @override
  String get addRentAgreement => 'إضافة عقد إيجار';

  @override
  String get editRentAgreement => 'تعديل عقد الإيجار';

  @override
  String get sectionUnitTenant => 'الوحدة والمستأجر';

  @override
  String get sectionTermRent => 'المدة والإيجار';

  @override
  String get sectionPayment => 'الدفع';

  @override
  String get newTenant => 'مستأجر جديد';

  @override
  String addScannedTenant(String name) {
    return 'إضافة $name كمستأجر';
  }

  @override
  String propertyMatched(String name) {
    return 'تمت المطابقة مع $name';
  }

  @override
  String get myProfile => 'ملفي الشخصي';

  @override
  String get myEmiratesIdNo => 'رقم هويتي الإماراتية';

  @override
  String get myPassportNo => 'رقم جواز سفري';

  @override
  String get ownIdHelper =>
      'يُستخدم للتعرّف على مستنداتك حتى لا تُضاف كمستأجر أبدًا.';

  @override
  String get profileSaved => 'تم حفظ الملف.';

  @override
  String get tenantRequired => 'اختر مستأجرًا أو أضف واحدًا';

  @override
  String get noTenantsYet => 'لا يوجد مستأجرون بعد. أضف مستأجرًا للمتابعة.';

  @override
  String get scheduleNote => 'يُنشأ جدول الشيكات عند الحفظ.';

  @override
  String get tpSetupTitle => 'إعداد حسابك';

  @override
  String get tpSetupSub =>
      'بعض التفاصيل للبدء. يمكنك إضافة العقارات مباشرة بعد ذلك.';

  @override
  String get tpUnits => 'عدد الوحدات';

  @override
  String get tpUnitsHelper => 'عدد الوحدات التي تملكها أو تديرها';

  @override
  String get tpInvalidNumber => 'أدخل رقمًا (1 أو أكثر)';

  @override
  String get tpRole => 'دورك';

  @override
  String get tpRoleLandlord => 'مالك';

  @override
  String get tpRolePropertyManager => 'مدير عقارات';

  @override
  String get tpRoleTenant => 'مستأجر';

  @override
  String get tpImTenant => 'أنا مستأجر';

  @override
  String get tpImLandlord => 'أنا مالك أو مدير عقارات';

  @override
  String get tpAccountType => 'نوع الحساب';

  @override
  String get tpTenantWelcome => 'مرحبًا بك في LedGix Rent';

  @override
  String get tpTenantWelcomeSub =>
      'أدخل اسمك. إذا أعطاك المالك رمز دعوة، أضفه لترى عقدك ودفعاتك ومستنداتك.';

  @override
  String get tpInviteCode => 'رمز الدعوة';

  @override
  String get tpInviteCodeHint => '8 أحرف، مثل K7MP3QXA';

  @override
  String get tpSkip => 'تخطَّ الآن';

  @override
  String get tpCodeInvalid => 'هذا الرمز غير صالح. تحقق منه وحاول مرة أخرى.';

  @override
  String get tpCodeExpired =>
      'انتهت صلاحية هذا الرمز. اطلب رمزًا جديدًا من المالك.';

  @override
  String get tpCodeUsed =>
      'تم استخدام هذا الرمز من قبل. اطلب رمزًا جديدًا من المالك.';

  @override
  String get tpCodeOwn =>
      'هذا رمز دعوة أنشأته أنت. شاركه مع المستأجر بدلًا من ذلك.';

  @override
  String get tpCodeAlreadyLinked => 'سجل المستأجر هذا مرتبط بالفعل بحساب آخر.';

  @override
  String get tpLandlordAdded => 'تمت إضافة المالك.';

  @override
  String get tpInviteToApp => 'دعوة إلى التطبيق';

  @override
  String tpInviteTitle(String name) {
    return 'دعوة $name إلى LedGix Rent';
  }

  @override
  String tpInviteBody(String date) {
    return 'شارك هذا الرمز مع المستأجر. يدخله في تطبيق LedGix Rent ليرى عقده ودفعاته والمستندات التي تشاركها. تنتهي صلاحيته في $date.';
  }

  @override
  String get tpCopyCode => 'نسخ الرمز';

  @override
  String get tpShare => 'مشاركة';

  @override
  String get tpCodeCopied => 'تم نسخ الرمز';

  @override
  String tpInviteShareText(String code) {
    return 'انضم إليّ على LedGix Rent لترى عقدك ودفعاتك ومستنداتك. رمز الدعوة: $code. افتح https://rent.getledgix.com/app/ وسجّل كمستأجر.';
  }

  @override
  String get tpNewCode => 'رمز جديد';

  @override
  String get tpNotInvited => 'لم تتم دعوته';

  @override
  String get tpInvited => 'تمت دعوته';

  @override
  String get tpJoined => 'انضم إلى التطبيق';

  @override
  String get tpLater => 'لاحقًا';

  @override
  String get tpShareWithTenant => 'مشاركة مع المستأجر';

  @override
  String get tpSharedWithTenant => 'مُشارك مع المستأجر';

  @override
  String get tpShareChequeCopy => 'صورة الشيك مُشاركة مع المستأجر';

  @override
  String get tpHome => 'الرئيسية';

  @override
  String get tpLandlords => 'الملاك';

  @override
  String get tpPayments => 'الدفعات';

  @override
  String get tpInspections => 'المعاينات';

  @override
  String get tpManageLandlords => 'إدارة الملاك';

  @override
  String get tpAddLandlord => 'إضافة مالك';

  @override
  String get tpAddLandlordHint => 'أدخل رمز الدعوة الذي شاركه المالك معك.';

  @override
  String get tpCurrent => 'الحاليون';

  @override
  String get tpFormer => 'السابقون';

  @override
  String get tpRemove => 'إزالة';

  @override
  String tpRemoveTitle(String name) {
    return 'إزالة $name؟';
  }

  @override
  String get tpRemoveBody =>
      'لن يظهر عقدك السابق مع هذا المالك في تطبيقك بعد الآن. يمكنه إضافتك مجددًا برمز جديد.';

  @override
  String get tpNoLandlords => 'لا يوجد ملاك بعد. اطلب رمز دعوة من المالك.';

  @override
  String get tpLandlordDetails => 'تفاصيل المالك';

  @override
  String get tpAgreement => 'العقد';

  @override
  String get tpSharedDocuments => 'المستندات المُشاركة';

  @override
  String get tpNoSharedDocuments => 'لم تتم مشاركة أي مستندات بعد.';

  @override
  String get tpOpenDocument => 'فتح';

  @override
  String get tpNextPayment => 'الدفعة القادمة';

  @override
  String get tpNoUpcoming => 'لا توجد دفعات قادمة.';

  @override
  String get tpYourLeases => 'عقودك';

  @override
  String tpLeaseWith(String name) {
    return 'مع $name';
  }

  @override
  String get tpRecentDocuments => 'أحدث المستندات';

  @override
  String get tpChequeCopy => 'صورة الشيك';

  @override
  String get tpViewChequeCopy => 'عرض صورة الشيك';

  @override
  String get tpNewRequest => 'طلب جديد';

  @override
  String get tpRequestSent => 'تم إرسال الطلب إلى المالك.';

  @override
  String get tpRequestTitle => 'ما الذي يحتاج إلى إصلاح؟';

  @override
  String get tpRequestDetails => 'التفاصيل';

  @override
  String get tpAddPhotos => 'إضافة صور';

  @override
  String tpPhotosAdded(int count) {
    return 'تمت إضافة $count صورة';
  }

  @override
  String get tpMyRequests =>
      'يتابع المالك الطلبات، وستصلك التحديثات عند اتخاذ إجراء.';

  @override
  String get tpNoInspections => 'لا توجد معاينات بعد.';

  @override
  String get tpMoveIn => 'معاينة الاستلام';

  @override
  String get tpMoveOut => 'معاينة التسليم';

  @override
  String get tpInspection => 'معاينة';

  @override
  String get tpEnded => 'منتهٍ';

  @override
  String get tpActive => 'ساري';

  @override
  String get tpPropertyDetails => 'تفاصيل العقار';

  @override
  String get tpNoProperties =>
      'لا توجد عقارات بعد. ستظهر عندما يضيف المالك عقد الإيجار.';

  @override
  String get tpRentReminders =>
      'تذكيرات بالإيجار قبل 7 و3 و1 يوم من كل دفعة وفي يوم الاستحقاق';

  @override
  String get tpRenewalReminders => 'تذكيرات بانتهاء العقد قبل 60 و30 يومًا';

  @override
  String get tpBounced => 'تنبيهات إذا ارتد شيك أو تم تأجيله';

  @override
  String tpLeasePeriod(String start, String end) {
    return 'من $start إلى $end';
  }

  @override
  String get tpChoosePropertyFirst => 'اختر عقارًا';

  @override
  String tpSince(String date) {
    return 'منذ $date';
  }

  @override
  String get inspections => 'المعاينات';

  @override
  String get moveInInspection => 'معاينة الاستلام';

  @override
  String get moveOutInspection => 'معاينة التسليم';

  @override
  String get newInspection => 'معاينة جديدة';

  @override
  String get inspectionStatusDraft => 'مسودة';

  @override
  String get inspectionStatusAwaitingTenant => 'بانتظار المستأجر';

  @override
  String get inspectionStatusCompleted => 'مكتملة';

  @override
  String get conditionExcellent => 'ممتازة';

  @override
  String get conditionGood => 'جيدة';

  @override
  String get conditionFair => 'مقبولة';

  @override
  String get conditionPoor => 'سيئة';

  @override
  String get conditionDamaged => 'تالفة';

  @override
  String get conditionMissing => 'مفقودة';

  @override
  String get conditionNa => 'لا ينطبق';

  @override
  String get inspectionRooms => 'الغرف';

  @override
  String get addRoom => 'إضافة غرفة';

  @override
  String get renameRoom => 'إعادة تسمية الغرفة';

  @override
  String get deleteRoom => 'حذف الغرفة';

  @override
  String get roomNameLabel => 'اسم الغرفة';

  @override
  String get addItem => 'إضافة عنصر';

  @override
  String get itemNameLabel => 'اسم العنصر';

  @override
  String get renameItem => 'إعادة تسمية العنصر';

  @override
  String get deleteItem => 'حذف العنصر';

  @override
  String itemsRated(int rated, int total) {
    return 'تم تقييم $rated من $total';
  }

  @override
  String get metersAndKeys => 'العدادات والمفاتيح';

  @override
  String get meterReadings => 'قراءات العدادات';

  @override
  String get meterElectricity => 'عداد الكهرباء';

  @override
  String get meterWater => 'عداد المياه';

  @override
  String get meterGas => 'عداد الغاز';

  @override
  String get meterPhotos => 'صور العدادات';

  @override
  String get keysHandedOver => 'المفاتيح المسلّمة';

  @override
  String get keysMainDoor => 'مفاتيح الباب الرئيسي';

  @override
  String get keysMailbox => 'مفاتيح صندوق البريد';

  @override
  String get keysParking => 'موقف السيارات';

  @override
  String get keysAccessCards => 'بطاقات الدخول';

  @override
  String get keysRemotes => 'أجهزة التحكم';

  @override
  String get keysOther => 'أخرى';

  @override
  String get generalNotes => 'ملاحظات عامة';

  @override
  String get roomNotes => 'ملاحظات الغرفة';

  @override
  String get roomPhotos => 'صور ومقاطع الغرفة';

  @override
  String get recordVideo => 'تسجيل فيديو';

  @override
  String get fromGallery => 'من المعرض';

  @override
  String uploadingMedia(int count) {
    return 'جارٍ رفع $count…';
  }

  @override
  String uploadFailed(String error) {
    return 'تعذّر الرفع: $error';
  }

  @override
  String get reviewAndSend => 'المراجعة والإرسال';

  @override
  String get sendToTenant => 'إرسال إلى المستأجر';

  @override
  String get sendToTenantHint =>
      'يمكن للمستأجر مراجعتها وإضافة تعليقات وصور وتأكيدها من تطبيقه.';

  @override
  String get inspectionSent => 'تم الإرسال إلى المستأجر.';

  @override
  String get markCompleted => 'تحديدها كمكتملة';

  @override
  String get markCompletedHint =>
      'استخدم هذا إذا لم يكن المستأجر على التطبيق، مثل \"وُقّعت ورقيًا في 12/11\".';

  @override
  String get completionNoteLabel => 'ملاحظة';

  @override
  String get downloadReport => 'تقرير PDF';

  @override
  String get moveInVsMoveOut => 'الاستلام مقابل التسليم';

  @override
  String get atMoveIn => 'عند الاستلام';

  @override
  String get atMoveOut => 'عند التسليم';

  @override
  String get worsenedItems => 'عناصر حالتها أسوأ';

  @override
  String get noWorsenedItems =>
      'لا يوجد عنصر حالته أسوأ مما كانت عند الاستلام.';

  @override
  String get worsenedHint =>
      'استخدم هذه القائمة عند الاتفاق على خصومات التأمين.';

  @override
  String get tenantComments => 'تعليقات المستأجر';

  @override
  String get tenantMedia => 'صور ومقاطع المستأجر';

  @override
  String get addComment => 'إضافة تعليق';

  @override
  String get commentLabel => 'التعليق';

  @override
  String get addPhotoOrVideo => 'إضافة صورة أو فيديو';

  @override
  String get confirmInspection => 'تأكيد المعاينة';

  @override
  String get confirmInspectionBody =>
      'أكّد أن هذه المعاينة تطابق حالة الوحدة. أضف تعليقاتك أولًا إن كان هناك خطأ.';

  @override
  String get inspectionConfirmed => 'تم تأكيد المعاينة.';

  @override
  String get landlordSigned => 'توقيع المالك';

  @override
  String get tenantConfirmed => 'تأكيد المستأجر';

  @override
  String get notYet => 'ليس بعد';

  @override
  String get completedWithoutTenant => 'اكتملت دون تأكيد المستأجر';

  @override
  String get bedroomsLabel => 'غرف النوم';

  @override
  String get bathroomsLabel => 'الحمامات';

  @override
  String get roomsToInclude => 'الغرف المشمولة';

  @override
  String get rentAgreementLabel => 'عقد الإيجار';

  @override
  String get inspectionTypeLabel => 'النوع';

  @override
  String get startInspection => 'بدء المعاينة';

  @override
  String get continueInspection => 'متابعة';

  @override
  String get viewInspection => 'عرض';

  @override
  String get deleteInspection => 'حذف المعاينة';

  @override
  String get deleteInspectionConfirm =>
      'حذف هذه المعاينة وملاحظاتها؟ تبقى الصور المرفوعة في التخزين حتى حذف الحساب.';

  @override
  String unratedItems(int count) {
    return '$count عناصر لم تُقيَّم بعد. هل تريد الإرسال على أي حال؟';
  }

  @override
  String get prefilledFromMoveIn =>
      'نُسخت الغرف من معاينة الاستلام. تظهر حالة الاستلام على كل عنصر.';

  @override
  String get noInspectionsYet =>
      'لا توجد معاينات بعد. ابدأ واحدة من عقد إيجار.';

  @override
  String get noAgreementsForInspection => 'أضف عقد إيجار أولًا.';

  @override
  String inspectionCreated(String date) {
    return 'أُنشئت $date';
  }

  @override
  String photosOmitted(int count) {
    return '$count صور إضافية في التطبيق';
  }

  @override
  String get videosLabel => 'مقاطع الفيديو';

  @override
  String get itemLabel => 'العنصر';

  @override
  String get conditionLabel => 'الحالة';

  @override
  String get inspectionStatusLabel => 'الحالة';

  @override
  String get createdLabel => 'تاريخ الإنشاء';

  @override
  String get completedLabel => 'تاريخ الاكتمال';

  @override
  String get confirmationsLabel => 'التأكيدات';

  @override
  String worsenedCount(int count) {
    return '$count أسوأ';
  }

  @override
  String get hrPaymentDetails => 'تفاصيل الدفعة';

  @override
  String get hrRequestHold => 'طلب تأجيل';

  @override
  String get hrRequestHoldSub =>
      'اطلب من المالك تأجيل هذه الدفعة إلى تاريخ لاحق.';

  @override
  String get hrNewDate => 'التاريخ الجديد *';

  @override
  String get hrPickDate => 'اختر تاريخًا';

  @override
  String get hrReason => 'السبب *';

  @override
  String get hrReasonHint => 'مثال: يُصرف الراتب في وقت لاحق من هذا الشهر';

  @override
  String get hrNote => 'ملاحظة (اختياري)';

  @override
  String get hrSend => 'إرسال الطلب';

  @override
  String get hrSent => 'تم إرسال الطلب إلى المالك.';

  @override
  String get hrStatusPending => 'تم طلب التأجيل · بانتظار رد المالك';

  @override
  String hrStatusApproved(String date) {
    return 'تمت الموافقة على التأجيل · التاريخ الجديد $date';
  }

  @override
  String get hrStatusDeclined => 'تم رفض طلب التأجيل';

  @override
  String get hrLandlordResponse => 'رد المالك';

  @override
  String get hrYourReason => 'السبب الذي ذكرته';

  @override
  String get hrErrReason => 'يرجى ذكر السبب.';

  @override
  String get hrErrDate => 'اختر تاريخًا بعد تاريخ الاستحقاق.';

  @override
  String hrErrTooFar(int days) {
    return 'اختر تاريخًا خلال $days يومًا من تاريخ الاستحقاق.';
  }

  @override
  String get hrErrOpen => 'يوجد طلب قائم لهذه الدفعة بالفعل.';

  @override
  String get hrErrNotAllowed => 'لا يمكن تأجيل هذه الدفعة.';

  @override
  String get hrTapForDetails =>
      'اضغط على أي دفعة لعرض التفاصيل أو طلب التأجيل.';

  @override
  String get hrFromTenant => 'من تطبيق المستأجر';

  @override
  String get hrDecline => 'رفض';

  @override
  String get hrDeclineTitle => 'رفض طلب التأجيل';

  @override
  String get hrResponse => 'الرد على المستأجر';

  @override
  String get hrResponseHint => 'سبب مختصر، مثال: يجب إيداع الشيك في موعده';

  @override
  String hrPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قيد الانتظار',
      one: 'طلب واحد قيد الانتظار',
    );
    return '$_temp0';
  }

  @override
  String get hrNonePending => 'لا توجد طلبات تأجيل قيد الانتظار.';

  @override
  String hrMoveTo(String from, String to) {
    return '$from ← $to';
  }

  @override
  String hrNotif(String amount) {
    return 'طلب تأجيل · $amount';
  }

  @override
  String get hrApproved =>
      'تمت الموافقة على التأجيل وتم تغيير تاريخ الاستحقاق.';

  @override
  String get hrDeclined => 'تم رفض طلب التأجيل.';

  @override
  String get ixAddOtherDocument => 'إضافة مستند آخر';

  @override
  String ixAndMore(int count) {
    return 'و$count أخرى';
  }

  @override
  String get ixClearDate => 'مسح التاريخ';

  @override
  String get ixDocumentName => 'اسم المستند';

  @override
  String get ixEmiratesId => 'الهوية الإماراتية';

  @override
  String get ixEmiratesIdExpiry => 'تاريخ انتهاء الهوية الإماراتية';

  @override
  String ixExpiredOn(String date) {
    return 'انتهت في $date';
  }

  @override
  String ixExpiresInDays(String date, int days) {
    return 'تنتهي في $date (بعد $days يومًا)';
  }

  @override
  String ixExpiresOn(String date) {
    return 'تنتهي في $date';
  }

  @override
  String get ixExpiresToday => 'تنتهي اليوم';

  @override
  String get ixExpiryAlreadyPassed => 'هذا التاريخ قد مضى: الهوية منتهية';

  @override
  String get ixExpiryNotSet => 'لم يُحدد تاريخ الانتهاء';

  @override
  String get ixIdExpired => 'هوية منتهية';

  @override
  String ixIdExpiriesSubtitle(int expired, int soon) {
    return '$expired منتهية · $soon تنتهي خلال 60 يومًا';
  }

  @override
  String get ixIdExpiriesTitle => 'انتهاء صلاحية الهويات';

  @override
  String get ixIdExpiringSoon => 'هوية قاربت على الانتهاء';

  @override
  String get ixMyEmiratesIdExpiry => 'تاريخ انتهاء هويتي الإماراتية';

  @override
  String get ixMyPassportExpiry => 'تاريخ انتهاء جواز سفري';

  @override
  String get ixNoOtherDocuments => 'لا توجد مستندات أخرى بعد.';

  @override
  String get ixNotAttached => 'غير مرفق';

  @override
  String get ixOtherDocuments => 'مستندات أخرى';

  @override
  String get ixOwnerEmiratesIdExpiry => 'تاريخ انتهاء هوية المالك';

  @override
  String ixOwnerOfProperty(String property) {
    return 'المالك · $property';
  }

  @override
  String get ixOwnerPassportExpiry => 'تاريخ انتهاء جواز سفر المالك';

  @override
  String get ixPassport => 'جواز السفر';

  @override
  String get ixPassportExpiry => 'تاريخ انتهاء جواز السفر';

  @override
  String get ixReplace => 'استبدال';

  @override
  String get ixUpload => 'رفع';

  @override
  String get ixYou => 'أنت';
}
