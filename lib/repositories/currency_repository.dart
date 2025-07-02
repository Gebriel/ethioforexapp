import '../models/bank.dart';
import '../models/currency.dart';
import '../models/currency_rates_response.dart';
import '../services/api_service.dart';

class CurrencyRepository {
  static final CurrencyRepository _instance = CurrencyRepository._internal();
  factory CurrencyRepository() => _instance;
  CurrencyRepository._internal();

  List<Currency> _currencies = [];
  List<Bank> _banks = [];
  final Map<String, CurrencyRatesResponse> _cache = {};

  bool get isInitialized => _currencies.isNotEmpty && _banks.isNotEmpty;

  List<Currency> get currencies => _currencies;
  List<Bank> get banks => _banks; // ✅ Add this getter
  CurrencyRatesResponse? getCachedRates(String code) => _cache[code];

  Future<void> initialize() async {
    if (_currencies.isEmpty) {
      _currencies = await ApiService.fetchCurrencies();
    }
    if (_banks.isEmpty) {
      _banks = await ApiService.fetchBanks();
    }
  }

  Future<CurrencyRatesResponse> getRates(String code) async {
    if (_cache.containsKey(code)) return _cache[code]!;
    final rates = await ApiService.fetchRatesByCurrency(code);
    _cache[code] = rates;
    return rates;
  }

  Future<void> forceRefresh() async {
    _currencies = await ApiService.fetchCurrencies();
    _banks = await ApiService.fetchBanks();
    _cache.clear();
  }
}
