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
  /// **'Leases'**
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
  /// **'Add lease'**
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

  /// No description provided for @profileComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Profile editing is coming soon.'**
  String get profileComingSoon;

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
