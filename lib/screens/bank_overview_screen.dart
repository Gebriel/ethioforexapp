// ✅ lib/screens/bank_overview_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bank_rates_response.dart';
import '../repositories/bank_repository.dart';
import '../widgets/bank_currency_rate_item.dart';

class BankOverviewScreen extends StatefulWidget {
  const BankOverviewScreen({super.key});

  @override
  State<BankOverviewScreen> createState() => _BankOverviewScreenState();
}

class _BankOverviewScreenState extends State<BankOverviewScreen> {
  final BankRepository _repository = BankRepository();
  static const String _bankPrefKey = 'selected_bank';
  String? selectedBankCode;
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
    selectedBankCode = prefs.getString(_bankPrefKey) ?? 'CBET';
    loadInitialData();
  }

  Future<void> saveBankPreference(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bankPrefKey, code);
  }

  Future<void> loadInitialData({bool force = false}) async {
    if (!force && _repository.isInitialized && selectedBankCode != null && _repository.getCachedRates(selectedBankCode!) != null) {
      setState(() => hasLoadedOnce = true);
      return;
    }

    if (!hasLoadedOnce) setState(() => isLoading = true);

    try {
      await _repository.initialize();
      final defaultCode = _repository.banks.any((b) => b.bankCode == selectedBankCode)
          ? selectedBankCode!
          : _repository.banks.first.bankCode;

      await _repository.getRates(defaultCode);

      setState(() {
        selectedBankCode = defaultCode;
        isLoading = false;
        hasLoadedOnce = true;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
        hasLoadedOnce = true;
      });
    }
  }

  Future<void> loadRates(String bankCode) async {
    if (_repository.getCachedRates(bankCode) != null) {
      setState(() => selectedBankCode = bankCode);
      await saveBankPreference(bankCode);
      return;
    }

    setState(() => isLoading = true);
    try {
      await _repository.getRates(bankCode);
      setState(() {
        selectedBankCode = bankCode;
        isLoading = false;
      });
      await saveBankPreference(bankCode);
    } catch (e) {
      print("Error loading rates: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bankRates = selectedBankCode != null ? _repository.getCachedRates(selectedBankCode!) : null;
    final rates = bankRates?.cashRates ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Banks Overview"),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedBankCode,
              items: _repository.banks.map((b) {
                return DropdownMenuItem<String>(
                  value: b.bankCode,
                  child: Text(b.bankName),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  loadRates(val);
                }
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _repository.forceRefresh();
                await loadInitialData(force: true);
              },
              child: !hasLoadedOnce
                  ? const Center(child: CircularProgressIndicator())
                  : rates.isEmpty
                  ? const Center(child: Text("No rates available."))
                  : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: rates.map((r) {
                  final txn = bankRates!.transactionRates.firstWhere(
                        (t) => t.currencyCode == r.currencyCode,
                    orElse: () => r,
                  );
                  return BankCurrencyRateItem(
                    currencyName: r.currencyName,
                    currencyCode: r.currencyCode,
                    cashBuying: r.buying,
                    cashSelling: r.selling,
                    transactionBuying: txn.buying,
                    transactionSelling: txn.selling,
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
