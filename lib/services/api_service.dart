import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/bank.dart';
import '../models/bank_rates_response.dart';
import '../models/currency.dart';
import '../models/currency_rates_response.dart';

class ApiService {
  static Future<List<Currency>> fetchCurrencies() async {
    print('Fetching currencies');
    final uri = Uri.parse('$baseUrl/api/currencies');
    final res = await http.get(uri, headers: {'x-api-key': apiKey});

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.map((e) => Currency.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load currencies: ${res.statusCode}");
    }
  }

  static Future<CurrencyRatesResponse> fetchRatesByCurrency(String currencyCode) async {
    print('Fetching rates for currencyCode: $currencyCode');
    final uri = Uri.parse('$baseUrl/api/currency/$currencyCode');
    final res = await http.get(uri, headers: {'x-api-key': apiKey});

    if (res.statusCode == 200) {
      final jsonData = json.decode(res.body);
      return CurrencyRatesResponse.fromJson(jsonData);
    } else {
      throw Exception("Failed to fetch rates: ${res.statusCode}");
    }
  }

  static Future<List<Bank>> fetchBanks() async {
    print('Fetching banks');
    final uri = Uri.parse('$baseUrl/api/banks');
    final res = await http.get(uri, headers: {'x-api-key': apiKey});
    if (res.statusCode == 200) {
      final List jsonData = json.decode(res.body);
      return jsonData.map((e) => Bank.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch banks");
    }
  }

  static Future<BankRatesResponse> fetchBankRates(String bankCode) async {
    print('Fetching bank rates for bankCode: $bankCode');
    final uri = Uri.parse('$baseUrl/api/bank/$bankCode');
    final res = await http.get(uri, headers: {'x-api-key': apiKey});

    if (res.statusCode == 200) {
      final jsonData = json.decode(res.body);
      return BankRatesResponse.fromJson(jsonData);
    } else {
      throw Exception("Failed to fetch bank rates");
    }
  }
}
