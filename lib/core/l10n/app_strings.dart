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
/// navigation and the profile screen are translated. Ritual/ceremony content
/// (`ceremony_lore.dart`) and the long purohit registration form are still
/// English and are tracked as follow-up work.
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
}
