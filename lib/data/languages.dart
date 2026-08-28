/// The language list a purohit picks from on the registration screen.
///
/// Codes are stored, not display names. `pandit_profiles.languages` is a
/// `text[]` that already holds ISO-639 codes ('hi', 'en') written by earlier
/// sign-ups, so switching the stored format to names would orphan every
/// existing row and quietly empty the field for purohits who already
/// registered. [IndianLanguages.labelFor] therefore echoes an unrecognised
/// code back verbatim instead of dropping it.
///
/// The list is the 22 Eighth-Schedule languages plus English and the regional
/// tongues a purohit actually conducts ceremonies in (Bhojpuri, Awadhi,
/// Maithili, Marwari and friends), which is the whole point of asking.
class IndianLanguage {
  const IndianLanguage(this.code, this.name, this.native);

  final String code;
  final String name;

  /// Native-script name. Shown alongside the English name because a purohit
  /// scanning for "Bhojpuri" and one scanning for "भोजपुरी" are often the same
  /// person on a phone with a Devanagari keyboard.
  final String native;

  String get label => native.isEmpty ? name : '$name ($native)';
}

/// Sorted by English name so the picker reads predictably. Hindi, Sanskrit and
/// English are duplicated at the top by [IndianLanguages.ordered] because they
/// cover the overwhelming majority of purohits.
const kIndianLanguages = <IndianLanguage>[
  IndianLanguage('as', 'Assamese', 'অসমীয়া'),
  IndianLanguage('awa', 'Awadhi', 'अवधी'),
  IndianLanguage('bn', 'Bengali', 'বাংলা'),
  IndianLanguage('bho', 'Bhojpuri', 'भोजपुरी'),
  IndianLanguage('brx', 'Bodo', 'बड़ो'),
  IndianLanguage('bra', 'Braj Bhasha', 'ब्रज भाषा'),
  IndianLanguage('hne', 'Chhattisgarhi', 'छत्तीसगढ़ी'),
  IndianLanguage('doi', 'Dogri', 'डोगरी'),
  IndianLanguage('en', 'English', ''),
  IndianLanguage('gbm', 'Garhwali', 'गढ़वळि'),
  IndianLanguage('gu', 'Gujarati', 'ગુજરાતી'),
  IndianLanguage('bgc', 'Haryanvi', 'हरियाणवी'),
  IndianLanguage('hi', 'Hindi', 'हिन्दी'),
  IndianLanguage('kn', 'Kannada', 'ಕನ್ನಡ'),
  IndianLanguage('ks', 'Kashmiri', 'کٲشُر'),
  IndianLanguage('kha', 'Khasi', 'Ka Ktien Khasi'),
  IndianLanguage('kok', 'Konkani', 'कोंकणी'),
  IndianLanguage('kfy', 'Kumaoni', 'कुमाऊँनी'),
  IndianLanguage('mag', 'Magahi', 'मगही'),
  IndianLanguage('mai', 'Maithili', 'मैथिली'),
  IndianLanguage('ml', 'Malayalam', 'മലയാളം'),
  IndianLanguage('mni', 'Manipuri', 'ꯃꯤꯇꯩꯂꯣꯟ'),
  IndianLanguage('mr', 'Marathi', 'मराठी'),
  IndianLanguage('mwr', 'Marwari', 'मारवाड़ी'),
  IndianLanguage('lus', 'Mizo', 'Mizo ṭawng'),
  IndianLanguage('ne', 'Nepali', 'नेपाली'),
  IndianLanguage('or', 'Odia', 'ଓଡ଼ିଆ'),
  IndianLanguage('pa', 'Punjabi', 'ਪੰਜਾਬੀ'),
  IndianLanguage('raj', 'Rajasthani', 'राजस्थानी'),
  IndianLanguage('sa', 'Sanskrit', 'संस्कृतम्'),
  IndianLanguage('sat', 'Santali', 'ᱥᱟᱱᱛᱟᱲᱤ'),
  IndianLanguage('sd', 'Sindhi', 'سنڌي'),
  IndianLanguage('ta', 'Tamil', 'தமிழ்'),
  IndianLanguage('te', 'Telugu', 'తెలుగు'),
  IndianLanguage('bo', 'Tibetan', 'བོད་སྐད'),
  IndianLanguage('tcy', 'Tulu', 'ತುಳು'),
  IndianLanguage('ur', 'Urdu', 'اردو'),
];

abstract final class IndianLanguages {
  static const _priority = ['hi', 'sa', 'en'];

  /// The three most common first, then everything else alphabetically.
  static List<IndianLanguage> get ordered {
    final head = <IndianLanguage>[];
    for (final code in _priority) {
      final hit = kIndianLanguages.where((l) => l.code == code);
      if (hit.isNotEmpty) head.add(hit.first);
    }
    final tail = kIndianLanguages
        .where((l) => !_priority.contains(l.code))
        .toList();
    return [...head, ...tail];
  }

  /// Unknown codes are echoed back so a legacy value never vanishes from the
  /// purohit's profile just because it is not in the list above.
  static String labelFor(String code) {
    for (final l in kIndianLanguages) {
      if (l.code == code) return l.label;
    }
    return code;
  }

  static IndianLanguage? byCode(String code) {
    for (final l in kIndianLanguages) {
      if (l.code == code) return l;
    }
    return null;
  }
}
