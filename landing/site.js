// LedGix Rent site: language (EN/AR with RTL), theme, mobile menu.
// English lives in the HTML (for search engines); Arabic is applied from AR below.
(function () {
  'use strict';
  var root = document.documentElement;

  var AR = {
    skip: 'تخطَّ إلى المحتوى',
    navFeatures: 'المزايا',
    navHow: 'طريقة العمل',
    navSecurity: 'الأمان',
    navFaq: 'الأسئلة الشائعة',
    signIn: 'تسجيل الدخول',
    getStarted: 'ابدأ الآن',
    seeHow: 'شاهد طريقة العمل',
    heroEyebrow: 'للملاك في الإمارات',
    heroTitle1: 'الإيجارات والشيكات والصيانة.',
    heroTitle2: 'في مكان واحد هادئ.',
    heroLede: 'يجمع LedGix Rent كل عقار ومستأجر وعقد إيجاري وشيك مؤجل وفاتورة ديوا وطلب صيانة في مكان واحد، ويذكّرك قبل أي موعد استحقاق. بالعربية والإنجليزية.',
    platWeb: 'الويب',
    available: 'متاح',
    platPhones: 'iPhone وAndroid',
    comingSoon: 'قريبًا',
    mDashboard: 'لوحة المعلومات',
    mProperties: 'العقارات',
    mTenants: 'المستأجرون',
    mCheques: 'الشيكات',
    mMaintenance: 'الصيانة',
    mReports: 'التقارير',
    mGreeting: 'صباح الخير',
    mSub: 'بيانات تجريبية · نوفمبر',
    mCollected: 'المحصّل هذا الشهر',
    mOutstanding: 'المستحق',
    mTickets: 'طلبات مفتوحة',
    mUpcoming: 'الشيكات القادمة',
    mNext30: 'خلال 30 يومًا',
    mCheque3: 'الشيك 3 من 4 · 15 ديسمبر',
    mCheque2: 'الشيك 2 من 6 · 1 ديسمبر',
    mCheque1: 'الشيك 1 من 2 · 20 نوفمبر',
    mPending: 'قيد الانتظار',
    mDeposited: 'مودَع',
    mCleared: 'محصّل',
    mScanned: 'تم مسح إيجاري · تعبئة 12 حقلًا',
    mNotifTitle: 'تذكير بالإيداع',
    mNotifBody: 'Marina Studio 1204: موعد الشيك بعد 3 أيام.',
    featEyebrow: 'المزايا',
    featTitle: 'كل ما يتابعه المالك، بلا جداول بيانات.',
    featLede: 'مصمَّم حول طريقة الإيجار في الإمارات: عقود سنوية، وشيكات مؤجلة، وإيجاري، وديوا، ورسوم خدمات المباني.',
    f1t: 'تتبّع الشيكات وتذكيرات الإيداع',
    f1d: 'سجّل كل شيك مؤجل مرة واحدة، واحصل على تذكير قبل موعده بثلاثة أيام وبيوم واحد، واعرف ما هو قيد الانتظار أو مودَع أو محصّل أو معلّق أو مرتجع.',
    f2t: 'عقود الإيجار وإيجاري',
    f2d: 'عقد كل وحدة ورقم إيجاري والمدة وجدول الدفعات في سجل واحد، مع تنبيهات التجديد قبل 90 و60 و30 يومًا.',
    f3t: 'امسح المستندات لتعبئة النماذج',
    f3d: 'امسح شهادة إيجاري أو عقد الإيجار أو فاتورة ديوا أو سند الملكية، وسيعبّئ LedGix Rent البيانات لتراجعها.',
    f3tag: 'في تطبيقَي iPhone وAndroid',
    f4t: 'الصيانة مع عروض الأسعار',
    f4d: 'حوّل الطلب إلى شركة الصيانة، واستلم عرض السعر ووافق عليه، مع حفظ كل خطوة في الطلب.',
    f5t: 'فواتير المرافق ورسوم الخدمات',
    f5d: 'احتفظ بفواتير ديوا ورسوم خدمات ملاك مع كل وحدة، كي لا يفوتك شيء بين عقد وآخر.',
    f6t: 'التقارير',
    f6d: 'الإيجار المحصّل والمستحق شهريًا وسنويًا، لعقار واحد أو لكل محفظتك.',
    f7t: 'المستندات في مكان واحد',
    f7d: 'سندات الملكية والهويات الإماراتية وجوازات السفر والعقود والفواتير محفوظة بخصوصية مع العقار أو المستأجر الذي تخصه.',
    f8t: 'العربية والإنجليزية',
    f8d: 'كل الشاشات تعمل باللغتين، بما في ذلك الاتجاه من اليمين إلى اليسار. بدّل اللغة متى شئت.',
    howEyebrow: 'طريقة العمل',
    howTitle: 'جهّز كل شيء في بعد ظهر واحد، ثم دعه يذكّرك.',
    s1t: 'أضف عقاراتك',
    s1d: 'اكتب البيانات أو امسح سند الملكية وفاتورة ديوا، وأضف المستندات التي تريد حفظها.',
    s2t: 'أضف المستأجرين والعقود',
    s2d: 'امسح إيجاري أو عقد الإيجار لتسجيل المستأجر والمدة وجدول الشيكات دفعة واحدة.',
    s3t: 'تلقَّ التذكيرات وابقَ مطمئنًا',
    s3d: 'تصلك تذكيرات الإيداع وتنبيهات التجديد وتحديثات الصيانة على هاتفك قبل أن تتحول إلى مشكلات.',
    audEyebrow: 'الملاك والمستأجرون',
    audTitle: 'مصمَّم للملاك. والمستأجرون قادمون.',
    audLede: 'اليوم، LedGix Rent مخصص للملاك. وتطبيق المستأجرين في الطريق، لتنتهي أخيرًا المراسلات المتكررة عبر واتساب.',
    audL: 'للملاك',
    audL1: 'العقارات والمستأجرون والعقود والمستندات',
    audL2: 'جداول الشيكات مع تذكيرات الإيداع',
    audL3: 'تحويل طلبات الصيانة والموافقة على عروض الأسعار',
    audL4: 'تقارير لكل محفظتك',
    audT: 'للمستأجرين',
    audT1: 'الاطلاع على العقد وجدول الدفعات',
    audT2: 'إرسال طلبات الصيانة إليك مباشرة',
    audT3: 'رفع المستندات التي تطلبها',
    audT4: 'تلقي التذكيرات قبل إيداع الشيكات',
    secEyebrow: 'الخصوصية والأمان',
    secTitle: 'بياناتك تبقى لك.',
    secLede: 'هويات المستأجرين والشيكات والعقود بيانات حساسة. يحفظها LedGix Rent خاصة بحسابك، ولا يستخدمها أبدًا لأغراض إعلانية.',
    secLink: 'اقرأ سياسة الخصوصية',
    sec1t: 'خاصة بحسابك',
    sec1d: 'تُحفظ سجلات وملفات كل مالك بشكل منفصل، ولا يستطيع فتحها إلا صاحب الحساب المسجّل.',
    sec2t: 'سجّل الدخول بطريقتك',
    sec2d: 'استخدم LedGix ID أو Google أو Apple أو البريد الإلكتروني. حساب LedGix ID واحد يعمل في كل تطبيقات LedGix.',
    sec3t: 'احذف حسابك متى شئت',
    sec3d: 'احذف حسابك من داخل التطبيق وسيُحذف معه كل ما فيه.',
    sec4t: 'لا إعلانات ولا بيع للبيانات',
    sec4d: 'لا نعرض إعلانات، ولا نبيع معلوماتك أو نشاركها لأغراض إعلانية.',
    faqEyebrow: 'الأسئلة الشائعة',
    faqTitle: 'أسئلة يطرحها الملاك',
    q1: 'لمن صُمّم LedGix Rent؟',
    a1: 'للملاك في الإمارات الذين يديرون وحداتهم بأنفسهم، سواء كانت شقة واحدة أو محفظة من الشقق والفلل والمكاتب.',
    q2: 'هل يعمل باللغة العربية؟',
    a2: 'نعم. التطبيق كاملًا متاح بالعربية والإنجليزية مع دعم كامل للاتجاه من اليمين إلى اليسار، ويمكنك تبديل اللغة في أي وقت.',
    q3: 'هل يستطيع قراءة إيجاري أو عقد الإيجار أو فاتورة ديوا؟',
    a3: 'نعم في تطبيقَي iPhone وAndroid. امسح المستند أو ارفعه وسيعبّئ LedGix Rent البيانات من نصّه الإنجليزي لتراجعها. النص الموجود بالعربية فقط لا يُقرأ بعد، ويمكنك تعديل كل حقل.',
    q4: 'هل هو مرتبط بإيجاري أو ديوا أو ملاك؟',
    a4: 'ليس بشكل مباشر بعد. يحفظ LedGix Rent بيانات ومستندات إيجاري وديوا وملاك مع كل وحدة، أما الربط المباشر بهذه الخدمات فغير مفعّل حاليًا.',
    q5: 'ما هو LedGix ID؟',
    a5: 'حساب واحد لكل تطبيقات LedGix. إذا كنت تستخدم تطبيقًا آخر من LedGix، فسجّل الدخول إلى LedGix Rent بالحساب نفسه. ويمكنك أيضًا استخدام Google أو Apple أو البريد الإلكتروني.',
    q6: 'متى يصدر تطبيقا iPhone وAndroid؟',
    a6: 'هما قيد الاختبار الآن. وحتى صدورهما يمكنك استخدام LedGix Rent من أي متصفح، وستجد بياناتك عند تثبيت التطبيق.',
    q7: 'كيف أحذف حسابي؟',
    a7: 'اختر «حذف الحساب» من إعدادات التطبيق، وسيُحذف حسابك وسجلاتك وملفاتك نهائيًا. وإذا تعذّر عليك الدخول إلى التطبيق، راسل support@getledgix.com من البريد المسجّل في حسابك.',
    q8: 'كيف أحصل على المساعدة؟',
    a8: 'راسلنا على',
    ctaTitle: 'دع إيجاراتك تُدار بسلاسة.',
    ctaLede: 'سجّل الدخول باستخدام LedGix ID أو Google أو Apple أو البريد الإلكتروني، وأضف أول عقار خلال دقائق.',
    footTag: 'الإيجارات والشيكات والصيانة للملاك في الإمارات.',
    footProduct: 'المنتج',
    footSupport: 'الدعم',
    footLegal: 'قانوني',
    privacy: 'سياسة الخصوصية',
    footDelete: 'حذف الحساب',
    partOf: 'جزء من LedGix'
  };

  var EN = {};
  var nodes = document.querySelectorAll('[data-i18n]');
  nodes.forEach(function (el) { EN[el.getAttribute('data-i18n')] = el.textContent; });
  var titles = {
    en: document.title,
    ar: 'LedGix Rent · الإيجارات والشيكات والصيانة للملاك في الإمارات'
  };

  function store(key, value) { try { localStorage.setItem(key, value); } catch (e) {} }

  function applyLang(lang) {
    var dict = lang === 'ar' ? AR : EN;
    nodes.forEach(function (el) {
      var k = el.getAttribute('data-i18n');
      if (dict[k] != null) el.textContent = dict[k];
    });
    root.lang = lang;
    root.dir = lang === 'ar' ? 'rtl' : 'ltr';
    document.title = titles[lang];
    document.querySelectorAll('[data-lang-toggle]').forEach(function (b) {
      b.textContent = lang === 'ar' ? 'English' : 'العربية';
      b.setAttribute('aria-label', lang === 'ar' ? 'Switch to English' : 'التبديل إلى العربية');
      b.setAttribute('lang', lang === 'ar' ? 'en' : 'ar');
    });
    // Carry the language into the app, so /app/ opens in the same language.
    document.querySelectorAll('a[href^="/app/"]').forEach(function (a) {
      a.setAttribute('href', lang === 'ar' ? '/app/?lang=ar' : '/app/');
    });
    document.querySelectorAll('a[data-ar-href]').forEach(function (a) {
      if (!a.hasAttribute('data-en-href')) a.setAttribute('data-en-href', a.getAttribute('href'));
      a.setAttribute('href', lang === 'ar' ? a.getAttribute('data-ar-href') : a.getAttribute('data-en-href'));
    });
  }

  function applyTheme(theme) {
    root.setAttribute('data-theme', theme);
    document.querySelectorAll('[data-theme-toggle]').forEach(function (b) {
      var dark = theme === 'dark';
      b.setAttribute('aria-pressed', String(dark));
      b.setAttribute('aria-label', dark ? 'Light mode' : 'Dark mode');
    });
  }

  applyLang(root.lang === 'ar' ? 'ar' : 'en');
  applyTheme(root.getAttribute('data-theme') === 'dark' ? 'dark' : 'light');

  document.addEventListener('click', function (e) {
    var t = e.target.closest('[data-lang-toggle],[data-theme-toggle],[data-menu-toggle],.mobile-panel a');
    if (!t) return;
    if (t.hasAttribute('data-lang-toggle')) {
      var next = root.lang === 'ar' ? 'en' : 'ar';
      applyLang(next); store('ledgix-rent-lang', next);
    } else if (t.hasAttribute('data-theme-toggle')) {
      var theme = root.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
      applyTheme(theme); store('ledgix-theme', theme);
    } else if (t.hasAttribute('data-menu-toggle')) {
      var open = !document.body.classList.contains('nav-open');
      document.body.classList.toggle('nav-open', open);
      t.setAttribute('aria-expanded', String(open));
    } else {
      document.body.classList.remove('nav-open');
      document.querySelectorAll('[data-menu-toggle]').forEach(function (b) { b.setAttribute('aria-expanded', 'false'); });
    }
  });

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && document.body.classList.contains('nav-open')) {
      document.body.classList.remove('nav-open');
      document.querySelectorAll('[data-menu-toggle]').forEach(function (b) { b.setAttribute('aria-expanded', 'false'); b.focus(); });
    }
  });

  // Follow the system theme until the visitor picks one.
  var mq = matchMedia('(prefers-color-scheme: dark)');
  var listener = function (ev) {
    var chosen = null;
    try { chosen = localStorage.getItem('ledgix-theme'); } catch (e) {}
    if (!chosen) applyTheme(ev.matches ? 'dark' : 'light');
  };
  if (mq.addEventListener) mq.addEventListener('change', listener);
})();
