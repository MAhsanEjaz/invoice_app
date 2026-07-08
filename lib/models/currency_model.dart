class CurrencyModel {
  final String code;
  final String name;
  final String symbol;
  final String flag;

  const CurrencyModel({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
  });

  /// PDF-safe symbol using only Latin-1 characters supported by standard
  /// PDF fonts (Helvetica). Unicode symbols like ₨, ₹, €, ₩ are replaced
  /// with readable ASCII equivalents.
  String get pdfSymbol {
    const Map<String, String> pdfMap = {
      'USD': r'$',
      'EUR': 'EUR',
      'GBP': '£', // £ is Latin-1
      'PKR': 'Rs.',
      'INR': 'Rs.',
      'AED': 'AED',
      'SAR': 'SAR',
      'CAD': r'CA$',
      'AUD': r'A$',
      'CHF': 'Fr',
      'JPY': '¥', // ¥ is Latin-1
      'CNY': 'CNY',
      'KRW': 'KRW',
      'BDT': 'BDT',
      'SGD': r'S$',
      'MYR': 'RM',
      'THB': 'THB',
      'TRY': 'TRY',
      'BRL': r'R$',
      'ZAR': 'R',
      'KWD': 'KD',
      'QAR': 'QR',
      'OMR': 'OMR',
      'BHD': 'BD',
      'NGN': 'NGN',
      'EGP': 'EGP',
      'KES': 'KSh',
      'IDR': 'Rp',
      'PHP': 'PHP',
      'VND': 'VND',
      'MXN': r'MX$',
      'SEK': 'kr',
      'NOK': 'kr',
      'DKK': 'kr',
      'NZD': r'NZ$',
      'HKD': r'HK$',
    };
    return pdfMap[code] ?? code;
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'symbol': symbol,
    'flag': flag,
  };

  factory CurrencyModel.fromJson(Map<String, dynamic> json) => CurrencyModel(
    code: json['code'] as String,
    name: json['name'] as String,
    symbol: json['symbol'] as String,
    flag: json['flag'] as String,
  );

  static const CurrencyModel defaultCurrency = CurrencyModel(
    code: 'USD',
    name: 'US Dollar',
    symbol: '\$',
    flag: '🇺🇸',
  );

  static const List<CurrencyModel> all = [
    CurrencyModel(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸'),
    CurrencyModel(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺'),
    CurrencyModel(
      code: 'GBP',
      name: 'British Pound',
      symbol: '£',
      flag: '🇬🇧',
    ),
    CurrencyModel(
      code: 'PKR',
      name: 'Pakistani Rupee',
      symbol: '₨',
      flag: '🇵🇰',
    ),
    CurrencyModel(code: 'INR', name: 'Indian Rupee', symbol: '₹', flag: '🇮🇳'),
    CurrencyModel(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ', flag: '🇦🇪'),
    CurrencyModel(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼', flag: '🇸🇦'),
    CurrencyModel(
      code: 'CAD',
      name: 'Canadian Dollar',
      symbol: 'CA\$',
      flag: '🇨🇦',
    ),
    CurrencyModel(
      code: 'AUD',
      name: 'Australian Dollar',
      symbol: 'A\$',
      flag: '🇦🇺',
    ),
    CurrencyModel(code: 'CHF', name: 'Swiss Franc', symbol: 'Fr', flag: '🇨🇭'),
    CurrencyModel(code: 'JPY', name: 'Japanese Yen', symbol: '¥', flag: '🇯🇵'),
    CurrencyModel(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', flag: '🇨🇳'),
    CurrencyModel(
      code: 'KRW',
      name: 'South Korean Won',
      symbol: '₩',
      flag: '🇰🇷',
    ),
    CurrencyModel(
      code: 'BDT',
      name: 'Bangladeshi Taka',
      symbol: '৳',
      flag: '🇧🇩',
    ),
    CurrencyModel(
      code: 'SGD',
      name: 'Singapore Dollar',
      symbol: 'S\$',
      flag: '🇸🇬',
    ),
    CurrencyModel(
      code: 'MYR',
      name: 'Malaysian Ringgit',
      symbol: 'RM',
      flag: '🇲🇾',
    ),
    CurrencyModel(code: 'THB', name: 'Thai Baht', symbol: '฿', flag: '🇹🇭'),
    CurrencyModel(code: 'TRY', name: 'Turkish Lira', symbol: '₺', flag: '🇹🇷'),
    CurrencyModel(
      code: 'BRL',
      name: 'Brazilian Real',
      symbol: 'R\$',
      flag: '🇧🇷',
    ),
    CurrencyModel(
      code: 'ZAR',
      name: 'South African Rand',
      symbol: 'R',
      flag: '🇿🇦',
    ),
    CurrencyModel(
      code: 'KWD',
      name: 'Kuwaiti Dinar',
      symbol: 'KD',
      flag: '🇰🇼',
    ),
    CurrencyModel(
      code: 'QAR',
      name: 'Qatari Riyal',
      symbol: 'QR',
      flag: '🇶🇦',
    ),
    CurrencyModel(code: 'OMR', name: 'Omani Rial', symbol: 'OMR', flag: '🇴🇲'),
    CurrencyModel(
      code: 'BHD',
      name: 'Bahraini Dinar',
      symbol: 'BD',
      flag: '🇧🇭',
    ),
    CurrencyModel(
      code: 'NGN',
      name: 'Nigerian Naira',
      symbol: '₦',
      flag: '🇳🇬',
    ),
    CurrencyModel(
      code: 'EGP',
      name: 'Egyptian Pound',
      symbol: 'E£',
      flag: '🇪🇬',
    ),
    CurrencyModel(
      code: 'KES',
      name: 'Kenyan Shilling',
      symbol: 'KSh',
      flag: '🇰🇪',
    ),
    CurrencyModel(
      code: 'IDR',
      name: 'Indonesian Rupiah',
      symbol: 'Rp',
      flag: '🇮🇩',
    ),
    CurrencyModel(
      code: 'PHP',
      name: 'Philippine Peso',
      symbol: '₱',
      flag: '🇵🇭',
    ),
    CurrencyModel(
      code: 'VND',
      name: 'Vietnamese Dong',
      symbol: '₫',
      flag: '🇻🇳',
    ),
    CurrencyModel(
      code: 'MXN',
      name: 'Mexican Peso',
      symbol: 'MX\$',
      flag: '🇲🇽',
    ),
    CurrencyModel(
      code: 'SEK',
      name: 'Swedish Krona',
      symbol: 'kr',
      flag: '🇸🇪',
    ),
    CurrencyModel(
      code: 'NOK',
      name: 'Norwegian Krone',
      symbol: 'kr',
      flag: '🇳🇴',
    ),
    CurrencyModel(
      code: 'DKK',
      name: 'Danish Krone',
      symbol: 'kr',
      flag: '🇩🇰',
    ),
    CurrencyModel(
      code: 'NZD',
      name: 'New Zealand Dollar',
      symbol: 'NZ\$',
      flag: '🇳🇿',
    ),
    CurrencyModel(
      code: 'HKD',
      name: 'Hong Kong Dollar',
      symbol: 'HK\$',
      flag: '🇭🇰',
    ),
  ];
}
