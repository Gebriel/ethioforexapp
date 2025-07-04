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

  // Filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadPreferences();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<Map<String, dynamic>> _getFilteredRates() {
    final bankRates = selectedBankCode != null
        ? _repository.getCachedRates(selectedBankCode!)
        : null;
    final rates = bankRates?.cashRates ?? [];

    List<Map<String, dynamic>> rateData = rates.map((rate) {
      final txn = bankRates?.transactionRates.firstWhere(
            (t) => t.currencyCode == rate.currencyCode,
        orElse: () => rate,
      );

      return {
        'rate': rate,
        'txn': txn,
        'currencyName': rate.currencyName ?? '',
        'currencyCode': rate.currencyCode ?? '',
      };
    }).toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      rateData = rateData.where((item) {
        return item['currencyName'].toLowerCase().contains(query) ||
            item['currencyCode'].toLowerCase().contains(query);
      }).toList();
    }

    return rateData;
  }

  Widget _buildFilterBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Field
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search currencies...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bankRates = selectedBankCode != null
        ? _repository.getCachedRates(selectedBankCode!)
        : null;
    final filteredRates = _getFilteredRates();

    Bank? selectedBank;
    if (selectedBankCode != null && _repository.banks.isNotEmpty) {
      selectedBank = _repository.banks.firstWhere(
            (b) => b.bankCode == selectedBankCode,
        orElse: () => Bank(bankCode: '', bankName: '', bankLogo: ''),
      );
    }
    final logoUrl = selectedBank?.bankLogo ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Banks Overview",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Bank Selector
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

          if (hasLoadedOnce && filteredRates.isNotEmpty) _buildFilterBar(),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _repository.forceRefresh();
                await loadInitialData(force: true);
              },
              child: !hasLoadedOnce
                  ? const Center(child: CircularProgressIndicator())
                  : filteredRates.isEmpty
                  ? const Center(child: Text("No rates available."))
                  : CustomScrollView(
                slivers: [
                  if (logoUrl.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
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
                    ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final item = filteredRates[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          child: BankCurrencyRateItem(
                            currencyName: item['currencyName'],
                            currencyCode: item['currencyCode'],
                            cashBuying: item['rate'].buying ?? 0.0,
                            cashSelling: item['rate'].selling ?? 0.0,
                            transactionBuying: item['txn']?.buying ?? 0.0,
                            transactionSelling: item['txn']?.selling ?? 0.0,
                            updated: bankRates?.updated ?? DateTime.now(),
                          ),
                        );
                      },
                      childCount: filteredRates.length,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
