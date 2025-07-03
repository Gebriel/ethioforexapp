import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bank.dart';
import '../repositories/currency_repository.dart';
import '../widgets/rate_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CurrencyRepository _repository = CurrencyRepository();
  static const String _currencyPrefKey = 'selected_currency';
  String? selectedCurrency;
  bool isLoading = false;
  bool hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadPreferences();
    });
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    selectedCurrency = prefs.getString(_currencyPrefKey) ?? 'USD';
    fetchInitialData();
  }

  Future<void> saveCurrencyPreference(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyPrefKey, code);
  }

  Future<void> fetchInitialData({bool force = false}) async {
    if (!force &&
        _repository.isInitialized &&
        selectedCurrency != null &&
        _repository.getCachedRates(selectedCurrency!) != null) {
      setState(() => hasLoadedOnce = true);
      return;
    }

    if (!hasLoadedOnce) setState(() => isLoading = true);

    try {
      await _repository.initialize();
      final defaultCode = _repository.currencies.any((c) => c.currencyCode == selectedCurrency)
          ? selectedCurrency!
          : _repository.currencies.first.currencyCode;

      await _repository.getRates(defaultCode);

      setState(() {
        selectedCurrency = defaultCode;
        isLoading = false;
        hasLoadedOnce = true;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasLoadedOnce = true;
      });
    }
  }

  Future<void> fetchRates(String code) async {
    if (_repository.getCachedRates(code) != null) {
      setState(() => selectedCurrency = code);
      await saveCurrencyPreference(code);
      return;
    }

    setState(() => isLoading = true);
    try {
      await _repository.getRates(code);
      setState(() {
        selectedCurrency = code;
        isLoading = false;
      });
      await saveCurrencyPreference(code);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencies = _repository.currencies;
    final currencyRates = selectedCurrency != null ? _repository.getCachedRates(selectedCurrency!) : null;
    final rates = currencyRates?.cashRates ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "EthioForex",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface, // AppBar is also a 'surface' element
        automaticallyImplyLeading: false, // You can set this to true if you add a drawer/back button
      ),
      body: Column(
        children: [
          // Currency Selector - Now matches BankOverviewScreen exactly
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedCurrency,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: currencies.map((c) {
                    return DropdownMenuItem<String>(
                      value: c.currencyCode,
                      child: Text("${c.currencyName} (${c.currencyCode})"),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      fetchRates(val);
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _repository.forceRefresh();
                await fetchInitialData(force: true);
              },
              child: !hasLoadedOnce
                  ? const Center(child: CircularProgressIndicator())
                  : rates.isEmpty
                  ? const Center(child: Text("No exchange rates found."))
                  : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: rates.map((r) {
                  final txn = currencyRates!.transactionRates.firstWhere(
                        (t) => t.bankCode == r.bankCode,
                    orElse: () => r,
                  );

                  Bank? bank;
                  try {
                    bank = _repository.banks.firstWhere((b) => b.bankCode == r.bankCode);
                  } catch (_) {
                    bank = null;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RateListItem(
                      bankName: r.bankName,
                      bankLogo: bank?.bankLogo ?? '',
                      bankCode: r.bankCode,
                      cashBuying: r.buying,
                      cashSelling: r.selling,
                      transactionBuying: txn.buying,
                      transactionSelling: txn.selling,
                      updatedAt: r.updatedAt,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}