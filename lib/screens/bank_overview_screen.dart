import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bank.dart';
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
    if (!force &&
        _repository.isInitialized &&
        selectedBankCode != null &&
        _repository.getCachedRates(selectedBankCode!) != null) {
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
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bankRates = selectedBankCode != null ? _repository.getCachedRates(selectedBankCode!) : null;
    final rates = bankRates?.cashRates ?? [];

    // Get logo URL of selected bank
    final selectedBank = selectedBankCode != null
        ? _repository.banks.firstWhere(
          (b) => b.bankCode == selectedBankCode,
      orElse: () => Bank(bankCode: '', bankName: '', bankLogo: ''),
    )
        : null;
    final logoUrl = selectedBank?.bankLogo ?? '';

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
                  value: selectedBankCode,
                  icon: const Icon(Icons.keyboard_arrow_down),
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
            ),
          ),
          const SizedBox(height: 16),
          if (logoUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    logoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 6),
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
