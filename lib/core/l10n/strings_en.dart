import 'app_strings.dart';

/// English copy. This is the reference table: it reproduces the wording that
/// was hardcoded in the widgets before i18n existed, so switching to English
/// renders exactly the screens that shipped previously.
class AppStringsEn extends AppStrings {
  const AppStringsEn();

  @override
  String get languageTitle => 'Language';
  @override
  String get languageSubtitle => 'Choose the language for the app.';
  @override
  String get languageChangeCta => 'Change language';

  @override
  String get navBrowse => 'Browse';
  @override
  String get navFindWork => 'Find work';
  @override
  String get navMyJobs => 'My jobs';
  @override
  String get navApplications => 'Applications';
  @override
  String get navPost => 'Post';
  @override
  String get navMessages => 'Messages';
  @override
  String get navProfile => 'Profile';

  @override
  String get brand => 'Purohit';

  @override
  List<String> get heroLines => const [
        'Book a pandit the way you book anything else worth doing well.',
        'Every ritual deserves someone who knows why it is done.',
        'Muhurat, mantra, samagri — sorted before the guests arrive.',
        'Your family traditions, in hands that have held them before.',
      ];

  @override
  String get scrollHint => 'Scroll to see how it works';
  @override
  String get landingForFamilies => 'For families';
  @override
  String get landingForPurohits => 'For purohits';
  @override
  String get landingFamilyHeadline => 'Find the right purohit,\nnot just any purohit';
  @override
  String get landingPurohitHeadline => 'Your knowledge,\nfinally easy to find';

  @override
  String get stepTellRitualTitle => 'Tell us the ritual';
  @override
  String get stepTellRitualBody =>
      'Griha pravesh, satyanarayan katha, naamkaran, shraddh — pick the '
      'ceremony and the date you have in mind, along with your city.';
  @override
  String get stepCompareTitle => 'Compare verified purohits';
  @override
  String get stepCompareBody =>
      'See experience, languages spoken, the traditions they follow and what '
      'they charge. Every listed purohit has cleared our verification.';
  @override
  String get stepTalkTitle => 'Talk, then confirm';
  @override
  String get stepTalkBody =>
      'Message them about samagri, muhurat and how long the puja runs. '
      'Confirm only once it feels right.';

  @override
  String get stepRegisterTitle => 'Register and get verified';
  @override
  String get stepRegisterBody =>
      'Share your experience, your guru parampara and your documents once. '
      'Verification is what earns a family trust before you ever meet them.';
  @override
  String get stepRequestsTitle => 'See real requests near you';
  @override
  String get stepRequestsBody =>
      'Families post the ritual, the date and the place. Set your travel '
      'radius and only see what you can actually reach.';
  @override
  String get stepApplyTitle => 'Apply on your terms';
  @override
  String get stepApplyBody =>
      'Quote your dakshina, answer questions in chat and take only the work '
      'that suits your calendar.';

  @override
  String get trustVerifiedTitle => 'Verified, not just listed';
  @override
  String get trustVerifiedBody =>
      'Every purohit submits documents and guru references before a single '
      'family can see them. Nobody appears on the app unreviewed.';
  @override
  String get trustLanguageTitle => 'Your language, your parampara';
  @override
  String get trustLanguageBody =>
      'Filter by the languages a purohit speaks and the traditions they '
      'perform, so the ceremony sounds the way it does at home.';
  @override
  String get trustDakshinaTitle => 'Dakshina agreed upfront';
  @override
  String get trustDakshinaBody =>
      'Fees are stated before you book and discussed in chat. No awkward '
      'conversation on the morning of the puja.';
  @override
  String get trustReachTitle => 'Purohits who can actually reach you';
  @override
  String get trustReachBody =>
      'Each purohit sets a travel radius, so the people you see are the '
      'people who can be at your door on the day.';

  @override
  String get aboutEyebrow => 'What Purohit does';
  @override
  String get aboutHeadline => 'A marketplace for the moments\nthat matter most';
  @override
  String get aboutBody =>
      'Finding a pandit still runs on phone numbers passed around the family. '
      'That works until you move cities, until the date is close, or until '
      'nobody is sure who actually knows the vidhi. Purohit puts that search '
      'in one place — and gives purohits a way to be found by the families '
      'who need them.';

  @override
  String get assuranceHeadline => 'Nothing about a puja should be a gamble';
  @override
  String get assuranceDocuments =>
      'Documents and guru references checked by our team before a purohit is '
      'listed.';
  @override
  String get assuranceReviews =>
      'Reviews written only by families who actually completed a booking.';
  @override
  String get assuranceOneEmail =>
      'One email, one account. A login is either a family or a purohit — '
      'never quietly both.';

  @override
  String get whichSideTitle => 'Which side are you on?';
  @override
  String get whichSideBody =>
      'Pick a door. You can always browse the ceremonies first.';
  @override
  String get justBrowsing => 'Just browsing? See the ceremonies';
  @override
  String get startAsUser => 'Start as a user';
  @override
  String get startAsPurohit => 'Start as a purohit';
  @override
  String get roleUser => 'User';
  @override
  String get rolePurohit => 'Purohit';

  @override
  String get gateForPurohits => 'For purohits';
  @override
  String get gateForFamilies => 'For families';
  @override
  String get gatePurohitHeadline => 'Take bookings from\nfamilies near you';
  @override
  String get gateFamilyHeadline => 'Book a verified purohit\nfor your ceremony';
  @override
  String get gatePurohitBody =>
      'Create a purohit account to list your services, see requests in your '
      'area and apply with your own dakshina. Verification happens after you '
      'register.';
  @override
  String get gateFamilyBody =>
      'Create an account to post the ritual you need, compare verified '
      'purohits and message them before you confirm anything.';
  @override
  String get createAccount => 'Create an account';
  @override
  String get alreadyHaveAccount => 'I already have an account';

  @override
  String oneEmailNotice(String otherSide) =>
      'One email belongs to one side of the app. If this address is already '
      'registered as $otherSide, use that login instead — or register with a '
      'different email.';
  @override
  String get sideFamily => 'a family';
  @override
  String get sidePurohit => 'a purohit';

  @override
  String get purohitLogin => 'Purohit login';
  @override
  String get login => 'Login';
  @override
  String get welcomeBackPanditji => 'Welcome back, panditji';
  @override
  String get welcomeBack => 'Welcome back';
  @override
  String get signInSubtitlePurohit => 'Sign in to see requests near you.';
  @override
  String get signInSubtitleFamily =>
      'Sign in to post a ritual and message purohits.';
  @override
  String get email => 'Email';
  @override
  String get password => 'Password';
  @override
  String get enterYourEmail => 'Enter your email.';
  @override
  String get enterYourPassword => 'Enter your password.';
  @override
  String get signIn => 'Sign in';
  @override
  String get createAccountInstead => 'Create an account instead';
  @override
  String get adminSignIn => 'Admin sign in';
  @override
  String get back => 'Back';

  @override
  String get errNotConfigured => 'Supabase is not configured in this build.';
  @override
  String get errSignInFailed => 'Sign in failed.';
  @override
  String get errWrongCredentials => 'Wrong email or password.';
  @override
  String get errRegisteredAsPurohit =>
      'This email is registered as a purohit. Use the purohit login.';
  @override
  String get errRegisteredAsFamily =>
      'This email is registered as a family account. Use the user login.';

  @override
  String get profile => 'Profile';
  @override
  String get guest => 'Guest';
  @override
  String get labelEmail => 'Email';
  @override
  String get labelCity => 'City';
  @override
  String get labelDateOfBirth => 'Date of birth';
  @override
  String get labelExperience => 'Experience';
  @override
  String yearsCount(int years) => years == 1 ? '1 year' : '$years years';
  @override
  String get about => 'About';
  @override
  String get workPhotos => 'Work photos';
  @override
  String get workPhotosHint =>
      'Families see these on your profile when you apply.';
  @override
  String get registerAsPurohit => 'Register as a purohit';
  @override
  String get editPurohitDetails => 'Edit purohit details';
  @override
  String get verificationConsole => 'Verification console';
  @override
  String get signOut => 'Sign out';
  @override
  String get earlyBuild => 'Purohit Marketplace · early build';

  @override
  String get verificationApprovedBody =>
      'You are verified. Open ceremonies are visible in Find work.';
  @override
  String get verificationRejectedBody =>
      'Your verification was not approved. Reply to the email we sent to '
      'appeal.';
  @override
  String get verificationPendingBody =>
      'Verification pending. Until an admin approves you, the job feed stays '
      'empty — that rule lives in the database, not the app.';

  @override
  String get adminConsoleBlurb =>
      'For the team that reviews purohit applications. The admin role is '
      'granted in Supabase and cannot be requested from the app.';
  @override
  String get adminEmailLabel => 'Admin email';
  @override
  String get emailHintExample => 'you@example.com';
  @override
  String get showPassword => 'Show password';
  @override
  String get hidePassword => 'Hide password';
  @override
  String get adminSignInCta => 'Sign in to console';
  @override
  String get adminVerifyCta => 'Verify and open console';
  @override
  String get adminSendCode => 'Send code';
  @override
  String get adminUseDifferentEmail => 'Use a different email';
  @override
  String get adminUsePasswordInstead => 'Use a password instead';
  @override
  String get adminUseCodeInstead => 'Email me a code instead';
  @override
  String get adminBackToNormalSignIn => 'Back to normal sign in';
  @override
  String get errNotAdmin =>
      'That account is not an administrator. Ask the project owner to set '
      'app_metadata.role = "admin" in Supabase.';
  @override
  String get errInvalidEmail => 'Enter a valid email address.';
  @override
  String get errEnterPassword => 'Enter your password.';
  @override
  String get errEnterCode => 'Enter the 6-digit code.';
  @override
  String errCodeFailed(String detail) => 'That code did not work. $detail';
}
