import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'LedGix Rent'**
  String get appName;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone (+971…)'**
  String get phone;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendOtp;

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get otpCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @continueWithLedgix.
  ///
  /// In en, this message translates to:
  /// **'Continue with LedGix ID'**
  String get continueWithLedgix;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to LedGix Rent'**
  String get loginTitle;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your LedGix Rent account'**
  String get signUpTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rent, cheques and maintenance in one place.'**
  String get loginSubtitle;

  /// No description provided for @orUseEmail.
  ///
  /// In en, this message translates to:
  /// **'or use your email'**
  String get orUseEmail;

  /// No description provided for @orUsePhone.
  ///
  /// In en, this message translates to:
  /// **'or use your phone number'**
  String get orUsePhone;

  /// No description provided for @otherOptions.
  ///
  /// In en, this message translates to:
  /// **'Other ways to continue'**
  String get otherOptions;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the email you sign in with and we\'ll send you a link to choose a new password.'**
  String get resetPasswordBody;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for {email}, a reset link is on its way.'**
  String resetLinkSent(String email);

  /// No description provided for @noAccountYet.
  ///
  /// In en, this message translates to:
  /// **'New to LedGix Rent?'**
  String get noAccountYet;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @usePhoneInstead.
  ///
  /// In en, this message translates to:
  /// **'Use phone number instead'**
  String get usePhoneInstead;

  /// No description provided for @useEmailInstead.
  ///
  /// In en, this message translates to:
  /// **'Use email instead'**
  String get useEmailInstead;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @brandHeadline.
  ///
  /// In en, this message translates to:
  /// **'Rent, cheques and maintenance. One calm place.'**
  String get brandHeadline;

  /// No description provided for @brandBullet1.
  ///
  /// In en, this message translates to:
  /// **'Deposit reminders before every cheque is due'**
  String get brandBullet1;

  /// No description provided for @brandBullet2.
  ///
  /// In en, this message translates to:
  /// **'Ejari, DEWA and documents kept with each unit'**
  String get brandBullet2;

  /// No description provided for @brandBullet3.
  ///
  /// In en, this message translates to:
  /// **'Forward maintenance and approve quotes in a tap'**
  String get brandBullet3;

  /// No description provided for @partOfLedgix.
  ///
  /// In en, this message translates to:
  /// **'Part of LedGix'**
  String get partOfLedgix;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number with country code'**
  String get phoneRequired;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'That email and password don\'t match. Try again or reset your password.'**
  String get errInvalidCredentials;

  /// No description provided for @errEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Sign in instead.'**
  String get errEmailInUse;

  /// No description provided for @errWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password (at least 6 characters).'**
  String get errWeakPassword;

  /// No description provided for @errInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That email address doesn\'t look right.'**
  String get errInvalidEmail;

  /// No description provided for @errUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled. Contact support@getledgix.com.'**
  String get errUserDisabled;

  /// No description provided for @errTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a few minutes and try again.'**
  String get errTooManyRequests;

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect. Check your internet connection and try again.'**
  String get errNetwork;

  /// No description provided for @errMethodDisabled.
  ///
  /// In en, this message translates to:
  /// **'This sign-in option isn\'t available yet. Try another one.'**
  String get errMethodDisabled;

  /// No description provided for @errPopupBlocked.
  ///
  /// In en, this message translates to:
  /// **'Your browser blocked the sign-in window. Allow pop-ups for this site and try again.'**
  String get errPopupBlocked;

  /// No description provided for @errAccountExists.
  ///
  /// In en, this message translates to:
  /// **'This email is registered with a different sign-in option. Use the one you signed up with.'**
  String get errAccountExists;

  /// No description provided for @errInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your number with the country code, for example +971 50 123 4567.'**
  String get errInvalidPhone;

  /// No description provided for @errInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'That code isn\'t right or has expired. Check the SMS and try again.'**
  String get errInvalidCode;

  /// No description provided for @errLedgix.
  ///
  /// In en, this message translates to:
  /// **'LedGix ID sign-in didn\'t finish. Please try again.'**
  String get errLedgix;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errGeneric;

  /// No description provided for @emailTab.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailTab;

  /// No description provided for @phoneTab.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneTab;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome, landlord!'**
  String get welcomeTitle;

  /// No description provided for @welcomeSub.
  ///
  /// In en, this message translates to:
  /// **'Choose your language and add your first property.'**
  String get welcomeSub;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @portfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolio;

  /// No description provided for @cheques.
  ///
  /// In en, this message translates to:
  /// **'Cheques'**
  String get cheques;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @tenants.
  ///
  /// In en, this message translates to:
  /// **'Tenants'**
  String get tenants;

  /// No description provided for @leases.
  ///
  /// In en, this message translates to:
  /// **'Rent agreements'**
  String get leases;

  /// No description provided for @vendors.
  ///
  /// In en, this message translates to:
  /// **'Vendors'**
  String get vendors;

  /// No description provided for @holdRequests.
  ///
  /// In en, this message translates to:
  /// **'Hold requests'**
  String get holdRequests;

  /// No description provided for @directDebits.
  ///
  /// In en, this message translates to:
  /// **'Direct debits'**
  String get directDebits;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and everything in it: properties, tenants, leases, payments, cheque photos, documents and maintenance records. It can\'t be undone.'**
  String get deleteAccountBody;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get accountDeleted;

  /// No description provided for @collectedMonth.
  ///
  /// In en, this message translates to:
  /// **'Collected this month'**
  String get collectedMonth;

  /// No description provided for @outstandingMonth.
  ///
  /// In en, this message translates to:
  /// **'Outstanding this month'**
  String get outstandingMonth;

  /// No description provided for @collectedYear.
  ///
  /// In en, this message translates to:
  /// **'Collected this year'**
  String get collectedYear;

  /// No description provided for @outstandingYear.
  ///
  /// In en, this message translates to:
  /// **'Outstanding this year'**
  String get outstandingYear;

  /// No description provided for @upcomingCheques.
  ///
  /// In en, this message translates to:
  /// **'Upcoming cheques'**
  String get upcomingCheques;

  /// No description provided for @openTickets.
  ///
  /// In en, this message translates to:
  /// **'Open tickets'**
  String get openTickets;

  /// No description provided for @nothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get nothingYet;

  /// No description provided for @addProperty.
  ///
  /// In en, this message translates to:
  /// **'Add property'**
  String get addProperty;

  /// No description provided for @propertyName.
  ///
  /// In en, this message translates to:
  /// **'Property name'**
  String get propertyName;

  /// No description provided for @propertyType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get propertyType;

  /// No description provided for @villa.
  ///
  /// In en, this message translates to:
  /// **'Villa'**
  String get villa;

  /// No description provided for @apartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get apartment;

  /// No description provided for @studio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get studio;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @titleDeedNo.
  ///
  /// In en, this message translates to:
  /// **'Title deed no.'**
  String get titleDeedNo;

  /// No description provided for @dewaAccountNo.
  ///
  /// In en, this message translates to:
  /// **'DEWA account no.'**
  String get dewaAccountNo;

  /// No description provided for @occupied.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get occupied;

  /// No description provided for @vacant.
  ///
  /// In en, this message translates to:
  /// **'Vacant'**
  String get vacant;

  /// No description provided for @nextDue.
  ///
  /// In en, this message translates to:
  /// **'Next due'**
  String get nextDue;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @addTenant.
  ///
  /// In en, this message translates to:
  /// **'Add tenant'**
  String get addTenant;

  /// No description provided for @tenantName.
  ///
  /// In en, this message translates to:
  /// **'Tenant name'**
  String get tenantName;

  /// No description provided for @emiratesIdNo.
  ///
  /// In en, this message translates to:
  /// **'Emirates ID no.'**
  String get emiratesIdNo;

  /// No description provided for @attachPassport.
  ///
  /// In en, this message translates to:
  /// **'Attach passport copy'**
  String get attachPassport;

  /// No description provided for @attachEmiratesId.
  ///
  /// In en, this message translates to:
  /// **'Attach Emirates ID copy'**
  String get attachEmiratesId;

  /// No description provided for @attached.
  ///
  /// In en, this message translates to:
  /// **'Attached'**
  String get attached;

  /// No description provided for @addLease.
  ///
  /// In en, this message translates to:
  /// **'Add rent agreement'**
  String get addLease;

  /// No description provided for @property.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get property;

  /// No description provided for @tenant.
  ///
  /// In en, this message translates to:
  /// **'Tenant'**
  String get tenant;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @annualRent.
  ///
  /// In en, this message translates to:
  /// **'Annual rent (AED)'**
  String get annualRent;

  /// No description provided for @securityDeposit.
  ///
  /// In en, this message translates to:
  /// **'Security deposit (AED)'**
  String get securityDeposit;

  /// No description provided for @ejariNo.
  ///
  /// In en, this message translates to:
  /// **'Ejari no.'**
  String get ejariNo;

  /// No description provided for @numberOfCheques.
  ///
  /// In en, this message translates to:
  /// **'Number of cheques'**
  String get numberOfCheques;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @cheque.
  ///
  /// In en, this message translates to:
  /// **'Cheque'**
  String get cheque;

  /// No description provided for @directDebit.
  ///
  /// In en, this message translates to:
  /// **'Direct debit'**
  String get directDebit;

  /// No description provided for @addPropertyFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a property and a tenant first.'**
  String get addPropertyFirst;

  /// No description provided for @scheduleGenerated.
  ///
  /// In en, this message translates to:
  /// **'Payment schedule created'**
  String get scheduleGenerated;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusDeposited.
  ///
  /// In en, this message translates to:
  /// **'Deposited'**
  String get statusDeposited;

  /// No description provided for @statusCleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get statusCleared;

  /// No description provided for @statusBounced.
  ///
  /// In en, this message translates to:
  /// **'Bounced'**
  String get statusBounced;

  /// No description provided for @statusOnHold.
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get statusOnHold;

  /// No description provided for @markDeposited.
  ///
  /// In en, this message translates to:
  /// **'Mark deposited'**
  String get markDeposited;

  /// No description provided for @markCleared.
  ///
  /// In en, this message translates to:
  /// **'Mark cleared'**
  String get markCleared;

  /// No description provided for @markBounced.
  ///
  /// In en, this message translates to:
  /// **'Mark bounced'**
  String get markBounced;

  /// No description provided for @attachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach cheque photo'**
  String get attachPhoto;

  /// No description provided for @chequeNo.
  ///
  /// In en, this message translates to:
  /// **'Cheque no.'**
  String get chequeNo;

  /// No description provided for @bankName.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bankName;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get dueDate;

  /// No description provided for @failedDebit.
  ///
  /// In en, this message translates to:
  /// **'Debit failed'**
  String get failedDebit;

  /// No description provided for @requestHold.
  ///
  /// In en, this message translates to:
  /// **'Request hold'**
  String get requestHold;

  /// No description provided for @requestedDate.
  ///
  /// In en, this message translates to:
  /// **'New date'**
  String get requestedDate;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @originalDate.
  ///
  /// In en, this message translates to:
  /// **'Original date'**
  String get originalDate;

  /// No description provided for @response.
  ///
  /// In en, this message translates to:
  /// **'Response'**
  String get response;

  /// No description provided for @holdPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get holdPending;

  /// No description provided for @holdApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get holdApproved;

  /// No description provided for @holdRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get holdRejected;

  /// No description provided for @newTicket.
  ///
  /// In en, this message translates to:
  /// **'New ticket'**
  String get newTicket;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @ticketOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get ticketOpen;

  /// No description provided for @ticketInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get ticketInProgress;

  /// No description provided for @ticketResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get ticketResolved;

  /// No description provided for @vendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get vendor;

  /// No description provided for @cost.
  ///
  /// In en, this message translates to:
  /// **'Cost (AED)'**
  String get cost;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @addVendor.
  ///
  /// In en, this message translates to:
  /// **'Add vendor'**
  String get addVendor;

  /// No description provided for @vendorName.
  ///
  /// In en, this message translates to:
  /// **'Vendor name'**
  String get vendorName;

  /// No description provided for @trade.
  ///
  /// In en, this message translates to:
  /// **'Trade'**
  String get trade;

  /// No description provided for @addDocument.
  ///
  /// In en, this message translates to:
  /// **'Add document'**
  String get addDocument;

  /// No description provided for @docLease.
  ///
  /// In en, this message translates to:
  /// **'Lease'**
  String get docLease;

  /// No description provided for @docEjari.
  ///
  /// In en, this message translates to:
  /// **'Ejari'**
  String get docEjari;

  /// No description provided for @docTitleDeed.
  ///
  /// In en, this message translates to:
  /// **'Title deed'**
  String get docTitleDeed;

  /// No description provided for @docEmiratesId.
  ///
  /// In en, this message translates to:
  /// **'Emirates ID'**
  String get docEmiratesId;

  /// No description provided for @offlineHint.
  ///
  /// In en, this message translates to:
  /// **'Offline: showing saved data'**
  String get offlineHint;

  /// No description provided for @ticketRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get ticketRequested;

  /// No description provided for @ticketQuoted.
  ///
  /// In en, this message translates to:
  /// **'Quoted'**
  String get ticketQuoted;

  /// No description provided for @ticketApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get ticketApproved;

  /// No description provided for @ticketScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get ticketScheduled;

  /// No description provided for @ticketCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get ticketCompleted;

  /// No description provided for @ticketClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get ticketClosed;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @catAc.
  ///
  /// In en, this message translates to:
  /// **'AC'**
  String get catAc;

  /// No description provided for @catPlumbing.
  ///
  /// In en, this message translates to:
  /// **'Plumbing'**
  String get catPlumbing;

  /// No description provided for @catElectrical.
  ///
  /// In en, this message translates to:
  /// **'Electrical'**
  String get catElectrical;

  /// No description provided for @catAppliances.
  ///
  /// In en, this message translates to:
  /// **'Appliances'**
  String get catAppliances;

  /// No description provided for @catPestControl.
  ///
  /// In en, this message translates to:
  /// **'Pest control'**
  String get catPestControl;

  /// No description provided for @catPainting.
  ///
  /// In en, this message translates to:
  /// **'Painting'**
  String get catPainting;

  /// No description provided for @urgency.
  ///
  /// In en, this message translates to:
  /// **'Urgency'**
  String get urgency;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @visitRequired.
  ///
  /// In en, this message translates to:
  /// **'Visit required?'**
  String get visitRequired;

  /// No description provided for @addTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Add time slot (max 3)'**
  String get addTimeSlot;

  /// No description provided for @accessNotes.
  ///
  /// In en, this message translates to:
  /// **'Access notes'**
  String get accessNotes;

  /// No description provided for @addVideo.
  ///
  /// In en, this message translates to:
  /// **'Add video'**
  String get addVideo;

  /// No description provided for @ticketDetails.
  ///
  /// In en, this message translates to:
  /// **'Maintenance request'**
  String get ticketDetails;

  /// No description provided for @landlordNote.
  ///
  /// In en, this message translates to:
  /// **'Note to the company'**
  String get landlordNote;

  /// No description provided for @maintenanceCompany.
  ///
  /// In en, this message translates to:
  /// **'Maintenance company'**
  String get maintenanceCompany;

  /// No description provided for @requestQuote.
  ///
  /// In en, this message translates to:
  /// **'Request Quote'**
  String get requestQuote;

  /// No description provided for @shareTenantContact.
  ///
  /// In en, this message translates to:
  /// **'Share tenant contact details'**
  String get shareTenantContact;

  /// No description provided for @forwardedApp.
  ///
  /// In en, this message translates to:
  /// **'Sent in the LedGix Rent app'**
  String get forwardedApp;

  /// No description provided for @forwardedEmail.
  ///
  /// In en, this message translates to:
  /// **'Emailed with a secure link (valid 7 days)'**
  String get forwardedEmail;

  /// No description provided for @quotes.
  ///
  /// In en, this message translates to:
  /// **'Quotes'**
  String get quotes;

  /// No description provided for @addQuote.
  ///
  /// In en, this message translates to:
  /// **'Add quote'**
  String get addQuote;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount (AED)'**
  String get amount;

  /// No description provided for @vat.
  ///
  /// In en, this message translates to:
  /// **'VAT (AED)'**
  String get vat;

  /// No description provided for @scope.
  ///
  /// In en, this message translates to:
  /// **'Scope of work'**
  String get scope;

  /// No description provided for @proposedVisit.
  ///
  /// In en, this message translates to:
  /// **'Proposed visit'**
  String get proposedVisit;

  /// No description provided for @askQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask a question'**
  String get askQuestion;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @quoteSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get quoteSubmitted;

  /// No description provided for @quoteApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get quoteApproved;

  /// No description provided for @quoteRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get quoteRejected;

  /// No description provided for @quoteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question asked'**
  String get quoteQuestion;

  /// No description provided for @startJob.
  ///
  /// In en, this message translates to:
  /// **'Start job'**
  String get startJob;

  /// No description provided for @completeJob.
  ///
  /// In en, this message translates to:
  /// **'Mark completed'**
  String get completeJob;

  /// No description provided for @closeJob.
  ///
  /// In en, this message translates to:
  /// **'Tenant confirmed & rate'**
  String get closeJob;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @visitConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Visit confirmed'**
  String get visitConfirmed;

  /// No description provided for @tradeLicenceNo.
  ///
  /// In en, this message translates to:
  /// **'Trade licence no.'**
  String get tradeLicenceNo;

  /// No description provided for @contactPerson.
  ///
  /// In en, this message translates to:
  /// **'Contact person'**
  String get contactPerson;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services offered (comma separated)'**
  String get services;

  /// No description provided for @areasCovered.
  ///
  /// In en, this message translates to:
  /// **'Areas covered (comma separated)'**
  String get areasCovered;

  /// No description provided for @linkedAccount.
  ///
  /// In en, this message translates to:
  /// **'LedGix Rent account id (if any)'**
  String get linkedAccount;

  /// No description provided for @defaultForCategories.
  ///
  /// In en, this message translates to:
  /// **'Default company for'**
  String get defaultForCategories;

  /// No description provided for @defaultCompany.
  ///
  /// In en, this message translates to:
  /// **'Default maintenance company'**
  String get defaultCompany;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @utilityBills.
  ///
  /// In en, this message translates to:
  /// **'Utility bills'**
  String get utilityBills;

  /// No description provided for @addBill.
  ///
  /// In en, this message translates to:
  /// **'Add bill'**
  String get addBill;

  /// No description provided for @fetchBill.
  ///
  /// In en, this message translates to:
  /// **'Fetch latest bill'**
  String get fetchBill;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @accountNo.
  ///
  /// In en, this message translates to:
  /// **'Account no.'**
  String get accountNo;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @paidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get paidBy;

  /// No description provided for @landlord.
  ///
  /// In en, this message translates to:
  /// **'Landlord'**
  String get landlord;

  /// No description provided for @billUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get billUnpaid;

  /// No description provided for @billPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get billPaid;

  /// No description provided for @billOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get billOverdue;

  /// No description provided for @markPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get markPaid;

  /// No description provided for @attachBill.
  ///
  /// In en, this message translates to:
  /// **'Attach bill photo'**
  String get attachBill;

  /// No description provided for @noAccountNo.
  ///
  /// In en, this message translates to:
  /// **'Add a DEWA or chiller account number to this property first.'**
  String get noAccountNo;

  /// No description provided for @chillerProvider.
  ///
  /// In en, this message translates to:
  /// **'Chiller provider'**
  String get chillerProvider;

  /// No description provided for @chillerAccountNo.
  ///
  /// In en, this message translates to:
  /// **'Chiller account no.'**
  String get chillerAccountNo;

  /// No description provided for @jointlyOwned.
  ///
  /// In en, this message translates to:
  /// **'Jointly owned building'**
  String get jointlyOwned;

  /// No description provided for @mollakUnitRef.
  ///
  /// In en, this message translates to:
  /// **'Mollak unit reference'**
  String get mollakUnitRef;

  /// No description provided for @serviceCharges.
  ///
  /// In en, this message translates to:
  /// **'Service charges'**
  String get serviceCharges;

  /// No description provided for @syncMollak.
  ///
  /// In en, this message translates to:
  /// **'Sync from Mollak'**
  String get syncMollak;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @dueStatus.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get dueStatus;

  /// No description provided for @chargePaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get chargePaid;

  /// No description provided for @chargeOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get chargeOverdue;

  /// No description provided for @verifyEjari.
  ///
  /// In en, this message translates to:
  /// **'Verify Ejari'**
  String get verifyEjari;

  /// No description provided for @ejariActive.
  ///
  /// In en, this message translates to:
  /// **'Ejari active'**
  String get ejariActive;

  /// No description provided for @ejariExpiring.
  ///
  /// In en, this message translates to:
  /// **'Ejari expiring'**
  String get ejariExpiring;

  /// No description provided for @ejariExpired.
  ///
  /// In en, this message translates to:
  /// **'Ejari expired'**
  String get ejariExpired;

  /// No description provided for @ejariUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get ejariUnknown;

  /// No description provided for @ejariExpiry.
  ///
  /// In en, this message translates to:
  /// **'Ejari expiry'**
  String get ejariExpiry;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced'**
  String get lastSynced;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Unit reports'**
  String get reports;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get net;

  /// No description provided for @yieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Net yield'**
  String get yieldLabel;

  /// No description provided for @maintenanceCost.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenanceCost;

  /// No description provided for @utilitiesCost.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get utilitiesCost;

  /// No description provided for @dewaLabel.
  ///
  /// In en, this message translates to:
  /// **'DEWA'**
  String get dewaLabel;

  /// No description provided for @chillerLabel.
  ///
  /// In en, this message translates to:
  /// **'Chiller'**
  String get chillerLabel;

  /// No description provided for @sewaLabel.
  ///
  /// In en, this message translates to:
  /// **'SEWA'**
  String get sewaLabel;

  /// No description provided for @addcLabel.
  ///
  /// In en, this message translates to:
  /// **'ADDC'**
  String get addcLabel;

  /// No description provided for @aadcLabel.
  ///
  /// In en, this message translates to:
  /// **'AADC'**
  String get aadcLabel;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @operations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get operations;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @properties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get properties;

  /// No description provided for @rentAgreements.
  ///
  /// In en, this message translates to:
  /// **'Rent agreements'**
  String get rentAgreements;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get noNotifications;

  /// No description provided for @openMenu.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get openMenu;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String goodMorning(String name);

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}'**
  String goodAfternoon(String name);

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String goodEvening(String name);

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s how your properties are doing today.'**
  String get dashboardSubtitle;

  /// No description provided for @occupancy.
  ///
  /// In en, this message translates to:
  /// **'Occupancy'**
  String get occupancy;

  /// No description provided for @occupiedOf.
  ///
  /// In en, this message translates to:
  /// **'{occupied} of {total} occupied'**
  String occupiedOf(int occupied, int total);

  /// No description provided for @dueNext30.
  ///
  /// In en, this message translates to:
  /// **'Due in next 30 days'**
  String get dueNext30;

  /// No description provided for @paymentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No payments} =1{1 payment} other{{count} payments}}'**
  String paymentsCount(num count);

  /// No description provided for @collections6m.
  ///
  /// In en, this message translates to:
  /// **'Collections, last 6 months'**
  String get collections6m;

  /// No description provided for @leaseRenewals.
  ///
  /// In en, this message translates to:
  /// **'Lease renewals'**
  String get leaseRenewals;

  /// No description provided for @next90Days.
  ///
  /// In en, this message translates to:
  /// **'Next 90 days'**
  String get next90Days;

  /// No description provided for @endsInDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Ends today} =1{Ends tomorrow} other{Ends in {days} days}}'**
  String endsInDays(num days);

  /// No description provided for @noRenewals.
  ///
  /// In en, this message translates to:
  /// **'No leases end in the next 90 days.'**
  String get noRenewals;

  /// No description provided for @noUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No cheques due soon.'**
  String get noUpcoming;

  /// No description provided for @noOpenTickets.
  ///
  /// In en, this message translates to:
  /// **'No open maintenance requests.'**
  String get noOpenTickets;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @newRentAgreement.
  ///
  /// In en, this message translates to:
  /// **'New rent agreement'**
  String get newRentAgreement;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get recordPayment;

  /// No description provided for @newMaintenanceRequest.
  ///
  /// In en, this message translates to:
  /// **'New maintenance request'**
  String get newMaintenanceRequest;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @getStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up your portfolio'**
  String get getStartedTitle;

  /// No description provided for @getStartedBody.
  ///
  /// In en, this message translates to:
  /// **'Add a property, then a tenant and a rent agreement. Cheques and reminders are created for you.'**
  String get getStartedBody;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @remindersInfo.
  ///
  /// In en, this message translates to:
  /// **'Reminders we send'**
  String get remindersInfo;

  /// No description provided for @reminderDeposit.
  ///
  /// In en, this message translates to:
  /// **'Cheque deposit reminders 3 days and 1 day before the due date'**
  String get reminderDeposit;

  /// No description provided for @reminderRenewal.
  ///
  /// In en, this message translates to:
  /// **'Lease renewal alerts 90, 60 and 30 days before the end date'**
  String get reminderRenewal;

  /// No description provided for @remindersDelivery.
  ///
  /// In en, this message translates to:
  /// **'Sent as push notifications at 8:00 AM UAE time.'**
  String get remindersDelivery;

  /// No description provided for @securitySignIn.
  ///
  /// In en, this message translates to:
  /// **'Security & sign-in'**
  String get securitySignIn;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(String email);

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get dangerZone;

  /// No description provided for @deleteAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and all of its data.'**
  String get deleteAccountHint;

  /// No description provided for @selectPropertyForBills.
  ///
  /// In en, this message translates to:
  /// **'Choose a property to see its utility bills.'**
  String get selectPropertyForBills;

  /// No description provided for @serviceChargesHint.
  ///
  /// In en, this message translates to:
  /// **'Service charges are synced from Mollak for jointly owned properties.'**
  String get serviceChargesHint;

  /// No description provided for @unpaidBills.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{All paid} =1{1 unpaid bill} other{{count} unpaid bills}}'**
  String unpaidBills(num count);

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get thisYear;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Rent, cheques and maintenance in one place.'**
  String get authTagline;

  /// No description provided for @authSubtagline.
  ///
  /// In en, this message translates to:
  /// **'Built for landlords in the UAE: track every cheque, renew leases on time and keep tenants in the loop.'**
  String get authSubtagline;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @filledFromScan.
  ///
  /// In en, this message translates to:
  /// **'Filled from scan, please check'**
  String get filledFromScan;

  /// No description provided for @replaceTypedTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace what you typed?'**
  String get replaceTypedTitle;

  /// No description provided for @replaceTypedBody.
  ///
  /// In en, this message translates to:
  /// **'The scan found different values for these fields. Tick the ones to replace; the rest keep what you typed.'**
  String get replaceTypedBody;

  /// No description provided for @keepMine.
  ///
  /// In en, this message translates to:
  /// **'Keep mine'**
  String get keepMine;

  /// No description provided for @replaceSelected.
  ///
  /// In en, this message translates to:
  /// **'Replace selected'**
  String get replaceSelected;

  /// No description provided for @scanFilled.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 field filled from {doc}, please review} other{{count} fields filled from {doc}, please review}}'**
  String scanFilled(int count, String doc);

  /// No description provided for @scanNothingNew.
  ///
  /// In en, this message translates to:
  /// **'Read {doc}, but found nothing new to fill.'**
  String scanNothingNew(String doc);

  /// No description provided for @docDewaBill.
  ///
  /// In en, this message translates to:
  /// **'DEWA bill'**
  String get docDewaBill;

  /// No description provided for @docOwnerEmiratesId.
  ///
  /// In en, this message translates to:
  /// **'Emirates ID (owner)'**
  String get docOwnerEmiratesId;

  /// No description provided for @docOwnerPassport.
  ///
  /// In en, this message translates to:
  /// **'Passport (owner)'**
  String get docOwnerPassport;

  /// No description provided for @docMollak.
  ///
  /// In en, this message translates to:
  /// **'Mollak / service charge'**
  String get docMollak;

  /// No description provided for @docTenancyContract.
  ///
  /// In en, this message translates to:
  /// **'Tenancy contract'**
  String get docTenancyContract;

  /// No description provided for @docEmiratesIdCopy.
  ///
  /// In en, this message translates to:
  /// **'Emirates ID'**
  String get docEmiratesIdCopy;

  /// No description provided for @docPassportCopy.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get docPassportCopy;

  /// No description provided for @docOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get docOther;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @chooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose an image'**
  String get chooseImage;

  /// No description provided for @choosePdf.
  ///
  /// In en, this message translates to:
  /// **'Choose a PDF'**
  String get choosePdf;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That file is over 20 MB. Choose a smaller one.'**
  String get fileTooLarge;

  /// No description provided for @documentsMissing.
  ///
  /// In en, this message translates to:
  /// **'Attach: {list}'**
  String documentsMissing(String list);

  /// No description provided for @noDocumentsYet.
  ///
  /// In en, this message translates to:
  /// **'No documents yet.'**
  String get noDocumentsYet;

  /// No description provided for @notUploadedYet.
  ///
  /// In en, this message translates to:
  /// **'uploads on save'**
  String get notUploadedYet;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @scanToFill.
  ///
  /// In en, this message translates to:
  /// **'Scan to fill'**
  String get scanToFill;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Reading…'**
  String get scanning;

  /// No description provided for @scanNotRecognised.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read that document. Try a clearer photo or the PDF.'**
  String get scanNotRecognised;

  /// No description provided for @scanFailed.
  ///
  /// In en, this message translates to:
  /// **'Scanning failed. Please try again or fill the form by hand.'**
  String get scanFailed;

  /// No description provided for @scanWebNote.
  ///
  /// In en, this message translates to:
  /// **'Scanning works in the iPhone and Android apps.'**
  String get scanWebNote;

  /// No description provided for @scanHintProperty.
  ///
  /// In en, this message translates to:
  /// **'Title deed, DEWA bill, Ejari or tenancy contract'**
  String get scanHintProperty;

  /// No description provided for @scanHintTenant.
  ///
  /// In en, this message translates to:
  /// **'Emirates ID, passport, Ejari or tenancy contract'**
  String get scanHintTenant;

  /// No description provided for @scanHintAgreement.
  ///
  /// In en, this message translates to:
  /// **'Ejari certificate or tenancy contract'**
  String get scanHintAgreement;

  /// No description provided for @sectionBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic information'**
  String get sectionBasicInfo;

  /// No description provided for @sectionDewaMollak.
  ///
  /// In en, this message translates to:
  /// **'DEWA & Mollak'**
  String get sectionDewaMollak;

  /// No description provided for @sectionOwnership.
  ///
  /// In en, this message translates to:
  /// **'Ownership'**
  String get sectionOwnership;

  /// No description provided for @sectionHoa.
  ///
  /// In en, this message translates to:
  /// **'Owners association (HOA)'**
  String get sectionHoa;

  /// No description provided for @sectionMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get sectionMaintenance;

  /// No description provided for @sectionDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get sectionDocuments;

  /// No description provided for @dewaPremiseNo.
  ///
  /// In en, this message translates to:
  /// **'DEWA premise no.'**
  String get dewaPremiseNo;

  /// No description provided for @mollakRegistrationNo.
  ///
  /// In en, this message translates to:
  /// **'Mollak registration no.'**
  String get mollakRegistrationNo;

  /// No description provided for @hoaName.
  ///
  /// In en, this message translates to:
  /// **'HOA name'**
  String get hoaName;

  /// No description provided for @hoaPhone.
  ///
  /// In en, this message translates to:
  /// **'HOA contact number'**
  String get hoaPhone;

  /// No description provided for @ownerEmiratesIdNo.
  ///
  /// In en, this message translates to:
  /// **'Owner\'s Emirates ID no.'**
  String get ownerEmiratesIdNo;

  /// No description provided for @ownerPassportNo.
  ///
  /// In en, this message translates to:
  /// **'Owner\'s passport no.'**
  String get ownerPassportNo;

  /// No description provided for @annualRentLabel.
  ///
  /// In en, this message translates to:
  /// **'Annual rent'**
  String get annualRentLabel;

  /// No description provided for @depositLabel.
  ///
  /// In en, this message translates to:
  /// **'Security deposit'**
  String get depositLabel;

  /// No description provided for @aed.
  ///
  /// In en, this message translates to:
  /// **'AED'**
  String get aed;

  /// No description provided for @editProperty.
  ///
  /// In en, this message translates to:
  /// **'Edit property'**
  String get editProperty;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @propertyNameHelper.
  ///
  /// In en, this message translates to:
  /// **'For example: Marina Heights 1203'**
  String get propertyNameHelper;

  /// No description provided for @premiseHelper.
  ///
  /// In en, this message translates to:
  /// **'9 digits, on the DEWA bill'**
  String get premiseHelper;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @middleName.
  ///
  /// In en, this message translates to:
  /// **'Middle name'**
  String get middleName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @contactNo.
  ///
  /// In en, this message translates to:
  /// **'Contact no.'**
  String get contactNo;

  /// No description provided for @passportNo.
  ///
  /// In en, this message translates to:
  /// **'Passport no.'**
  String get passportNo;

  /// No description provided for @sectionPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get sectionPersonal;

  /// No description provided for @sectionContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get sectionContact;

  /// No description provided for @sectionIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get sectionIdentity;

  /// No description provided for @editTenant.
  ///
  /// In en, this message translates to:
  /// **'Edit tenant'**
  String get editTenant;

  /// No description provided for @invalidEmiratesId.
  ///
  /// In en, this message translates to:
  /// **'Use the format 784-XXXX-XXXXXXX-X'**
  String get invalidEmiratesId;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @ownIdTenantError.
  ///
  /// In en, this message translates to:
  /// **'This is your own ID. A tenant can\'t use it.'**
  String get ownIdTenantError;

  /// No description provided for @ownIdTitle.
  ///
  /// In en, this message translates to:
  /// **'This looks like your own Emirates ID'**
  String get ownIdTitle;

  /// No description provided for @ownIdBody.
  ///
  /// In en, this message translates to:
  /// **'The ID on this document matches yours, so it hasn\'t been filled in as a tenant.'**
  String get ownIdBody;

  /// No description provided for @ownIdAgreementBody.
  ///
  /// In en, this message translates to:
  /// **'The tenant on this document has your own ID, so no tenant was filled in. Choose the tenant yourself.'**
  String get ownIdAgreementBody;

  /// No description provided for @useForMyProfile.
  ///
  /// In en, this message translates to:
  /// **'Save to my profile'**
  String get useForMyProfile;

  /// No description provided for @ownIdSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to your profile.'**
  String get ownIdSaved;

  /// No description provided for @addRentAgreement.
  ///
  /// In en, this message translates to:
  /// **'Add rent agreement'**
  String get addRentAgreement;

  /// No description provided for @editRentAgreement.
  ///
  /// In en, this message translates to:
  /// **'Edit rent agreement'**
  String get editRentAgreement;

  /// No description provided for @sectionUnitTenant.
  ///
  /// In en, this message translates to:
  /// **'Unit & tenant'**
  String get sectionUnitTenant;

  /// No description provided for @sectionTermRent.
  ///
  /// In en, this message translates to:
  /// **'Term & rent'**
  String get sectionTermRent;

  /// No description provided for @sectionPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get sectionPayment;

  /// No description provided for @newTenant.
  ///
  /// In en, this message translates to:
  /// **'New tenant'**
  String get newTenant;

  /// No description provided for @addScannedTenant.
  ///
  /// In en, this message translates to:
  /// **'Add {name} as tenant'**
  String addScannedTenant(String name);

  /// No description provided for @propertyMatched.
  ///
  /// In en, this message translates to:
  /// **'Matched to {name}'**
  String propertyMatched(String name);

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @myEmiratesIdNo.
  ///
  /// In en, this message translates to:
  /// **'My Emirates ID no.'**
  String get myEmiratesIdNo;

  /// No description provided for @myPassportNo.
  ///
  /// In en, this message translates to:
  /// **'My passport no.'**
  String get myPassportNo;

  /// No description provided for @ownIdHelper.
  ///
  /// In en, this message translates to:
  /// **'Used to recognise your own documents, so you\'re never added as a tenant.'**
  String get ownIdHelper;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaved;

  /// No description provided for @tenantRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose or add a tenant'**
  String get tenantRequired;

  /// No description provided for @noTenantsYet.
  ///
  /// In en, this message translates to:
  /// **'No tenants yet. Add one to continue.'**
  String get noTenantsYet;

  /// No description provided for @scheduleNote.
  ///
  /// In en, this message translates to:
  /// **'The cheque schedule is created when you save.'**
  String get scheduleNote;

  /// No description provided for @tpSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your account'**
  String get tpSetupTitle;

  /// No description provided for @tpSetupSub.
  ///
  /// In en, this message translates to:
  /// **'A few details to get started. You can add properties right after.'**
  String get tpSetupSub;

  /// No description provided for @tpUnits.
  ///
  /// In en, this message translates to:
  /// **'Number of units'**
  String get tpUnits;

  /// No description provided for @tpUnitsHelper.
  ///
  /// In en, this message translates to:
  /// **'How many units you own or manage'**
  String get tpUnitsHelper;

  /// No description provided for @tpInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number (1 or more)'**
  String get tpInvalidNumber;

  /// No description provided for @tpRole.
  ///
  /// In en, this message translates to:
  /// **'Your role'**
  String get tpRole;

  /// No description provided for @tpRoleLandlord.
  ///
  /// In en, this message translates to:
  /// **'Landlord'**
  String get tpRoleLandlord;

  /// No description provided for @tpRolePropertyManager.
  ///
  /// In en, this message translates to:
  /// **'Property manager'**
  String get tpRolePropertyManager;

  /// No description provided for @tpRoleTenant.
  ///
  /// In en, this message translates to:
  /// **'Tenant'**
  String get tpRoleTenant;

  /// No description provided for @tpImTenant.
  ///
  /// In en, this message translates to:
  /// **'I\'m a tenant'**
  String get tpImTenant;

  /// No description provided for @tpImLandlord.
  ///
  /// In en, this message translates to:
  /// **'I\'m a landlord or property manager'**
  String get tpImLandlord;

  /// No description provided for @tpAccountType.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get tpAccountType;

  /// No description provided for @tpTenantWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to LedGix Rent'**
  String get tpTenantWelcome;

  /// No description provided for @tpTenantWelcomeSub.
  ///
  /// In en, this message translates to:
  /// **'Enter your name. If your landlord gave you an invite code, add it to see your lease, payments and documents.'**
  String get tpTenantWelcomeSub;

  /// No description provided for @tpInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get tpInviteCode;

  /// No description provided for @tpInviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'8 characters, e.g. K7MP3QXA'**
  String get tpInviteCodeHint;

  /// No description provided for @tpSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get tpSkip;

  /// No description provided for @tpCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code isn\'t valid. Check it and try again.'**
  String get tpCodeInvalid;

  /// No description provided for @tpCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'That code has expired. Ask your landlord for a new one.'**
  String get tpCodeExpired;

  /// No description provided for @tpCodeUsed.
  ///
  /// In en, this message translates to:
  /// **'That code has already been used. Ask your landlord for a new one.'**
  String get tpCodeUsed;

  /// No description provided for @tpCodeOwn.
  ///
  /// In en, this message translates to:
  /// **'That\'s an invite code you created. Share it with your tenant instead.'**
  String get tpCodeOwn;

  /// No description provided for @tpCodeAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'This tenant record is already linked to another account.'**
  String get tpCodeAlreadyLinked;

  /// No description provided for @tpLandlordAdded.
  ///
  /// In en, this message translates to:
  /// **'Landlord added.'**
  String get tpLandlordAdded;

  /// No description provided for @tpInviteToApp.
  ///
  /// In en, this message translates to:
  /// **'Invite to app'**
  String get tpInviteToApp;

  /// No description provided for @tpInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite {name} to LedGix Rent'**
  String tpInviteTitle(String name);

  /// No description provided for @tpInviteBody.
  ///
  /// In en, this message translates to:
  /// **'Share this code with your tenant. They enter it in the LedGix Rent app to see their lease, payments and the documents you share. It expires on {date}.'**
  String tpInviteBody(String date);

  /// No description provided for @tpCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get tpCopyCode;

  /// No description provided for @tpShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get tpShare;

  /// No description provided for @tpCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get tpCodeCopied;

  /// No description provided for @tpInviteShareText.
  ///
  /// In en, this message translates to:
  /// **'Join me on LedGix Rent to see your lease, payments and documents. Your invite code: {code}. Open https://rent.getledgix.com/app/ to sign up as a tenant.'**
  String tpInviteShareText(String code);

  /// No description provided for @tpNewCode.
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get tpNewCode;

  /// No description provided for @tpNotInvited.
  ///
  /// In en, this message translates to:
  /// **'Not invited'**
  String get tpNotInvited;

  /// No description provided for @tpInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get tpInvited;

  /// No description provided for @tpJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined the app'**
  String get tpJoined;

  /// No description provided for @tpLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get tpLater;

  /// No description provided for @tpShareWithTenant.
  ///
  /// In en, this message translates to:
  /// **'Share with tenant'**
  String get tpShareWithTenant;

  /// No description provided for @tpSharedWithTenant.
  ///
  /// In en, this message translates to:
  /// **'Shared with tenant'**
  String get tpSharedWithTenant;

  /// No description provided for @tpShareChequeCopy.
  ///
  /// In en, this message translates to:
  /// **'Cheque copy shared with tenant'**
  String get tpShareChequeCopy;

  /// No description provided for @tpHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tpHome;

  /// No description provided for @tpLandlords.
  ///
  /// In en, this message translates to:
  /// **'Landlords'**
  String get tpLandlords;

  /// No description provided for @tpPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get tpPayments;

  /// No description provided for @tpInspections.
  ///
  /// In en, this message translates to:
  /// **'Inspections'**
  String get tpInspections;

  /// No description provided for @tpManageLandlords.
  ///
  /// In en, this message translates to:
  /// **'Manage landlords'**
  String get tpManageLandlords;

  /// No description provided for @tpAddLandlord.
  ///
  /// In en, this message translates to:
  /// **'Add landlord'**
  String get tpAddLandlord;

  /// No description provided for @tpAddLandlordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the invite code your landlord shared with you.'**
  String get tpAddLandlordHint;

  /// No description provided for @tpCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get tpCurrent;

  /// No description provided for @tpFormer.
  ///
  /// In en, this message translates to:
  /// **'Former'**
  String get tpFormer;

  /// No description provided for @tpRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get tpRemove;

  /// No description provided for @tpRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String tpRemoveTitle(String name);

  /// No description provided for @tpRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Your past lease with this landlord will no longer show in your app. They can add you again with a new code.'**
  String get tpRemoveBody;

  /// No description provided for @tpNoLandlords.
  ///
  /// In en, this message translates to:
  /// **'No landlords yet. Ask your landlord for an invite code.'**
  String get tpNoLandlords;

  /// No description provided for @tpLandlordDetails.
  ///
  /// In en, this message translates to:
  /// **'Landlord details'**
  String get tpLandlordDetails;

  /// No description provided for @tpAgreement.
  ///
  /// In en, this message translates to:
  /// **'Agreement'**
  String get tpAgreement;

  /// No description provided for @tpSharedDocuments.
  ///
  /// In en, this message translates to:
  /// **'Shared documents'**
  String get tpSharedDocuments;

  /// No description provided for @tpNoSharedDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents shared yet.'**
  String get tpNoSharedDocuments;

  /// No description provided for @tpOpenDocument.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get tpOpenDocument;

  /// No description provided for @tpNextPayment.
  ///
  /// In en, this message translates to:
  /// **'Next payment'**
  String get tpNextPayment;

  /// No description provided for @tpNoUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming payments.'**
  String get tpNoUpcoming;

  /// No description provided for @tpYourLeases.
  ///
  /// In en, this message translates to:
  /// **'Your leases'**
  String get tpYourLeases;

  /// No description provided for @tpLeaseWith.
  ///
  /// In en, this message translates to:
  /// **'with {name}'**
  String tpLeaseWith(String name);

  /// No description provided for @tpRecentDocuments.
  ///
  /// In en, this message translates to:
  /// **'Recent documents'**
  String get tpRecentDocuments;

  /// No description provided for @tpChequeCopy.
  ///
  /// In en, this message translates to:
  /// **'Cheque copy'**
  String get tpChequeCopy;

  /// No description provided for @tpViewChequeCopy.
  ///
  /// In en, this message translates to:
  /// **'View cheque copy'**
  String get tpViewChequeCopy;

  /// No description provided for @tpNewRequest.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get tpNewRequest;

  /// No description provided for @tpRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent to your landlord.'**
  String get tpRequestSent;

  /// No description provided for @tpRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'What needs fixing?'**
  String get tpRequestTitle;

  /// No description provided for @tpRequestDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get tpRequestDetails;

  /// No description provided for @tpAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get tpAddPhotos;

  /// No description provided for @tpPhotosAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} photo(s) added'**
  String tpPhotosAdded(int count);

  /// No description provided for @tpMyRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests are tracked by your landlord. You\'ll get updates when they act on them.'**
  String get tpMyRequests;

  /// No description provided for @tpNoInspections.
  ///
  /// In en, this message translates to:
  /// **'No inspections yet.'**
  String get tpNoInspections;

  /// No description provided for @tpMoveIn.
  ///
  /// In en, this message translates to:
  /// **'Move-in inspection'**
  String get tpMoveIn;

  /// No description provided for @tpMoveOut.
  ///
  /// In en, this message translates to:
  /// **'Move-out inspection'**
  String get tpMoveOut;

  /// No description provided for @tpInspection.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get tpInspection;

  /// No description provided for @tpEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get tpEnded;

  /// No description provided for @tpActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get tpActive;

  /// No description provided for @tpPropertyDetails.
  ///
  /// In en, this message translates to:
  /// **'Property details'**
  String get tpPropertyDetails;

  /// No description provided for @tpNoProperties.
  ///
  /// In en, this message translates to:
  /// **'No properties yet. They appear once your landlord adds your rent agreement.'**
  String get tpNoProperties;

  /// No description provided for @tpRentReminders.
  ///
  /// In en, this message translates to:
  /// **'Rent reminders 7, 3 and 1 days before each payment, and on the due day'**
  String get tpRentReminders;

  /// No description provided for @tpRenewalReminders.
  ///
  /// In en, this message translates to:
  /// **'Lease end reminders 60 and 30 days before'**
  String get tpRenewalReminders;

  /// No description provided for @tpBounced.
  ///
  /// In en, this message translates to:
  /// **'Alerts if a cheque bounces or is put on hold'**
  String get tpBounced;

  /// No description provided for @tpLeasePeriod.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String tpLeasePeriod(String start, String end);

  /// No description provided for @tpChoosePropertyFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a property'**
  String get tpChoosePropertyFirst;

  /// No description provided for @tpSince.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String tpSince(String date);

  /// No description provided for @inspections.
  ///
  /// In en, this message translates to:
  /// **'Inspections'**
  String get inspections;

  /// No description provided for @moveInInspection.
  ///
  /// In en, this message translates to:
  /// **'Move-in inspection'**
  String get moveInInspection;

  /// No description provided for @moveOutInspection.
  ///
  /// In en, this message translates to:
  /// **'Move-out inspection'**
  String get moveOutInspection;

  /// No description provided for @newInspection.
  ///
  /// In en, this message translates to:
  /// **'New inspection'**
  String get newInspection;

  /// No description provided for @inspectionStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get inspectionStatusDraft;

  /// No description provided for @inspectionStatusAwaitingTenant.
  ///
  /// In en, this message translates to:
  /// **'Waiting for tenant'**
  String get inspectionStatusAwaitingTenant;

  /// No description provided for @inspectionStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get inspectionStatusCompleted;

  /// No description provided for @conditionExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get conditionExcellent;

  /// No description provided for @conditionGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get conditionGood;

  /// No description provided for @conditionFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get conditionFair;

  /// No description provided for @conditionPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get conditionPoor;

  /// No description provided for @conditionDamaged.
  ///
  /// In en, this message translates to:
  /// **'Damaged'**
  String get conditionDamaged;

  /// No description provided for @conditionMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get conditionMissing;

  /// No description provided for @conditionNa.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get conditionNa;

  /// No description provided for @inspectionRooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get inspectionRooms;

  /// No description provided for @addRoom.
  ///
  /// In en, this message translates to:
  /// **'Add room'**
  String get addRoom;

  /// No description provided for @renameRoom.
  ///
  /// In en, this message translates to:
  /// **'Rename room'**
  String get renameRoom;

  /// No description provided for @deleteRoom.
  ///
  /// In en, this message translates to:
  /// **'Delete room'**
  String get deleteRoom;

  /// No description provided for @roomNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Room name'**
  String get roomNameLabel;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @itemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get itemNameLabel;

  /// No description provided for @renameItem.
  ///
  /// In en, this message translates to:
  /// **'Rename item'**
  String get renameItem;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get deleteItem;

  /// No description provided for @itemsRated.
  ///
  /// In en, this message translates to:
  /// **'{rated} of {total} rated'**
  String itemsRated(int rated, int total);

  /// No description provided for @metersAndKeys.
  ///
  /// In en, this message translates to:
  /// **'Meters & keys'**
  String get metersAndKeys;

  /// No description provided for @meterReadings.
  ///
  /// In en, this message translates to:
  /// **'Meter readings'**
  String get meterReadings;

  /// No description provided for @meterElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity meter'**
  String get meterElectricity;

  /// No description provided for @meterWater.
  ///
  /// In en, this message translates to:
  /// **'Water meter'**
  String get meterWater;

  /// No description provided for @meterGas.
  ///
  /// In en, this message translates to:
  /// **'Gas meter'**
  String get meterGas;

  /// No description provided for @meterPhotos.
  ///
  /// In en, this message translates to:
  /// **'Meter photos'**
  String get meterPhotos;

  /// No description provided for @keysHandedOver.
  ///
  /// In en, this message translates to:
  /// **'Keys handed over'**
  String get keysHandedOver;

  /// No description provided for @keysMainDoor.
  ///
  /// In en, this message translates to:
  /// **'Main door keys'**
  String get keysMainDoor;

  /// No description provided for @keysMailbox.
  ///
  /// In en, this message translates to:
  /// **'Mailbox keys'**
  String get keysMailbox;

  /// No description provided for @keysParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get keysParking;

  /// No description provided for @keysAccessCards.
  ///
  /// In en, this message translates to:
  /// **'Access cards'**
  String get keysAccessCards;

  /// No description provided for @keysRemotes.
  ///
  /// In en, this message translates to:
  /// **'Remotes'**
  String get keysRemotes;

  /// No description provided for @keysOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get keysOther;

  /// No description provided for @generalNotes.
  ///
  /// In en, this message translates to:
  /// **'General notes'**
  String get generalNotes;

  /// No description provided for @roomNotes.
  ///
  /// In en, this message translates to:
  /// **'Room notes'**
  String get roomNotes;

  /// No description provided for @roomPhotos.
  ///
  /// In en, this message translates to:
  /// **'Room photos & videos'**
  String get roomPhotos;

  /// No description provided for @recordVideo.
  ///
  /// In en, this message translates to:
  /// **'Record video'**
  String get recordVideo;

  /// No description provided for @fromGallery.
  ///
  /// In en, this message translates to:
  /// **'From gallery'**
  String get fromGallery;

  /// No description provided for @uploadingMedia.
  ///
  /// In en, this message translates to:
  /// **'Uploading {count}…'**
  String uploadingMedia(int count);

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String uploadFailed(String error);

  /// No description provided for @reviewAndSend.
  ///
  /// In en, this message translates to:
  /// **'Review & send'**
  String get reviewAndSend;

  /// No description provided for @sendToTenant.
  ///
  /// In en, this message translates to:
  /// **'Send to tenant'**
  String get sendToTenant;

  /// No description provided for @sendToTenantHint.
  ///
  /// In en, this message translates to:
  /// **'The tenant can review it, add comments and photos, and confirm in their app.'**
  String get sendToTenantHint;

  /// No description provided for @inspectionSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to the tenant.'**
  String get inspectionSent;

  /// No description provided for @markCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as completed'**
  String get markCompleted;

  /// No description provided for @markCompletedHint.
  ///
  /// In en, this message translates to:
  /// **'Use this when the tenant isn\'t on the app, e.g. \"Signed on paper on 12/11\".'**
  String get markCompletedHint;

  /// No description provided for @completionNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get completionNoteLabel;

  /// No description provided for @downloadReport.
  ///
  /// In en, this message translates to:
  /// **'PDF report'**
  String get downloadReport;

  /// No description provided for @moveInVsMoveOut.
  ///
  /// In en, this message translates to:
  /// **'Move-in vs move-out'**
  String get moveInVsMoveOut;

  /// No description provided for @atMoveIn.
  ///
  /// In en, this message translates to:
  /// **'Move-in'**
  String get atMoveIn;

  /// No description provided for @atMoveOut.
  ///
  /// In en, this message translates to:
  /// **'Move-out'**
  String get atMoveOut;

  /// No description provided for @worsenedItems.
  ///
  /// In en, this message translates to:
  /// **'Items in worse condition'**
  String get worsenedItems;

  /// No description provided for @noWorsenedItems.
  ///
  /// In en, this message translates to:
  /// **'No item is in worse condition than at move-in.'**
  String get noWorsenedItems;

  /// No description provided for @worsenedHint.
  ///
  /// In en, this message translates to:
  /// **'Use this list when agreeing deposit deductions.'**
  String get worsenedHint;

  /// No description provided for @tenantComments.
  ///
  /// In en, this message translates to:
  /// **'Tenant\'s comments'**
  String get tenantComments;

  /// No description provided for @tenantMedia.
  ///
  /// In en, this message translates to:
  /// **'Tenant\'s photos & videos'**
  String get tenantMedia;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add comment'**
  String get addComment;

  /// No description provided for @commentLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get commentLabel;

  /// No description provided for @addPhotoOrVideo.
  ///
  /// In en, this message translates to:
  /// **'Add photo or video'**
  String get addPhotoOrVideo;

  /// No description provided for @confirmInspection.
  ///
  /// In en, this message translates to:
  /// **'Confirm inspection'**
  String get confirmInspection;

  /// No description provided for @confirmInspectionBody.
  ///
  /// In en, this message translates to:
  /// **'Confirm that this inspection matches the unit\'s condition. Add comments first if anything is wrong.'**
  String get confirmInspectionBody;

  /// No description provided for @inspectionConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Inspection confirmed.'**
  String get inspectionConfirmed;

  /// No description provided for @landlordSigned.
  ///
  /// In en, this message translates to:
  /// **'Landlord signed'**
  String get landlordSigned;

  /// No description provided for @tenantConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Tenant confirmed'**
  String get tenantConfirmed;

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// No description provided for @completedWithoutTenant.
  ///
  /// In en, this message translates to:
  /// **'Completed without tenant confirmation'**
  String get completedWithoutTenant;

  /// No description provided for @bedroomsLabel.
  ///
  /// In en, this message translates to:
  /// **'Bedrooms'**
  String get bedroomsLabel;

  /// No description provided for @bathroomsLabel.
  ///
  /// In en, this message translates to:
  /// **'Bathrooms'**
  String get bathroomsLabel;

  /// No description provided for @roomsToInclude.
  ///
  /// In en, this message translates to:
  /// **'Rooms to include'**
  String get roomsToInclude;

  /// No description provided for @rentAgreementLabel.
  ///
  /// In en, this message translates to:
  /// **'Rent agreement'**
  String get rentAgreementLabel;

  /// No description provided for @inspectionTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get inspectionTypeLabel;

  /// No description provided for @startInspection.
  ///
  /// In en, this message translates to:
  /// **'Start inspection'**
  String get startInspection;

  /// No description provided for @continueInspection.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueInspection;

  /// No description provided for @viewInspection.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewInspection;

  /// No description provided for @deleteInspection.
  ///
  /// In en, this message translates to:
  /// **'Delete inspection'**
  String get deleteInspection;

  /// No description provided for @deleteInspectionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this inspection and its notes? Uploaded photos stay in storage until the account is deleted.'**
  String get deleteInspectionConfirm;

  /// No description provided for @unratedItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items aren\'t rated yet. Send anyway?'**
  String unratedItems(int count);

  /// No description provided for @prefilledFromMoveIn.
  ///
  /// In en, this message translates to:
  /// **'Rooms copied from the move-in inspection. The move-in condition shows on each item.'**
  String get prefilledFromMoveIn;

  /// No description provided for @noInspectionsYet.
  ///
  /// In en, this message translates to:
  /// **'No inspections yet. Start one from a rent agreement.'**
  String get noInspectionsYet;

  /// No description provided for @noAgreementsForInspection.
  ///
  /// In en, this message translates to:
  /// **'Add a rent agreement first.'**
  String get noAgreementsForInspection;

  /// No description provided for @inspectionCreated.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String inspectionCreated(String date);

  /// No description provided for @photosOmitted.
  ///
  /// In en, this message translates to:
  /// **'{count} more photos in the app'**
  String photosOmitted(int count);

  /// No description provided for @videosLabel.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videosLabel;

  /// No description provided for @itemLabel.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get itemLabel;

  /// No description provided for @conditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get conditionLabel;

  /// No description provided for @inspectionStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get inspectionStatusLabel;

  /// No description provided for @createdLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdLabel;

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// No description provided for @confirmationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirmations'**
  String get confirmationsLabel;

  /// No description provided for @worsenedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} worse'**
  String worsenedCount(int count);

  /// No description provided for @hrPaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Payment details'**
  String get hrPaymentDetails;

  /// No description provided for @hrRequestHold.
  ///
  /// In en, this message translates to:
  /// **'Request to hold'**
  String get hrRequestHold;

  /// No description provided for @hrRequestHoldSub.
  ///
  /// In en, this message translates to:
  /// **'Ask your landlord to hold this payment until a later date.'**
  String get hrRequestHoldSub;

  /// No description provided for @hrNewDate.
  ///
  /// In en, this message translates to:
  /// **'New date *'**
  String get hrNewDate;

  /// No description provided for @hrPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get hrPickDate;

  /// No description provided for @hrReason.
  ///
  /// In en, this message translates to:
  /// **'Reason *'**
  String get hrReason;

  /// No description provided for @hrReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. salary is paid later this month'**
  String get hrReasonHint;

  /// No description provided for @hrNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get hrNote;

  /// No description provided for @hrSend.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get hrSend;

  /// No description provided for @hrSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent to your landlord.'**
  String get hrSent;

  /// No description provided for @hrStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Hold requested · waiting for your landlord'**
  String get hrStatusPending;

  /// No description provided for @hrStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Hold approved · new date {date}'**
  String hrStatusApproved(String date);

  /// No description provided for @hrStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Hold request declined'**
  String get hrStatusDeclined;

  /// No description provided for @hrLandlordResponse.
  ///
  /// In en, this message translates to:
  /// **'Landlord\'s response'**
  String get hrLandlordResponse;

  /// No description provided for @hrYourReason.
  ///
  /// In en, this message translates to:
  /// **'Your reason'**
  String get hrYourReason;

  /// No description provided for @hrErrReason.
  ///
  /// In en, this message translates to:
  /// **'Please give a reason.'**
  String get hrErrReason;

  /// No description provided for @hrErrDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date after the due date.'**
  String get hrErrDate;

  /// No description provided for @hrErrTooFar.
  ///
  /// In en, this message translates to:
  /// **'Pick a date within {days} days of the due date.'**
  String hrErrTooFar(int days);

  /// No description provided for @hrErrOpen.
  ///
  /// In en, this message translates to:
  /// **'There\'s already a request for this payment.'**
  String get hrErrOpen;

  /// No description provided for @hrErrNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This payment can\'t be put on hold.'**
  String get hrErrNotAllowed;

  /// No description provided for @hrTapForDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap a payment for details or to request a hold.'**
  String get hrTapForDetails;

  /// No description provided for @hrFromTenant.
  ///
  /// In en, this message translates to:
  /// **'From tenant app'**
  String get hrFromTenant;

  /// No description provided for @hrDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get hrDecline;

  /// No description provided for @hrDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline hold request'**
  String get hrDeclineTitle;

  /// No description provided for @hrResponse.
  ///
  /// In en, this message translates to:
  /// **'Response to the tenant'**
  String get hrResponse;

  /// No description provided for @hrResponseHint.
  ///
  /// In en, this message translates to:
  /// **'Short reason, e.g. the cheque must be deposited on time'**
  String get hrResponseHint;

  /// No description provided for @hrPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pending} other{{count} pending}}'**
  String hrPendingCount(int count);

  /// No description provided for @hrNonePending.
  ///
  /// In en, this message translates to:
  /// **'No pending hold requests.'**
  String get hrNonePending;

  /// No description provided for @hrMoveTo.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String hrMoveTo(String from, String to);

  /// No description provided for @hrNotif.
  ///
  /// In en, this message translates to:
  /// **'Hold request · {amount}'**
  String hrNotif(String amount);

  /// No description provided for @hrApproved.
  ///
  /// In en, this message translates to:
  /// **'Hold approved. The due date has moved.'**
  String get hrApproved;

  /// No description provided for @hrDeclined.
  ///
  /// In en, this message translates to:
  /// **'Hold request declined.'**
  String get hrDeclined;

  /// No description provided for @ixAddOtherDocument.
  ///
  /// In en, this message translates to:
  /// **'Add other document'**
  String get ixAddOtherDocument;

  /// No description provided for @ixAndMore.
  ///
  /// In en, this message translates to:
  /// **'and {count} more'**
  String ixAndMore(int count);

  /// No description provided for @ixClearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get ixClearDate;

  /// No description provided for @ixDocumentName.
  ///
  /// In en, this message translates to:
  /// **'Document name'**
  String get ixDocumentName;

  /// No description provided for @ixEmiratesId.
  ///
  /// In en, this message translates to:
  /// **'Emirates ID'**
  String get ixEmiratesId;

  /// No description provided for @ixEmiratesIdExpiry.
  ///
  /// In en, this message translates to:
  /// **'Emirates ID expiry'**
  String get ixEmiratesIdExpiry;

  /// No description provided for @ixExpiredOn.
  ///
  /// In en, this message translates to:
  /// **'Expired {date}'**
  String ixExpiredOn(String date);

  /// No description provided for @ixExpiresInDays.
  ///
  /// In en, this message translates to:
  /// **'Expires {date} (in {days} days)'**
  String ixExpiresInDays(String date, int days);

  /// No description provided for @ixExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String ixExpiresOn(String date);

  /// No description provided for @ixExpiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get ixExpiresToday;

  /// No description provided for @ixExpiryAlreadyPassed.
  ///
  /// In en, this message translates to:
  /// **'This date has passed: the ID has expired'**
  String get ixExpiryAlreadyPassed;

  /// No description provided for @ixExpiryNotSet.
  ///
  /// In en, this message translates to:
  /// **'Expiry date not set'**
  String get ixExpiryNotSet;

  /// No description provided for @ixIdExpired.
  ///
  /// In en, this message translates to:
  /// **'ID expired'**
  String get ixIdExpired;

  /// No description provided for @ixIdExpiriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{expired} expired · {soon} expiring within 60 days'**
  String ixIdExpiriesSubtitle(int expired, int soon);

  /// No description provided for @ixIdExpiriesTitle.
  ///
  /// In en, this message translates to:
  /// **'ID expiries'**
  String get ixIdExpiriesTitle;

  /// No description provided for @ixIdExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'ID expiring'**
  String get ixIdExpiringSoon;

  /// No description provided for @ixMyEmiratesIdExpiry.
  ///
  /// In en, this message translates to:
  /// **'My Emirates ID expiry'**
  String get ixMyEmiratesIdExpiry;

  /// No description provided for @ixMyPassportExpiry.
  ///
  /// In en, this message translates to:
  /// **'My passport expiry'**
  String get ixMyPassportExpiry;

  /// No description provided for @ixNoOtherDocuments.
  ///
  /// In en, this message translates to:
  /// **'No other documents yet.'**
  String get ixNoOtherDocuments;

  /// No description provided for @ixNotAttached.
  ///
  /// In en, this message translates to:
  /// **'Not attached'**
  String get ixNotAttached;

  /// No description provided for @ixOtherDocuments.
  ///
  /// In en, this message translates to:
  /// **'Other documents'**
  String get ixOtherDocuments;

  /// No description provided for @ixOwnerEmiratesIdExpiry.
  ///
  /// In en, this message translates to:
  /// **'Owner\'s Emirates ID expiry'**
  String get ixOwnerEmiratesIdExpiry;

  /// No description provided for @ixOwnerOfProperty.
  ///
  /// In en, this message translates to:
  /// **'Owner · {property}'**
  String ixOwnerOfProperty(String property);

  /// No description provided for @ixOwnerPassportExpiry.
  ///
  /// In en, this message translates to:
  /// **'Owner\'s passport expiry'**
  String get ixOwnerPassportExpiry;

  /// No description provided for @ixPassport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get ixPassport;

  /// No description provided for @ixPassportExpiry.
  ///
  /// In en, this message translates to:
  /// **'Passport expiry'**
  String get ixPassportExpiry;

  /// No description provided for @ixReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get ixReplace;

  /// No description provided for @ixUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get ixUpload;

  /// No description provided for @ixYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get ixYou;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
