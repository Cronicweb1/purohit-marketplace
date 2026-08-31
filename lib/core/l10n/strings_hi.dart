import 'app_strings.dart';

/// Hindi copy.
///
/// Ritual vocabulary (मुहूर्त, सामग्री, दक्षिणा, गुरु परंपरा, विधि) is written in
/// Devanagari rather than transliterated, because those are the words a family
/// actually uses. "Purohit" stays पुरोहित as the product name too — the brand and
/// the profession are the same word, which is the whole point of the name.
class AppStringsHi extends AppStrings {
  const AppStringsHi();

  @override
  String get languageTitle => 'भाषा';
  @override
  String get languageSubtitle => 'ऐप के लिए भाषा चुनें।';
  @override
  String get languageChangeCta => 'भाषा बदलें';

  @override
  String get navBrowse => 'खोजें';
  @override
  String get navFindWork => 'काम खोजें';
  @override
  String get navMyJobs => 'मेरे काम';
  @override
  String get navApplications => 'आवेदन';
  @override
  String get navPost => 'पोस्ट';
  @override
  String get navMessages => 'संदेश';
  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get brand => 'पुरोहित';

  @override
  List<String> get heroLines => const [
        'पंडित जी बुक करें, उतनी ही आसानी से जितनी किसी और ज़रूरी चीज़ के लिए।',
        'हर अनुष्ठान का हक़ है ऐसे व्यक्ति पर जो जानता हो कि वह क्यों किया जाता है।',
        'मुहूर्त, मंत्र, सामग्री — मेहमानों के आने से पहले ही तय।',
        'आपकी पारिवारिक परंपराएँ, उन हाथों में जिन्होंने उन्हें पहले भी निभाया है।',
      ];

  @override
  String get scrollHint => 'देखें यह कैसे काम करता है';
  @override
  String get landingForFamilies => 'परिवारों के लिए';
  @override
  String get landingForPurohits => 'पुरोहितों के लिए';
  @override
  String get landingFamilyHeadline => 'सही पुरोहित चुनें,\nकोई भी पुरोहित नहीं';
  @override
  String get landingPurohitHeadline => 'आपका ज्ञान,\nअब आसानी से मिल सके';

  @override
  String get stepTellRitualTitle => 'अनुष्ठान बताइए';
  @override
  String get stepTellRitualBody =>
      'गृह प्रवेश, सत्यनारायण कथा, नामकरण, श्राद्ध — अपने शहर के साथ वह '
      'संस्कार और तिथि चुनिए जो आपके मन में है।';
  @override
  String get stepCompareTitle => 'सत्यापित पुरोहितों की तुलना करें';
  @override
  String get stepCompareBody =>
      'अनुभव, बोली जाने वाली भाषाएँ, निभाई जाने वाली परंपराएँ और दक्षिणा — सब '
      'देखिए। सूची में हर पुरोहित हमारा सत्यापन पूरा कर चुका है।';
  @override
  String get stepTalkTitle => 'बात करें, फिर तय करें';
  @override
  String get stepTalkBody =>
      'सामग्री, मुहूर्त और पूजा में लगने वाले समय पर संदेश भेजकर बात कीजिए। '
      'ठीक लगे तभी पुष्टि कीजिए।';

  @override
  String get stepRegisterTitle => 'पंजीकरण कराएँ और सत्यापित हों';
  @override
  String get stepRegisterBody =>
      'अपना अनुभव, गुरु परंपरा और दस्तावेज़ एक बार साझा कीजिए। मिलने से पहले ही '
      'परिवार का भरोसा सत्यापन से बनता है।';
  @override
  String get stepRequestsTitle => 'अपने आसपास के असली अनुरोध देखें';
  @override
  String get stepRequestsBody =>
      'परिवार अनुष्ठान, तिथि और स्थान पोस्ट करते हैं। अपनी यात्रा सीमा तय कीजिए '
      'और केवल वही देखिए जहाँ आप सचमुच पहुँच सकते हैं।';
  @override
  String get stepApplyTitle => 'अपनी शर्तों पर आवेदन करें';
  @override
  String get stepApplyBody =>
      'अपनी दक्षिणा बताइए, चैट में सवालों के जवाब दीजिए और वही काम लीजिए जो '
      'आपके कैलेंडर में बैठता हो।';

  @override
  String get trustVerifiedTitle => 'सिर्फ़ सूचीबद्ध नहीं, सत्यापित';
  @override
  String get trustVerifiedBody =>
      'किसी एक भी परिवार तक पहुँचने से पहले हर पुरोहित दस्तावेज़ और गुरु संदर्भ '
      'देता है। बिना समीक्षा कोई ऐप पर नहीं आता।';
  @override
  String get trustLanguageTitle => 'आपकी भाषा, आपकी परंपरा';
  @override
  String get trustLanguageBody =>
      'पुरोहित की भाषा और उनके द्वारा की जाने वाली परंपरा से छाँटिए, ताकि '
      'अनुष्ठान वैसा ही लगे जैसा घर पर होता है।';
  @override
  String get trustDakshinaTitle => 'दक्षिणा पहले से तय';
  @override
  String get trustDakshinaBody =>
      'बुकिंग से पहले शुल्क बताया जाता है और चैट में उस पर बात होती है। पूजा की '
      'सुबह कोई असहज बातचीत नहीं।';
  @override
  String get trustReachTitle => 'ऐसे पुरोहित जो सचमुच पहुँच सकें';
  @override
  String get trustReachBody =>
      'हर पुरोहित अपनी यात्रा सीमा तय करता है, इसलिए आपको वही लोग दिखते हैं जो '
      'उस दिन आपके द्वार तक आ सकें।';

  @override
  String get aboutEyebrow => 'पुरोहित क्या करता है';
  @override
  String get aboutHeadline => 'उन क्षणों के लिए एक मंच\nजो सबसे ज़्यादा मायने रखते हैं';
  @override
  String get aboutBody =>
      'पंडित जी की तलाश आज भी परिवार में इधर-उधर घूमते फ़ोन नंबरों से चलती है। '
      'यह तब तक ठीक है जब तक आप शहर न बदलें, तिथि पास न आ जाए, या किसी को यह '
      'पक्का न पता हो कि विधि असल में कौन जानता है। पुरोहित इस तलाश को एक जगह '
      'ले आता है — और पुरोहितों को उन परिवारों तक पहुँचने का रास्ता देता है '
      'जिन्हें उनकी ज़रूरत है।';

  @override
  String get assuranceHeadline => 'पूजा में कुछ भी जुए जैसा नहीं होना चाहिए';
  @override
  String get assuranceDocuments =>
      'पुरोहित को सूचीबद्ध करने से पहले हमारी टीम दस्तावेज़ और गुरु संदर्भ जाँचती है।';
  @override
  String get assuranceReviews =>
      'समीक्षाएँ केवल उन परिवारों की, जिन्होंने सचमुच बुकिंग पूरी की हो।';
  @override
  String get assuranceOneEmail =>
      'एक ईमेल, एक खाता। लॉगिन या तो परिवार का होगा या पुरोहित का — चुपचाप दोनों '
      'कभी नहीं।';

  @override
  String get whichSideTitle => 'आप किस ओर हैं?';
  @override
  String get whichSideBody =>
      'एक द्वार चुनिए। आप पहले संस्कार भी देख सकते हैं।';
  @override
  String get justBrowsing => 'बस देख रहे हैं? संस्कार देखिए';
  @override
  String get startAsUser => 'उपयोगकर्ता के रूप में शुरू करें';
  @override
  String get startAsPurohit => 'पुरोहित के रूप में शुरू करें';
  @override
  String get roleUser => 'उपयोगकर्ता';
  @override
  String get rolePurohit => 'पुरोहित';

  @override
  String get gateForPurohits => 'पुरोहितों के लिए';
  @override
  String get gateForFamilies => 'परिवारों के लिए';
  @override
  String get gatePurohitHeadline => 'अपने आसपास के परिवारों से\nबुकिंग लीजिए';
  @override
  String get gateFamilyHeadline => 'अपने अनुष्ठान के लिए\nसत्यापित पुरोहित बुक कीजिए';
  @override
  String get gatePurohitBody =>
      'पुरोहित खाता बनाइए ताकि आप अपनी सेवाएँ सूचीबद्ध कर सकें, अपने क्षेत्र के '
      'अनुरोध देख सकें और अपनी दक्षिणा के साथ आवेदन कर सकें। सत्यापन पंजीकरण के '
      'बाद होता है।';
  @override
  String get gateFamilyBody =>
      'खाता बनाइए ताकि आप अपना ज़रूरी अनुष्ठान पोस्ट कर सकें, सत्यापित पुरोहितों '
      'की तुलना कर सकें और कुछ भी पक्का करने से पहले उनसे बात कर सकें।';
  @override
  String get createAccount => 'खाता बनाएँ';
  @override
  String get alreadyHaveAccount => 'मेरा खाता पहले से है';

  @override
  String oneEmailNotice(String otherSide) =>
      'एक ईमेल ऐप के एक ही पक्ष का होता है। यदि यह पता पहले से $otherSide के रूप '
      'में पंजीकृत है, तो वही लॉगिन उपयोग कीजिए — या किसी दूसरे ईमेल से पंजीकरण '
      'कीजिए।';
  @override
  String get sideFamily => 'परिवार';
  @override
  String get sidePurohit => 'पुरोहित';

  @override
  String get purohitLogin => 'पुरोहित लॉगिन';
  @override
  String get login => 'लॉगिन';
  @override
  String get welcomeBackPanditji => 'पुनः स्वागत है, पंडित जी';
  @override
  String get welcomeBack => 'पुनः स्वागत है';
  @override
  String get signInSubtitlePurohit =>
      'अपने आसपास के अनुरोध देखने के लिए साइन इन कीजिए।';
  @override
  String get signInSubtitleFamily =>
      'अनुष्ठान पोस्ट करने और पुरोहितों से बात करने के लिए साइन इन कीजिए।';
  @override
  String get email => 'ईमेल';
  @override
  String get password => 'पासवर्ड';
  @override
  String get enterYourEmail => 'अपना ईमेल दर्ज कीजिए।';
  @override
  String get enterYourPassword => 'अपना पासवर्ड दर्ज कीजिए।';
  @override
  String get signIn => 'साइन इन';
  @override
  String get createAccountInstead => 'इसके बजाय खाता बनाएँ';
  @override
  String get adminSignIn => 'एडमिन साइन इन';
  @override
  String get back => 'वापस';

  @override
  String get errNotConfigured => 'इस बिल्ड में Supabase कॉन्फ़िगर नहीं है।';
  @override
  String get errSignInFailed => 'साइन इन विफल रहा।';
  @override
  String get errWrongCredentials => 'ईमेल या पासवर्ड ग़लत है।';
  @override
  String get errRegisteredAsPurohit =>
      'यह ईमेल पुरोहित के रूप में पंजीकृत है। पुरोहित लॉगिन का उपयोग कीजिए।';
  @override
  String get errRegisteredAsFamily =>
      'यह ईमेल परिवार खाते के रूप में पंजीकृत है। उपयोगकर्ता लॉगिन का उपयोग कीजिए।';

  @override
  String get profile => 'प्रोफ़ाइल';
  @override
  String get guest => 'अतिथि';
  @override
  String get labelEmail => 'ईमेल';
  @override
  String get labelCity => 'शहर';
  @override
  String get labelDateOfBirth => 'जन्म तिथि';
  @override
  String get labelExperience => 'अनुभव';
  @override
  String yearsCount(int years) => years == 1 ? '1 वर्ष' : '$years वर्ष';
  @override
  String get about => 'परिचय';
  @override
  String get workPhotos => 'कार्य की तस्वीरें';
  @override
  String get workPhotosHint =>
      'आवेदन करने पर परिवार आपकी प्रोफ़ाइल में ये तस्वीरें देखते हैं।';
  @override
  String get registerAsPurohit => 'पुरोहित के रूप में पंजीकरण करें';
  @override
  String get editPurohitDetails => 'पुरोहित विवरण संपादित करें';
  @override
  String get verificationConsole => 'सत्यापन कंसोल';
  @override
  String get signOut => 'साइन आउट';
  @override
  String get earlyBuild => 'पुरोहित मार्केटप्लेस · प्रारंभिक बिल्ड';

  @override
  String get verificationApprovedBody =>
      'आप सत्यापित हैं। खुले अनुष्ठान "काम खोजें" में दिख रहे हैं।';
  @override
  String get verificationRejectedBody =>
      'आपका सत्यापन स्वीकृत नहीं हुआ। अपील के लिए हमारे भेजे गए ईमेल का उत्तर दीजिए।';
  @override
  String get verificationPendingBody =>
      'सत्यापन लंबित है। जब तक कोई एडमिन आपको स्वीकृत नहीं करता, काम की सूची '
      'खाली रहेगी — यह नियम ऐप में नहीं, डेटाबेस में है।';

  @override
  String get adminConsoleBlurb =>
      'पुरोहित आवेदनों की समीक्षा करने वाली टीम के लिए। एडमिन भूमिका Supabase में दी '
      'जाती है और ऐप से नहीं मांगी जा सकती।';
  @override
  String get adminEmailLabel => 'एडमिन ईमेल';
  @override
  String get emailHintExample => 'you@example.com';
  @override
  String get showPassword => 'पासवर्ड दिखाएँ';
  @override
  String get hidePassword => 'पासवर्ड छिपाएँ';
  @override
  String get adminSignInCta => 'कंसोल में साइन इन करें';
  @override
  String get adminVerifyCta => 'सत्यापित करके कंसोल खोलें';
  @override
  String get adminSendCode => 'कोड भेजें';
  @override
  String get adminUseDifferentEmail => 'दूसरा ईमेल उपयोग करें';
  @override
  String get adminUsePasswordInstead => 'इसके बजाय पासवर्ड उपयोग करें';
  @override
  String get adminUseCodeInstead => 'इसके बजाय मुझे कोड ईमेल करें';
  @override
  String get adminBackToNormalSignIn => 'सामान्य साइन इन पर लौटें';
  @override
  String get errNotAdmin =>
      'यह खाता एडमिन नहीं है। प्रोजेक्ट ओनर से Supabase में app_metadata.role = "admin" '
      'सेट करने को कहें।';
  @override
  String get errInvalidEmail => 'मान्य ईमेल पता दर्ज करें।';
  @override
  String get errEnterPassword => 'अपना पासवर्ड दर्ज करें।';
  @override
  String get errEnterCode => '6 अंकों का कोड दर्ज करें।';
  @override
  String errCodeFailed(String detail) => 'यह कोड काम नहीं कर सका। $detail';

  // ---- Jobs ---------------------------------------------------------------
  @override
  String get findWork => 'काम खोजें';
  @override
  String get searchCeremoniesHint => 'संस्कार खोजें, जैसे गृह प्रवेश';
  @override
  String get clearSearch => 'खोज हटाएँ';
  @override
  String get clearFilters => 'फ़िल्टर हटाएँ';
  @override
  String get clearAction => 'हटाएँ';
  @override
  String openJobsCount(int count) =>
      count == 1 ? '1 खुला काम' : '$count खुले काम';
  @override
  String get feedAwaitingVerificationBody =>
      'आपकी पुरोहित लिस्टिंग सत्यापन की प्रतीक्षा में है। जब तक कोई एडमिन '
      'आपको स्वीकृत नहीं करता, काम की पोस्ट छिपी रहती हैं — यह डेटाबेस स्तर '
      'पर लागू है, इसलिए तब तक नीचे की सूची खाली रहेगी।';
  @override
  String get noOpenJobsMatch => 'कोई खुला काम मेल नहीं खाता';
  @override
  String get nothingToShowYet => 'अभी दिखाने को कुछ नहीं';
  @override
  String get noOpenJobsMatchBody => 'फ़िल्टर हटाकर देखें, या कल फिर देखें।';
  @override
  String get feedLockedBody =>
      'आपकी लिस्टिंग सत्यापित होते ही, परिवारों द्वारा पोस्ट किए गए संस्कार '
      'यहाँ दिखेंगे।';

  @override
  String get urgent => 'तत्काल';
  @override
  String postedAgo(String ago) => '$ago पोस्ट किया गया';

  @override
  String get ceremony => 'संस्कार';
  @override
  String get notVisibleToYou => 'आपको दिखाई नहीं देता';
  @override
  String get notVisibleToYouBody =>
      'यह संस्कार या तो अब मौजूद नहीं है, या row-level security आपको इस तक '
      'पहुँच नहीं देती।';
  @override
  String get budget => 'बजट';
  @override
  String get dateLabel => 'तिथि';
  @override
  String get locationLabel => 'स्थान';
  @override
  String get urgencyLabel => 'तात्कालिकता';
  @override
  String get detailsLabel => 'विवरण';
  @override
  String get applicationsLabel => 'आवेदन';
  @override
  String get noApplicantsYet =>
      'अभी तक किसी पुरोहित ने आवेदन नहीं किया। सत्यापित पुरोहितों को आपकी '
      'पोस्ट उनकी फ़ीड में दिखती है।';
  @override
  String couldNotOpenChat(String detail) => 'चैट नहीं खुल सकी: $detail';
  @override
  String get thisPurohit => 'इस पुरोहित';
  @override
  String get confirmPurohitTitle => 'पुरोहित की पुष्टि करें';
  @override
  String confirmPurohitBody(String name) =>
      'इस संस्कार के लिए $name को चुनें?\n\n'
      'बाकी सभी आवेदकों को "नहीं चुना गया" कर दिया जाएगा, संस्कार '
      '"पुरोहित चयनित" स्थिति में चला जाएगा, और संपर्क विवरण साझा हो जाएँगे। '
      'इसे ऐप से पूर्ववत नहीं किया जा सकता।';
  @override
  String get cancelAction => 'रद्द करें';
  @override
  String get confirmAction => 'पुष्टि करें';
  @override
  String purohitConfirmed(String name) =>
      'इस संस्कार के लिए $name की पुष्टि हो गई।';
  @override
  String couldNotConfirm(String detail) => 'पुष्टि नहीं हो सकी: $detail';
  @override
  String get purohitFallbackName => 'पुरोहित';
  @override
  String yearsShort(int years) => '$years वर्ष';
  @override
  String get noAmountQuoted => 'कोई राशि नहीं बताई';
  @override
  String quotedAmount(String amount) => '$amount बताया';
  @override
  String get messageAction => 'संदेश';
  @override
  String get selectAction => 'चुनें';
  @override
  String get applicationSent => 'आवेदन भेज दिया गया।';
  @override
  String get ctaVerificationPending => 'सत्यापन लंबित';
  @override
  String get ctaClosed => 'बंद';
  @override
  String get ctaApplied => 'आवेदन किया';
  @override
  String get ctaApply => 'आवेदन करें';
  @override
  String get sendYourQuote => 'अपना प्रस्ताव भेजें';
  @override
  String get yourFeeLabel => 'आपकी दक्षिणा (₹)';
  @override
  String get feeHintExample => 'जैसे 5100';
  @override
  String get messageToFamily => 'परिवार को संदेश';
  @override
  String get messageToFamilyHint =>
      'आप किस सम्प्रदाय का पालन करते हैं, इसमें क्या शामिल है…';
  @override
  String get sendApplication => 'आवेदन भेजें';

  @override
  String get myApplications => 'मेरे आवेदन';
  @override
  String get myCeremonies => 'मेरे संस्कार';
  @override
  String get nothingPostedYet => 'अभी कुछ पोस्ट नहीं किया';
  @override
  String get nothingPostedYetBody =>
      'पोस्ट टैब से संस्कार पोस्ट करें। आपके शहर के सत्यापित पुरोहित इसे '
      'देखेंगे और आपको अपने प्रस्ताव भेजेंगे।';
  @override
  String get noApplicationsYet => 'अभी कोई आवेदन नहीं';
  @override
  String get noApplicationsYetBody =>
      '"काम खोजें" खोलें, ऐसा संस्कार चुनें जो आप करा सकते हैं, और परिवार को '
      'अपना प्रस्ताव भेजें।';
  @override
  String ceremonyNumber(int id) => 'संस्कार #$id';
  @override
  String youQuoted(String amount) => 'आपने $amount बताया';
  @override
  String sentAgo(String ago) => '$ago भेजा';
  @override
  String get selectedContactUnlocked =>
      'चयनित — परिवार के संपर्क विवरण अनलॉक हो गए हैं।';

  // ---- Enum labels --------------------------------------------------------
  @override
  String get urgencyFlexible => 'लचीली तिथि';
  @override
  String get urgencyScheduled => 'निर्धारित';
  @override
  String get urgencyImmediate => 'तत्काल';
  @override
  String get jobStatusOpen => 'खुला';
  @override
  String get jobStatusAssigned => 'पुरोहित चयनित';
  @override
  String get jobStatusCompleted => 'पूर्ण';
  @override
  String get jobStatusCancelled => 'रद्द';
  @override
  String get appStatusApplied => 'आवेदन किया';
  @override
  String get appStatusShortlisted => 'शॉर्टलिस्ट';
  @override
  String get appStatusSelected => 'चयनित';
  @override
  String get appStatusRejected => 'नहीं चुना गया';
  @override
  String get appStatusWithdrawn => 'वापस लिया';

  // ---- Money, dates, relative time ---------------------------------------
  @override
  String get notSpecified => 'निर्दिष्ट नहीं';
  @override
  String get openToQuotes => 'प्रस्ताव आमंत्रित';
  @override
  String get justNow => 'अभी अभी';
  @override
  String minutesAgo(int n) => '$n मिनट पहले';
  @override
  String hoursAgo(int n) => '$n घंटे पहले';
  @override
  String daysAgo(int n) => '$n दिन पहले';
  @override
  String monthsAgo(int n) => '$n महीने पहले';
  @override
  String yearsAgo(int n) => '$n वर्ष पहले';
  @override
  String get datePassed => 'तिथि बीत चुकी';
  @override
  String get todayLabel => 'आज';
  @override
  String get tomorrowLabel => 'कल';
  @override
  String inDaysLabel(int days) => '$days दिन में';
}
