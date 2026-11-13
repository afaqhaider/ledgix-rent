// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'LedGix Rent';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get phone => 'Phone (+971…)';

  @override
  String get sendOtp => 'Send code';

  @override
  String get otpCode => 'Verification code';

  @override
  String get verify => 'Verify';

  @override
  String get continueWithLedgix => 'Continue with LedGix ID';

  @override
  String get orDivider => 'or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get loginTitle => 'Sign in to LedGix Rent';

  @override
  String get signUpTitle => 'Create your LedGix Rent account';

  @override
  String get loginSubtitle => 'Rent, cheques and maintenance in one place.';

  @override
  String get orUseEmail => 'or use your email';

  @override
  String get orUsePhone => 'or use your phone number';

  @override
  String get otherOptions => 'Other ways to continue';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPasswordTitle => 'Reset your password';

  @override
  String get resetPasswordBody =>
      'Enter the email you sign in with and we\'ll send you a link to choose a new password.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String resetLinkSent(String email) {
    return 'If an account exists for $email, a reset link is on its way.';
  }

  @override
  String get noAccountYet => 'New to LedGix Rent?';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get usePhoneInstead => 'Use phone number instead';

  @override
  String get useEmailInstead => 'Use email instead';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get brandHeadline => 'Rent, cheques and maintenance. One calm place.';

  @override
  String get brandBullet1 => 'Deposit reminders before every cheque is due';

  @override
  String get brandBullet2 => 'Ejari, DEWA and documents kept with each unit';

  @override
  String get brandBullet3 => 'Forward maintenance and approve quotes in a tap';

  @override
  String get partOfLedgix => 'Part of LedGix';

  @override
  String get emailRequired => 'Enter your email address';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get passwordRequired => 'Enter your password';

  @override
  String get passwordTooShort => 'Use at least 6 characters';

  @override
  String get phoneRequired => 'Enter your phone number with country code';

  @override
  String get errInvalidCredentials =>
      'That email and password don\'t match. Try again or reset your password.';

  @override
  String get errEmailInUse =>
      'An account with this email already exists. Sign in instead.';

  @override
  String get errWeakPassword =>
      'Choose a stronger password (at least 6 characters).';

  @override
  String get errInvalidEmail => 'That email address doesn\'t look right.';

  @override
  String get errUserDisabled =>
      'This account has been disabled. Contact support@getledgix.com.';

  @override
  String get errTooManyRequests =>
      'Too many attempts. Wait a few minutes and try again.';

  @override
  String get errNetwork =>
      'Couldn\'t connect. Check your internet connection and try again.';

  @override
  String get errMethodDisabled =>
      'This sign-in option isn\'t available yet. Try another one.';

  @override
  String get errPopupBlocked =>
      'Your browser blocked the sign-in window. Allow pop-ups for this site and try again.';

  @override
  String get errAccountExists =>
      'This email is registered with a different sign-in option. Use the one you signed up with.';

  @override
  String get errInvalidPhone =>
      'Enter your number with the country code, for example +971 50 123 4567.';

  @override
  String get errInvalidCode =>
      'That code isn\'t right or has expired. Check the SMS and try again.';

  @override
  String get errLedgix => 'LedGix ID sign-in didn\'t finish. Please try again.';

  @override
  String get errGeneric => 'Something went wrong. Please try again.';

  @override
  String get emailTab => 'Email';

  @override
  String get phoneTab => 'Phone';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get continueLabel => 'Continue';

  @override
  String get welcomeTitle => 'Welcome, landlord!';

  @override
  String get welcomeSub => 'Choose your language and add your first property.';

  @override
  String get yourName => 'Your name';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get portfolio => 'Portfolio';

  @override
  String get cheques => 'Cheques';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get more => 'More';

  @override
  String get tenants => 'Tenants';

  @override
  String get leases => 'Rent agreements';

  @override
  String get vendors => 'Vendors';

  @override
  String get holdRequests => 'Hold requests';

  @override
  String get directDebits => 'Direct debits';

  @override
  String get documents => 'Documents';

  @override
  String get signOut => 'Sign out';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your account and everything in it: properties, tenants, leases, payments, cheque photos, documents and maintenance records. It can\'t be undone.';

  @override
  String get accountDeleted => 'Your account has been deleted.';

  @override
  String get collectedMonth => 'Collected this month';

  @override
  String get outstandingMonth => 'Outstanding this month';

  @override
  String get collectedYear => 'Collected this year';

  @override
  String get outstandingYear => 'Outstanding this year';

  @override
  String get upcomingCheques => 'Upcoming cheques';

  @override
  String get openTickets => 'Open tickets';

  @override
  String get nothingYet => 'Nothing here yet';

  @override
  String get addProperty => 'Add property';

  @override
  String get propertyName => 'Property name';

  @override
  String get propertyType => 'Type';

  @override
  String get villa => 'Villa';

  @override
  String get apartment => 'Apartment';

  @override
  String get studio => 'Studio';

  @override
  String get other => 'Other';

  @override
  String get address => 'Address';

  @override
  String get community => 'Community';

  @override
  String get titleDeedNo => 'Title deed no.';

  @override
  String get dewaAccountNo => 'DEWA account no.';

  @override
  String get occupied => 'Occupied';

  @override
  String get vacant => 'Vacant';

  @override
  String get nextDue => 'Next due';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get required => 'Required';

  @override
  String get addTenant => 'Add tenant';

  @override
  String get tenantName => 'Tenant name';

  @override
  String get emiratesIdNo => 'Emirates ID no.';

  @override
  String get attachPassport => 'Attach passport copy';

  @override
  String get attachEmiratesId => 'Attach Emirates ID copy';

  @override
  String get attached => 'Attached';

  @override
  String get addLease => 'Add rent agreement';

  @override
  String get property => 'Property';

  @override
  String get tenant => 'Tenant';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String get annualRent => 'Annual rent (AED)';

  @override
  String get securityDeposit => 'Security deposit (AED)';

  @override
  String get ejariNo => 'Ejari no.';

  @override
  String get numberOfCheques => 'Number of cheques';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get cheque => 'Cheque';

  @override
  String get directDebit => 'Direct debit';

  @override
  String get addPropertyFirst => 'Add a property and a tenant first.';

  @override
  String get scheduleGenerated => 'Payment schedule created';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusDeposited => 'Deposited';

  @override
  String get statusCleared => 'Cleared';

  @override
  String get statusBounced => 'Bounced';

  @override
  String get statusOnHold => 'On hold';

  @override
  String get markDeposited => 'Mark deposited';

  @override
  String get markCleared => 'Mark cleared';

  @override
  String get markBounced => 'Mark bounced';

  @override
  String get attachPhoto => 'Attach cheque photo';

  @override
  String get chequeNo => 'Cheque no.';

  @override
  String get bankName => 'Bank';

  @override
  String get notes => 'Notes';

  @override
  String get all => 'All';

  @override
  String get dueDate => 'Due';

  @override
  String get failedDebit => 'Debit failed';

  @override
  String get requestHold => 'Request hold';

  @override
  String get requestedDate => 'New date';

  @override
  String get reason => 'Reason';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get originalDate => 'Original date';

  @override
  String get response => 'Response';

  @override
  String get holdPending => 'Pending';

  @override
  String get holdApproved => 'Approved';

  @override
  String get holdRejected => 'Rejected';

  @override
  String get newTicket => 'New ticket';

  @override
  String get title => 'Title';

  @override
  String get description => 'Description';

  @override
  String get priority => 'Priority';

  @override
  String get low => 'Low';

  @override
  String get medium => 'Medium';

  @override
  String get high => 'High';

  @override
  String get urgent => 'Urgent';

  @override
  String get ticketOpen => 'Open';

  @override
  String get ticketInProgress => 'In progress';

  @override
  String get ticketResolved => 'Resolved';

  @override
  String get vendor => 'Vendor';

  @override
  String get cost => 'Cost (AED)';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get addVendor => 'Add vendor';

  @override
  String get vendorName => 'Vendor name';

  @override
  String get trade => 'Trade';

  @override
  String get addDocument => 'Add document';

  @override
  String get docLease => 'Lease';

  @override
  String get docEjari => 'Ejari';

  @override
  String get docTitleDeed => 'Title deed';

  @override
  String get docEmiratesId => 'Emirates ID';

  @override
  String get offlineHint => 'Offline: showing saved data';

  @override
  String get ticketRequested => 'Requested';

  @override
  String get ticketQuoted => 'Quoted';

  @override
  String get ticketApproved => 'Approved';

  @override
  String get ticketScheduled => 'Scheduled';

  @override
  String get ticketCompleted => 'Completed';

  @override
  String get ticketClosed => 'Closed';

  @override
  String get category => 'Category';

  @override
  String get catAc => 'AC';

  @override
  String get catPlumbing => 'Plumbing';

  @override
  String get catElectrical => 'Electrical';

  @override
  String get catAppliances => 'Appliances';

  @override
  String get catPestControl => 'Pest control';

  @override
  String get catPainting => 'Painting';

  @override
  String get urgency => 'Urgency';

  @override
  String get emergency => 'Emergency';

  @override
  String get normal => 'Normal';

  @override
  String get visitRequired => 'Visit required?';

  @override
  String get addTimeSlot => 'Add time slot (max 3)';

  @override
  String get accessNotes => 'Access notes';

  @override
  String get addVideo => 'Add video';

  @override
  String get ticketDetails => 'Maintenance request';

  @override
  String get landlordNote => 'Note to the company';

  @override
  String get maintenanceCompany => 'Maintenance company';

  @override
  String get requestQuote => 'Request Quote';

  @override
  String get shareTenantContact => 'Share tenant contact details';

  @override
  String get forwardedApp => 'Sent in the LedGix Rent app';

  @override
  String get forwardedEmail => 'Emailed with a secure link (valid 7 days)';

  @override
  String get quotes => 'Quotes';

  @override
  String get addQuote => 'Add quote';

  @override
  String get amount => 'Amount (AED)';

  @override
  String get vat => 'VAT (AED)';

  @override
  String get scope => 'Scope of work';

  @override
  String get proposedVisit => 'Proposed visit';

  @override
  String get askQuestion => 'Ask a question';

  @override
  String get question => 'Question';

  @override
  String get quoteSubmitted => 'Submitted';

  @override
  String get quoteApproved => 'Approved';

  @override
  String get quoteRejected => 'Rejected';

  @override
  String get quoteQuestion => 'Question asked';

  @override
  String get startJob => 'Start job';

  @override
  String get completeJob => 'Mark completed';

  @override
  String get closeJob => 'Tenant confirmed & rate';

  @override
  String get rating => 'Rating';

  @override
  String get visitConfirmed => 'Visit confirmed';

  @override
  String get tradeLicenceNo => 'Trade licence no.';

  @override
  String get contactPerson => 'Contact person';

  @override
  String get services => 'Services offered (comma separated)';

  @override
  String get areasCovered => 'Areas covered (comma separated)';

  @override
  String get linkedAccount => 'LedGix Rent account id (if any)';

  @override
  String get defaultForCategories => 'Default company for';

  @override
  String get defaultCompany => 'Default maintenance company';

  @override
  String get none => 'None';

  @override
  String get utilityBills => 'Utility bills';

  @override
  String get addBill => 'Add bill';

  @override
  String get fetchBill => 'Fetch latest bill';

  @override
  String get provider => 'Provider';

  @override
  String get accountNo => 'Account no.';

  @override
  String get period => 'Period';

  @override
  String get paidBy => 'Paid by';

  @override
  String get landlord => 'Landlord';

  @override
  String get billUnpaid => 'Unpaid';

  @override
  String get billPaid => 'Paid';

  @override
  String get billOverdue => 'Overdue';

  @override
  String get markPaid => 'Mark paid';

  @override
  String get attachBill => 'Attach bill photo';

  @override
  String get noAccountNo =>
      'Add a DEWA or chiller account number to this property first.';

  @override
  String get chillerProvider => 'Chiller provider';

  @override
  String get chillerAccountNo => 'Chiller account no.';

  @override
  String get jointlyOwned => 'Jointly owned building';

  @override
  String get mollakUnitRef => 'Mollak unit reference';

  @override
  String get serviceCharges => 'Service charges';

  @override
  String get syncMollak => 'Sync from Mollak';

  @override
  String get outstanding => 'Outstanding';

  @override
  String get dueStatus => 'Due';

  @override
  String get chargePaid => 'Paid';

  @override
  String get chargeOverdue => 'Overdue';

  @override
  String get verifyEjari => 'Verify Ejari';

  @override
  String get ejariActive => 'Ejari active';

  @override
  String get ejariExpiring => 'Ejari expiring';

  @override
  String get ejariExpired => 'Ejari expired';

  @override
  String get ejariUnknown => 'Not verified';

  @override
  String get ejariExpiry => 'Ejari expiry';

  @override
  String get lastSynced => 'Last synced';

  @override
  String get reports => 'Unit reports';

  @override
  String get income => 'Income';

  @override
  String get expenses => 'Expenses';

  @override
  String get net => 'Net';

  @override
  String get yieldLabel => 'Net yield';

  @override
  String get maintenanceCost => 'Maintenance';

  @override
  String get utilitiesCost => 'Utilities';

  @override
  String get dewaLabel => 'DEWA';

  @override
  String get chillerLabel => 'Chiller';

  @override
  String get sewaLabel => 'SEWA';

  @override
  String get addcLabel => 'ADDC';

  @override
  String get aadcLabel => 'AADC';

  @override
  String get overview => 'Overview';

  @override
  String get operations => 'Operations';

  @override
  String get insights => 'Insights';

  @override
  String get properties => 'Properties';

  @override
  String get rentAgreements => 'Rent agreements';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'You\'re all caught up.';

  @override
  String get openMenu => 'Open menu';

  @override
  String goodMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String goodAfternoon(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String get dashboardSubtitle =>
      'Here\'s how your properties are doing today.';

  @override
  String get occupancy => 'Occupancy';

  @override
  String occupiedOf(int occupied, int total) {
    return '$occupied of $total occupied';
  }

  @override
  String get dueNext30 => 'Due in next 30 days';

  @override
  String paymentsCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString payments',
      one: '1 payment',
      zero: 'No payments',
    );
    return '$_temp0';
  }

  @override
  String get collections6m => 'Collections, last 6 months';

  @override
  String get leaseRenewals => 'Lease renewals';

  @override
  String get next90Days => 'Next 90 days';

  @override
  String endsInDays(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Ends in $daysString days',
      one: 'Ends tomorrow',
      zero: 'Ends today',
    );
    return '$_temp0';
  }

  @override
  String get noRenewals => 'No leases end in the next 90 days.';

  @override
  String get noUpcoming => 'No cheques due soon.';

  @override
  String get noOpenTickets => 'No open maintenance requests.';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get newRentAgreement => 'New rent agreement';

  @override
  String get recordPayment => 'Record payment';

  @override
  String get newMaintenanceRequest => 'New maintenance request';

  @override
  String get viewAll => 'View all';

  @override
  String get getStartedTitle => 'Let\'s set up your portfolio';

  @override
  String get getStartedBody =>
      'Add a property, then a tenant and a rent agreement. Cheques and reminders are created for you.';

  @override
  String get account => 'Account';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get profile => 'Profile';

  @override
  String get preferences => 'Preferences';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get remindersInfo => 'Reminders we send';

  @override
  String get reminderDeposit =>
      'Cheque deposit reminders 3 days and 1 day before the due date';

  @override
  String get reminderRenewal =>
      'Lease renewal alerts 90, 60 and 30 days before the end date';

  @override
  String get remindersDelivery =>
      'Sent as push notifications at 8:00 AM UAE time.';

  @override
  String get securitySignIn => 'Security & sign-in';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get legal => 'Legal';

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get deleteAccountHint =>
      'Permanently delete your account and all of its data.';

  @override
  String get selectPropertyForBills =>
      'Choose a property to see its utility bills.';

  @override
  String get serviceChargesHint =>
      'Service charges are synced from Mollak for jointly owned properties.';

  @override
  String unpaidBills(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString unpaid bills',
      one: '1 unpaid bill',
      zero: 'All paid',
    );
    return '$_temp0';
  }

  @override
  String get thisMonth => 'This month';

  @override
  String get thisYear => 'This year';

  @override
  String get authTagline => 'Rent, cheques and maintenance in one place.';

  @override
  String get authSubtagline =>
      'Built for landlords in the UAE: track every cheque, renew leases on time and keep tenants in the loop.';

  @override
  String get close => 'Close';

  @override
  String get filledFromScan => 'Filled from scan, please check';

  @override
  String get replaceTypedTitle => 'Replace what you typed?';

  @override
  String get replaceTypedBody =>
      'The scan found different values for these fields. Tick the ones to replace; the rest keep what you typed.';

  @override
  String get keepMine => 'Keep mine';

  @override
  String get replaceSelected => 'Replace selected';

  @override
  String scanFilled(int count, String doc) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fields filled from $doc, please review',
      one: '1 field filled from $doc, please review',
    );
    return '$_temp0';
  }

  @override
  String scanNothingNew(String doc) {
    return 'Read $doc, but found nothing new to fill.';
  }

  @override
  String get docDewaBill => 'DEWA bill';

  @override
  String get docOwnerEmiratesId => 'Emirates ID (owner)';

  @override
  String get docOwnerPassport => 'Passport (owner)';

  @override
  String get docMollak => 'Mollak / service charge';

  @override
  String get docTenancyContract => 'Tenancy contract';

  @override
  String get docEmiratesIdCopy => 'Emirates ID';

  @override
  String get docPassportCopy => 'Passport';

  @override
  String get docOther => 'Other';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseImage => 'Choose an image';

  @override
  String get choosePdf => 'Choose a PDF';

  @override
  String get fileTooLarge => 'That file is over 20 MB. Choose a smaller one.';

  @override
  String documentsMissing(String list) {
    return 'Attach: $list';
  }

  @override
  String get noDocumentsYet => 'No documents yet.';

  @override
  String get notUploadedYet => 'uploads on save';

  @override
  String get preview => 'Preview';

  @override
  String get remove => 'Remove';

  @override
  String get scanToFill => 'Scan to fill';

  @override
  String get scan => 'Scan';

  @override
  String get scanning => 'Reading…';

  @override
  String get scanNotRecognised =>
      'Couldn\'t read that document. Try a clearer photo or the PDF.';

  @override
  String get scanFailed =>
      'Scanning failed. Please try again or fill the form by hand.';

  @override
  String get scanWebNote => 'Scanning works in the iPhone and Android apps.';

  @override
  String get scanHintProperty =>
      'Title deed, DEWA bill, Ejari or tenancy contract';

  @override
  String get scanHintTenant =>
      'Emirates ID, passport, Ejari or tenancy contract';

  @override
  String get scanHintAgreement => 'Ejari certificate or tenancy contract';

  @override
  String get sectionBasicInfo => 'Basic information';

  @override
  String get sectionDewaMollak => 'DEWA & Mollak';

  @override
  String get sectionOwnership => 'Ownership';

  @override
  String get sectionHoa => 'Owners association (HOA)';

  @override
  String get sectionMaintenance => 'Maintenance';

  @override
  String get sectionDocuments => 'Documents';

  @override
  String get dewaPremiseNo => 'DEWA premise no.';

  @override
  String get mollakRegistrationNo => 'Mollak registration no.';

  @override
  String get hoaName => 'HOA name';

  @override
  String get hoaPhone => 'HOA contact number';

  @override
  String get ownerEmiratesIdNo => 'Owner\'s Emirates ID no.';

  @override
  String get ownerPassportNo => 'Owner\'s passport no.';

  @override
  String get annualRentLabel => 'Annual rent';

  @override
  String get depositLabel => 'Security deposit';

  @override
  String get aed => 'AED';

  @override
  String get editProperty => 'Edit property';

  @override
  String get edit => 'Edit';

  @override
  String get propertyNameHelper => 'For example: Marina Heights 1203';

  @override
  String get premiseHelper => '9 digits, on the DEWA bill';

  @override
  String get firstName => 'First name';

  @override
  String get middleName => 'Middle name';

  @override
  String get lastName => 'Last name';

  @override
  String get contactNo => 'Contact no.';

  @override
  String get passportNo => 'Passport no.';

  @override
  String get sectionPersonal => 'Personal details';

  @override
  String get sectionContact => 'Contact';

  @override
  String get sectionIdentity => 'Identity';

  @override
  String get editTenant => 'Edit tenant';

  @override
  String get invalidEmiratesId => 'Use the format 784-XXXX-XXXXXXX-X';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get ownIdTenantError => 'This is your own ID. A tenant can\'t use it.';

  @override
  String get ownIdTitle => 'This looks like your own Emirates ID';

  @override
  String get ownIdBody =>
      'The ID on this document matches yours, so it hasn\'t been filled in as a tenant.';

  @override
  String get ownIdAgreementBody =>
      'The tenant on this document has your own ID, so no tenant was filled in. Choose the tenant yourself.';

  @override
  String get useForMyProfile => 'Save to my profile';

  @override
  String get ownIdSaved => 'Saved to your profile.';

  @override
  String get addRentAgreement => 'Add rent agreement';

  @override
  String get editRentAgreement => 'Edit rent agreement';

  @override
  String get sectionUnitTenant => 'Unit & tenant';

  @override
  String get sectionTermRent => 'Term & rent';

  @override
  String get sectionPayment => 'Payment';

  @override
  String get newTenant => 'New tenant';

  @override
  String addScannedTenant(String name) {
    return 'Add $name as tenant';
  }

  @override
  String propertyMatched(String name) {
    return 'Matched to $name';
  }

  @override
  String get myProfile => 'My profile';

  @override
  String get myEmiratesIdNo => 'My Emirates ID no.';

  @override
  String get myPassportNo => 'My passport no.';

  @override
  String get ownIdHelper =>
      'Used to recognise your own documents, so you\'re never added as a tenant.';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get tenantRequired => 'Choose or add a tenant';

  @override
  String get noTenantsYet => 'No tenants yet. Add one to continue.';

  @override
  String get scheduleNote => 'The cheque schedule is created when you save.';

  @override
  String get tpSetupTitle => 'Set up your account';

  @override
  String get tpSetupSub =>
      'A few details to get started. You can add properties right after.';

  @override
  String get tpUnits => 'Number of units';

  @override
  String get tpUnitsHelper => 'How many units you own or manage';

  @override
  String get tpInvalidNumber => 'Enter a number (1 or more)';

  @override
  String get tpRole => 'Your role';

  @override
  String get tpRoleLandlord => 'Landlord';

  @override
  String get tpRolePropertyManager => 'Property manager';

  @override
  String get tpRoleTenant => 'Tenant';

  @override
  String get tpImTenant => 'I\'m a tenant';

  @override
  String get tpImLandlord => 'I\'m a landlord or property manager';

  @override
  String get tpAccountType => 'Account type';

  @override
  String get tpTenantWelcome => 'Welcome to LedGix Rent';

  @override
  String get tpTenantWelcomeSub =>
      'Enter your name. If your landlord gave you an invite code, add it to see your lease, payments and documents.';

  @override
  String get tpInviteCode => 'Invite code';

  @override
  String get tpInviteCodeHint => '8 characters, e.g. K7MP3QXA';

  @override
  String get tpSkip => 'Skip for now';

  @override
  String get tpCodeInvalid => 'That code isn\'t valid. Check it and try again.';

  @override
  String get tpCodeExpired =>
      'That code has expired. Ask your landlord for a new one.';

  @override
  String get tpCodeUsed =>
      'That code has already been used. Ask your landlord for a new one.';

  @override
  String get tpCodeOwn =>
      'That\'s an invite code you created. Share it with your tenant instead.';

  @override
  String get tpCodeAlreadyLinked =>
      'This tenant record is already linked to another account.';

  @override
  String get tpLandlordAdded => 'Landlord added.';

  @override
  String get tpInviteToApp => 'Invite to app';

  @override
  String tpInviteTitle(String name) {
    return 'Invite $name to LedGix Rent';
  }

  @override
  String tpInviteBody(String date) {
    return 'Share this code with your tenant. They enter it in the LedGix Rent app to see their lease, payments and the documents you share. It expires on $date.';
  }

  @override
  String get tpCopyCode => 'Copy code';

  @override
  String get tpShare => 'Share';

  @override
  String get tpCodeCopied => 'Code copied';

  @override
  String tpInviteShareText(String code) {
    return 'Join me on LedGix Rent to see your lease, payments and documents. Your invite code: $code. Open https://rent.getledgix.com/app/ to sign up as a tenant.';
  }

  @override
  String get tpNewCode => 'New code';

  @override
  String get tpNotInvited => 'Not invited';

  @override
  String get tpInvited => 'Invited';

  @override
  String get tpJoined => 'Joined the app';

  @override
  String get tpLater => 'Later';

  @override
  String get tpShareWithTenant => 'Share with tenant';

  @override
  String get tpSharedWithTenant => 'Shared with tenant';

  @override
  String get tpShareChequeCopy => 'Cheque copy shared with tenant';

  @override
  String get tpHome => 'Home';

  @override
  String get tpLandlords => 'Landlords';

  @override
  String get tpPayments => 'Payments';

  @override
  String get tpInspections => 'Inspections';

  @override
  String get tpManageLandlords => 'Manage landlords';

  @override
  String get tpAddLandlord => 'Add landlord';

  @override
  String get tpAddLandlordHint =>
      'Enter the invite code your landlord shared with you.';

  @override
  String get tpCurrent => 'Current';

  @override
  String get tpFormer => 'Former';

  @override
  String get tpRemove => 'Remove';

  @override
  String tpRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get tpRemoveBody =>
      'Your past lease with this landlord will no longer show in your app. They can add you again with a new code.';

  @override
  String get tpNoLandlords =>
      'No landlords yet. Ask your landlord for an invite code.';

  @override
  String get tpLandlordDetails => 'Landlord details';

  @override
  String get tpAgreement => 'Agreement';

  @override
  String get tpSharedDocuments => 'Shared documents';

  @override
  String get tpNoSharedDocuments => 'No documents shared yet.';

  @override
  String get tpOpenDocument => 'Open';

  @override
  String get tpNextPayment => 'Next payment';

  @override
  String get tpNoUpcoming => 'No upcoming payments.';

  @override
  String get tpYourLeases => 'Your leases';

  @override
  String tpLeaseWith(String name) {
    return 'with $name';
  }

  @override
  String get tpRecentDocuments => 'Recent documents';

  @override
  String get tpChequeCopy => 'Cheque copy';

  @override
  String get tpViewChequeCopy => 'View cheque copy';

  @override
  String get tpNewRequest => 'New request';

  @override
  String get tpRequestSent => 'Request sent to your landlord.';

  @override
  String get tpRequestTitle => 'What needs fixing?';

  @override
  String get tpRequestDetails => 'Details';

  @override
  String get tpAddPhotos => 'Add photos';

  @override
  String tpPhotosAdded(int count) {
    return '$count photo(s) added';
  }

  @override
  String get tpMyRequests =>
      'Requests are tracked by your landlord. You\'ll get updates when they act on them.';

  @override
  String get tpNoInspections => 'No inspections yet.';

  @override
  String get tpMoveIn => 'Move-in inspection';

  @override
  String get tpMoveOut => 'Move-out inspection';

  @override
  String get tpInspection => 'Inspection';

  @override
  String get tpEnded => 'Ended';

  @override
  String get tpActive => 'Active';

  @override
  String get tpPropertyDetails => 'Property details';

  @override
  String get tpNoProperties =>
      'No properties yet. They appear once your landlord adds your rent agreement.';

  @override
  String get tpRentReminders =>
      'Rent reminders 7, 3 and 1 days before each payment, and on the due day';

  @override
  String get tpRenewalReminders => 'Lease end reminders 60 and 30 days before';

  @override
  String get tpBounced => 'Alerts if a cheque bounces or is put on hold';

  @override
  String tpLeasePeriod(String start, String end) {
    return '$start to $end';
  }

  @override
  String get tpChoosePropertyFirst => 'Choose a property';

  @override
  String tpSince(String date) {
    return 'Since $date';
  }
}
