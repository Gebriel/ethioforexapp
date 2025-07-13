import 'package:flutter/material.dart';
import '../models/bank_currency_rate.dart';
import '../models/bank_rates_response.dart';
import '../repositories/bank_repository.dart';
import '../widgets/bank_currency_rate_item.dart';
import '../helpers/adhelper_admob_convert_page.dart';

class ConvertScreen extends StatefulWidget {
  const ConvertScreen({super.key});

  @override
  State<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {
  final BankRepository _repository = BankRepository();

  String? selectedBankCode;
  String? selectedCurrencyCode;
  BankRatesResponse? bankRates;

  bool useTransaction = false;
  bool birrToForeign = true;
  final TextEditingController amountController = TextEditingController();
  double? convertedAmount;

  bool isLoading = true;
  bool hasLoadedOnce = false;
  String? errorMessage;

  // AdMob Native Ad Variable
  // Declare a nullable Widget to hold our ad.
  Widget? _nativeAdWidget;


  @override
  void initState() {
    super.initState();
    loadInitial();
    _initializeNativeAd(); // Initialize the ad here
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void _initializeNativeAd() {
    // Only create the ad widget once.
    _nativeAdWidget ??= AdMobNativeTemplateHelper.createNativeTemplateAdWidget();
  }

  Future<void> loadInitial({bool force = false}) async {
    if (!force && _repository.isInitialized && _repository.banks.isNotEmpty) {
      setState(() {
        hasLoadedOnce = true;
        errorMessage = null;
      });
      await loadRates(_repository.banks.first.bankCode);
      return;
    }

    if (!hasLoadedOnce) setState(() => isLoading = true);

    try {
      await _repository.initialize();
      if (_repository.banks.isNotEmpty) {
        // Ensure selectedBankCode is set before calling loadRates to avoid null issues
        selectedBankCode = _repository.banks.first.bankCode;
        await loadRates(selectedBankCode!);
      }
      setState(() {
        hasLoadedOnce = true;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        hasLoadedOnce = true;
        errorMessage = _getErrorMessage(e);
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadRates(String bankCode) async {
    // Only reload if the bank code is different or no rates are cached for this bank
    if (_repository.getCachedRates(bankCode) != null && bankCode == selectedBankCode) {
      setState(() {
        errorMessage = null;
        bankRates = _repository.getCachedRates(bankCode); // Ensure bankRates is updated from cache
        _updateCurrencySelection(); // Update currency selection when just reloading from cache
      });
      calculateConversion(); // Recalculate if rates are just re-set from cache
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _repository.getRates(bankCode);
      setState(() {
        selectedBankCode = bankCode;
        bankRates = result;
        isLoading = false;
        errorMessage = null;
        _updateCurrencySelection(); // Update currency selection after new rates fetch
      });
      calculateConversion();
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = _getErrorMessage(e);
      });
    }
  }

  // Helper to manage selectedCurrencyCode after rates change
  void _updateCurrencySelection() {
    final newCurrencyList = useTransaction ? bankRates!.transactionRates : bankRates!.cashRates;
    if (selectedCurrencyCode == null || !newCurrencyList.any((r) => r.currencyCode == selectedCurrencyCode)) {
      selectedCurrencyCode = newCurrencyList.isNotEmpty
          ? newCurrencyList.first.currencyCode
          : null;
    }
  }


  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException') ||
        error.toString().contains('NetworkException')) {
      return 'No internet connection. Please check your network and try again.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Request timeout. Please try again.';
    } else if (error.toString().contains('FormatException')) {
      return 'Invalid data received. Please try again.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  bool get hasValidData {
    return hasLoadedOnce &&
        errorMessage == null &&
        selectedBankCode != null &&
        bankRates != null;
  }

  Future<void> retry() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    await loadInitial(force: true);
  }

  void calculateConversion() {
    final input = double.tryParse(amountController.text);
    if (input == null || selectedCurrencyCode == null || bankRates == null) {
      setState(() => convertedAmount = null);
      return;
    }

    final validRates = useTransaction
        ? bankRates!.transactionRates.where((r) =>
    r.currencyCode == selectedCurrencyCode &&
        r.buying > 0 &&
        r.selling > 0)
        : bankRates!.cashRates.where((r) =>
    r.currencyCode == selectedCurrencyCode &&
        r.buying > 0 &&
        r.selling > 0);

    if (validRates.isEmpty) {
      setState(() => convertedAmount = null);
      return;
    }

    final rate = validRates.first;
    final result = birrToForeign
        ? input / rate.buying
        : input * rate.selling;

    setState(() => convertedAmount = result);
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Something went wrong',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: isLoading ? null : retry,
              icon: isLoading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.refresh),
              label: Text(isLoading ? 'Retrying...' : 'Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Currency Converter",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Bank Selector - Compact like HomeScreen
          if (hasValidData) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
                    items: _repository.banks.map((bank) {
                      return DropdownMenuItem<String>(
                        value: bank.bankCode,
                        child: Text(bank.bankName),
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
          ],

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _repository.forceRefresh();
                await loadInitial(force: true);
              },
              child: !hasLoadedOnce
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                  ? _buildErrorState()
                  : _buildMainContent(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme) {
    final cashRates = bankRates?.cashRates ?? [];
    if (cashRates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                "No exchange rates available for the selected bank or currency. Please try a different selection or check back later.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final selectedCash = cashRates.firstWhere(
          (r) => r.currencyCode == selectedCurrencyCode,
      orElse: () => cashRates.isNotEmpty ? cashRates.first :
      BankCurrencyRate(currencyCode: "N/A", currencyName: "No Data", buying: 0, selling: 0),
    );
    final txnRates = bankRates?.transactionRates ?? [];
    final selectedTxn = txnRates.firstWhere(
          (r) => r.currencyCode == selectedCurrencyCode,
      orElse: () => txnRates.isNotEmpty ? txnRates.first : selectedCash,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          // Currency & Options Card - More compact
          _buildCompactControlsCard(theme),
          const SizedBox(height: 12),

          // Result Card - Only show if there's a result
          if (convertedAmount != null && amountController.text.isNotEmpty)
            _buildCompactResultCard(theme),

          if (convertedAmount != null && amountController.text.isNotEmpty)
            const SizedBox(height: 12),

          // Ad Widget - positioned above BankCurrencyRateItem
          if (_nativeAdWidget != null && hasValidData) // Only show ad if we have valid data generally
            Padding(
              padding: const EdgeInsets.only(bottom: 12), // Spacing below ad
              child: _nativeAdWidget!, // Use the cached ad widget
            ),

          // Rates Card - More compact
          _buildCompactRatesCard(theme, selectedCash, selectedTxn),
        ],
      ),
    );
  }

  Widget _buildCompactControlsCard(ThemeData theme) {
    final cashRates = bankRates?.cashRates ?? [];
    final hasValidTxnRate = bankRates?.transactionRates.any((r) =>
    r.currencyCode == selectedCurrencyCode &&
        r.buying > 0 &&
        r.selling > 0) ?? false;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Currency Selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedCurrencyCode,
                  hint: const Text("Select Currency"),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: cashRates.map((c) {
                    return DropdownMenuItem<String>(
                      value: c.currencyCode,
                      child: Text("${c.currencyName} (${c.currencyCode})"),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => selectedCurrencyCode = val);
                    calculateConversion();
                  },
                ),
              ),
            ),
          ),

          // Amount Input & Direction Toggle in Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                // Amount Input
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: "0.00",
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        suffixText: birrToForeign ? "ETB" : selectedCurrencyCode ?? "",
                      ),
                      onChanged: (_) => calculateConversion(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Direction Toggle
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => birrToForeign = true);
                              calculateConversion();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: birrToForeign ? theme.colorScheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  "ETB→",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: birrToForeign
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => birrToForeign = false);
                              calculateConversion();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !birrToForeign ? theme.colorScheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  "→ETB",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: !birrToForeign
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Transaction Rate Toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Transaction Rate",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Switch.adaptive(
                  value: useTransaction,
                  onChanged: hasValidTxnRate
                      ? (val) {
                    setState(() => useTransaction = val);
                    calculateConversion();
                  }
                      : null,
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactResultCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Result",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            birrToForeign
                ? "${convertedAmount!.toStringAsFixed(2)} ${selectedCurrencyCode!}"
                : "${convertedAmount!.toStringAsFixed(2)} ETB",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRatesCard(ThemeData theme, BankCurrencyRate selectedCash, BankCurrencyRate selectedTxn) {
    return SizedBox(
      width: double.infinity,
      child: BankCurrencyRateItem(
        currencyName: selectedCash.currencyName,
        currencyCode: selectedCash.currencyCode,
        cashBuying: selectedCash.buying,
        cashSelling: selectedCash.selling,
        transactionBuying: selectedTxn.buying,
        transactionSelling: selectedTxn.selling,
      ),
    );
  }
}