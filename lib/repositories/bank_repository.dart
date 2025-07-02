// ✅ lib/repositories/bank_repository.dart

import '../models/bank.dart';
import '../models/bank_rates_response.dart';
import '../services/api_service.dart';

class BankRepository {
  static final BankRepository _instance = BankRepository._internal();
  factory BankRepository() => _instance;
  BankRepository._internal();

  List<Bank> _banks = [];
  final Map<String, BankRatesResponse> _cache = {};

  bool get isInitialized => _banks.isNotEmpty;

  List<Bank> get banks => _banks;
  BankRatesResponse? getCachedRates(String code) => _cache[code];

  Future<void> initialize() async {
    if (_banks.isEmpty) {
      _banks = await ApiService.fetchBanks();
    }
  }

  Future<BankRatesResponse> getRates(String bankCode) async {
    if (_cache.containsKey(bankCode)) return _cache[bankCode]!;
    final rates = await ApiService.fetchBankRates(bankCode);
    _cache[bankCode] = rates;
    return rates;
  }

  Future<void> forceRefresh() async {
    _banks = await ApiService.fetchBanks();
    _cache.clear();
  }
}
