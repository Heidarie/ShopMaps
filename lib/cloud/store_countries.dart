class StoreCountry {
  const StoreCountry({required this.code, required this.languageCode});

  final String code;
  final String languageCode;
}

class StoreCountries {
  const StoreCountries._();

  static const all = [
    StoreCountry(code: 'gb', languageCode: 'en'),
    StoreCountry(code: 'pl', languageCode: 'pl'),
    StoreCountry(code: 'de', languageCode: 'de'),
    StoreCountry(code: 'nl', languageCode: 'nl'),
    StoreCountry(code: 'es', languageCode: 'es'),
    StoreCountry(code: 'fr', languageCode: 'fr'),
    StoreCountry(code: 'ua', languageCode: 'uk'),
    StoreCountry(code: 'it', languageCode: 'it'),
    StoreCountry(code: 'pt', languageCode: 'pt'),
  ];

  static String defaultForLanguageCode(String languageCode) {
    for (final country in all) {
      if (country.languageCode == languageCode) {
        return country.code;
      }
    }
    return 'gb';
  }

  static bool isSupported(String? countryCode) {
    if (countryCode == null) {
      return false;
    }
    return all.any((country) => country.code == countryCode.toLowerCase());
  }
}
