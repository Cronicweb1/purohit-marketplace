import 'app_locale.dart';
import 'strings_en.dart';
import 'strings_hi.dart';

/// Every user-facing string on the translated surfaces.
///
/// This is an abstract class rather than a map or a generated ARB bundle for
/// one reason: the compiler enforces completeness. Adding a getter here breaks
/// the build until *every* language implements it, so a half-translated release
/// cannot ship and no screen can ever render a blank or a raw key. The cost is
/// that adding a language means writing one file; the benefit is that adding a
/// string means you cannot forget to.
///
/// Scope note: the landing page, role gate, all sign-in screens, the bottom
/// navigation, the profile screen, the jobs feed, the ceremony detail screen
/// and My work are translated. Ritual/ceremony content (`ceremony_lore.dart`)
/// and the long purohit registration form are still English and are tracked
/// as follow-up work. Ritual names themselves come from the `rituals` table
/// and stay transliterated Sanskrit in every language.
abstract class AppStrings {
  const AppStrings();

  static AppStrings of(AppLocale locale) => switch (locale) {
        AppLocale.en => const AppStringsEn(),
        AppLocale.hi => const AppStringsHi(),
      };

  // ---------------------------------------------------------------- language
  String get languageTitle;
  String get languageSubtitle;
  String get languageChangeCta;

  // -------------------------------------------------------------- navigation
  String get navBrowse;
  String get navFindWork;
  String get navMyJobs;
  String get navApplications;
  String get navPost;
  String get navMessages;
  String get navProfile;

  // ----------------------------------------------------------------- landing
  String get brand;
  List<String> get heroLines;
  String get scrollHint;
  String get landingForFamilies;
  String get landingForPurohits;
  String get landingFamilyHeadline;
  String get landingPurohitHeadline;

  String get stepTellRitualTitle;
  String get stepTellRitualBody;
  String get stepCompareTitle;
  String get stepCompareBody;
  String get stepTalkTitle;
  String get stepTalkBody;

  String get stepRegisterTitle;
  String get stepRegisterBody;
  String get stepRequestsTitle;
  String get stepRequestsBody;
  String get stepApplyTitle;
  String get stepApplyBody;

  String get trustVerifiedTitle;
  String get trustVerifiedBody;
  String get trustLanguageTitle;
  String get trustLanguageBody;
  String get trustDakshinaTitle;
  String get trustDakshinaBody;
  String get trustReachTitle;
  String get trustReachBody;

  String get aboutEyebrow;
  String get aboutHeadline;
  String get aboutBody;

  String get assuranceHeadline;
  String get assuranceDocuments;
  String get assuranceReviews;
  String get assuranceOneEmail;

  String get whichSideTitle;
  String get whichSideBody;
  String get justBrowsing;
  String get startAsUser;
  String get startAsPurohit;
  String get roleUser;
  String get rolePurohit;

  // --------------------------------------------------------------- role gate
  String get gateForPurohits;
  String get gateForFamilies;
  String get gatePurohitHeadline;
  String get gateFamilyHeadline;
  String get gatePurohitBody;
  String get gateFamilyBody;
  String get createAccount;
  String get alreadyHaveAccount;

  /// [otherSide] is the *opposite* role, already localised.
  String oneEmailNotice(String otherSide);
  String get sideFamily;
  String get sidePurohit;

  // ------------------------------------------------------------------ sign in
  String get purohitLogin;
  String get login;
  String get welcomeBackPanditji;
  String get welcomeBack;
  String get signInSubtitlePurohit;
  String get signInSubtitleFamily;
  String get email;
  String get password;
  String get enterYourEmail;
  String get enterYourPassword;
  String get signIn;
  String get createAccountInstead;
  String get adminSignIn;
  String get back;

  String get errNotConfigured;
  String get errSignInFailed;
  String get errWrongCredentials;
  String get errRegisteredAsPurohit;
  String get errRegisteredAsFamily;

  // ------------------------------------------------------------------ profile
  String get profile;
  String get guest;
  String get labelEmail;
  String get labelCity;
  String get labelDateOfBirth;
  String get labelExperience;
  String yearsCount(int years);
  String get about;
  String get workPhotos;
  String get workPhotosHint;
  String get registerAsPurohit;
  String get editPurohitDetails;
  String get verificationConsole;
  String get signOut;
  String get earlyBuild;

  String get verificationPendingBody;
  String get verificationApprovedBody;
  String get verificationRejectedBody;

  // ---- Admin console sign-in -------------------------------------------
  // The admin surface is small but it is the one screen a reviewer sees
  // before anything else, so it gets the same treatment as the public pages.
  String get adminConsoleBlurb;
  String get adminEmailLabel;
  String get emailHintExample;
  String get showPassword;
  String get hidePassword;
  String get adminSignInCta;
  String get adminVerifyCta;
  String get adminSendCode;
  String get adminUseDifferentEmail;
  String get adminUsePasswordInstead;
  String get adminUseCodeInstead;
  String get adminBackToNormalSignIn;
  String get errNotAdmin;
  String get errInvalidEmail;
  String get errEnterPassword;
  String get errEnterCode;
  String errCodeFailed(String detail);

  // ---- Jobs: feed, card, detail, my work ---------------------------------
  // Everything a purohit reads while deciding whether to bid, plus the
  // family-side applicant review. These are the highest-traffic screens in
  // the app, so they are translated even though the copy is long.
  String get findWork;
  String get searchCeremoniesHint;
  String get clearSearch;
  String get clearFilters;
  String get clearAction;
  String openJobsCount(int count);
  String get feedAwaitingVerificationBody;
  String get noOpenJobsMatch;
  String get nothingToShowYet;
  String get noOpenJobsMatchBody;
  String get feedLockedBody;

  String get urgent;
  String postedAgo(String ago);

  String get ceremony;
  String get notVisibleToYou;
  String get notVisibleToYouBody;
  String get budget;
  String get dateLabel;
  String get locationLabel;
  String get urgencyLabel;
  String get detailsLabel;
  String get applicationsLabel;
  String get noApplicantsYet;
  String couldNotOpenChat(String detail);
  String get thisPurohit;
  String get confirmPurohitTitle;
  String confirmPurohitBody(String name);
  String get cancelAction;
  String get confirmAction;
  String purohitConfirmed(String name);
  String couldNotConfirm(String detail);
  String get purohitFallbackName;
  String yearsShort(int years);
  String get noAmountQuoted;
  String quotedAmount(String amount);
  String get messageAction;
  String get selectAction;
  String get applicationSent;
  String get ctaVerificationPending;
  String get ctaClosed;
  String get ctaApplied;
  String get ctaApply;
  String get sendYourQuote;
  String get yourFeeLabel;
  String get feeHintExample;
  String get messageToFamily;
  String get messageToFamilyHint;
  String get sendApplication;

  String get myApplications;
  String get myCeremonies;
  String get nothingPostedYet;
  String get nothingPostedYetBody;
  String get noApplicationsYet;
  String get noApplicationsYetBody;
  String ceremonyNumber(int id);
  String youQuoted(String amount);
  String sentAgo(String ago);
  String get selectedContactUnlocked;

  // ---- Enum labels -------------------------------------------------------
  // The models keep an English `.label` for logs and debugging; the widget
  // layer renders these instead. See `enum_labels.dart`.
  String get urgencyFlexible;
  String get urgencyScheduled;
  String get urgencyImmediate;
  String get jobStatusOpen;
  String get jobStatusAssigned;
  String get jobStatusCompleted;
  String get jobStatusCancelled;
  String get appStatusApplied;
  String get appStatusShortlisted;
  String get appStatusSelected;
  String get appStatusRejected;
  String get appStatusWithdrawn;

  // ---- Money, dates, relative time --------------------------------------
  // Consumed by `core/format.dart`, which takes an optional AppStrings and
  // falls back to English so the pure-function tests keep working.
  String get notSpecified;
  String get openToQuotes;
  String get justNow;
  String minutesAgo(int n);
  String hoursAgo(int n);
  String daysAgo(int n);
  String monthsAgo(int n);
  String yearsAgo(int n);
  String get datePassed;
  String get todayLabel;
  String get tomorrowLabel;
  String inDaysLabel(int days);
}
