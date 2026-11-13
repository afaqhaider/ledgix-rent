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
  String get leases => 'Leases';

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
  String get addLease => 'Add lease';

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
}
