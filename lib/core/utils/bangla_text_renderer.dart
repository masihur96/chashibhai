class BanglaTextRenderer {
  BanglaTextRenderer._();

  static const Map<String, String> _englishToBanglaDigits = {
    '0': '০',
    '1': '১',
    '2': '২',
    '3': '৩',
    '4': '৪',
    '5': '৫',
    '6': '৬',
    '7': '৭',
    '8': '৮',
    '9': '৯',
  };

  static const Map<String, String> _banglaToEnglishDigits = {
    '০': '0',
    '১': '1',
    '২': '2',
    '৩': '3',
    '৪': '4',
    '৫': '5',
    '৬': '6',
    '৭': '7',
    '৮': '8',
    '৯': '9',
  };

  /// Converts English numbers string to Bengali numbers
  static String toBanglaNumber(dynamic number) {
    final str = number.toString();
    return str.split('').map((char) => _englishToBanglaDigits[char] ?? char).join();
  }

  /// Converts Bengali numbers string to English numbers
  static String toEnglishNumber(String banglaNumber) {
    return banglaNumber.split('').map((char) => _banglaToEnglishDigits[char] ?? char).join();
  }

  /// Formats amount in Bangladeshi Taka with Bengali digits
  static String formatTaka(num amount) {
    return '৳${toBanglaNumber(amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2))}';
  }
}
