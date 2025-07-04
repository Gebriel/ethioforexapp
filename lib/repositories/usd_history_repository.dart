import '../models/history_rates_response.dart';
import '../services/api_service.dart';

class UsdHistoryRepository {
  static final UsdHistoryRepository _instance = UsdHistoryRepository._internal();
  final Map<String, HistoryRatesResponse> _cache = {};

  factory UsdHistoryRepository() => _instance;

  UsdHistoryRepository._internal();

  HistoryRatesResponse? getCached(String bankCode) => _cache[bankCode];

  Future<HistoryRatesResponse> getUsdHistory(String bankCode) async {
    if (_cache.containsKey(bankCode)) return _cache[bankCode]!;

    final response = await ApiService.fetchUsdHistoryForBank(bankCode);
    _cache[bankCode] = response;
    return response;
  }

  void clearCache() => _cache.clear();
}