/// Central registry for DOJO WALK language rollout.
///
/// Only languages with complete, reviewed translations should be selectable.
/// Adding a language here does not claim its translations are complete.
class DojoLanguage {
  const DojoLanguage({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.isAvailable,
  });

  final String code;
  final String nativeName;
  final String englishName;
  final bool isAvailable;
}

const List<DojoLanguage> dojoLanguages = [
  DojoLanguage(code: 'en', nativeName: 'English', englishName: 'English', isAvailable: true),
  DojoLanguage(code: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi', isAvailable: true),
  DojoLanguage(code: 'bn', nativeName: 'বাংলা', englishName: 'Bengali', isAvailable: true),
  DojoLanguage(code: 'as', nativeName: 'অসমীয়া', englishName: 'Assamese', isAvailable: false),
  DojoLanguage(code: 'brx', nativeName: 'बड़ो', englishName: 'Bodo', isAvailable: false),
  DojoLanguage(code: 'doi', nativeName: 'डोगरी', englishName: 'Dogri', isAvailable: false),
  DojoLanguage(code: 'gu', nativeName: 'ગુજરાતી', englishName: 'Gujarati', isAvailable: false),
  DojoLanguage(code: 'kn', nativeName: 'ಕನ್ನಡ', englishName: 'Kannada', isAvailable: false),
  DojoLanguage(code: 'ks', nativeName: 'کٲشُر', englishName: 'Kashmiri', isAvailable: false),
  DojoLanguage(code: 'kok', nativeName: 'कोंकणी', englishName: 'Konkani', isAvailable: false),
  DojoLanguage(code: 'mai', nativeName: 'मैथिली', englishName: 'Maithili', isAvailable: false),
  DojoLanguage(code: 'ml', nativeName: 'മലയാളം', englishName: 'Malayalam', isAvailable: false),
  DojoLanguage(code: 'mni', nativeName: 'মৈতৈলোন্', englishName: 'Manipuri (Meitei)', isAvailable: false),
  DojoLanguage(code: 'mr', nativeName: 'मराठी', englishName: 'Marathi', isAvailable: false),
  DojoLanguage(code: 'ne', nativeName: 'नेपाली', englishName: 'Nepali', isAvailable: false),
  DojoLanguage(code: 'or', nativeName: 'ଓଡ଼ିଆ', englishName: 'Odia', isAvailable: false),
  DojoLanguage(code: 'pa', nativeName: 'ਪੰਜਾਬੀ', englishName: 'Punjabi', isAvailable: false),
  DojoLanguage(code: 'sa', nativeName: 'संस्कृतम्', englishName: 'Sanskrit', isAvailable: false),
  DojoLanguage(code: 'sat', nativeName: 'ᱥᱟᱱᱛᱟᱲᱤ', englishName: 'Santali', isAvailable: false),
  DojoLanguage(code: 'sd', nativeName: 'سنڌي', englishName: 'Sindhi', isAvailable: false),
  DojoLanguage(code: 'ta', nativeName: 'தமிழ்', englishName: 'Tamil', isAvailable: false),
  DojoLanguage(code: 'te', nativeName: 'తెలుగు', englishName: 'Telugu', isAvailable: false),
  DojoLanguage(code: 'ur', nativeName: 'اردو', englishName: 'Urdu', isAvailable: false),
];

List<DojoLanguage> get availableDojoLanguages =>
    dojoLanguages.where((language) => language.isAvailable).toList();

DojoLanguage dojoLanguageByCode(String code) {
  return dojoLanguages.firstWhere(
    (language) => language.code == code,
    orElse: () => dojoLanguages.first,
  );
}
