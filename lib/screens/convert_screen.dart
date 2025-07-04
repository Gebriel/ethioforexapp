import 'package:flutter/material.dart';
import '../models/bank_currency_rate.dart';
import '../models/bank_rates_response.dart';
import '../repositories/bank_repository.dart';
import '../widgets/bank_currency_rate_item.dart';

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
  String? errorMessage; // Add error state

  @override
  void initState() {
    super.initState();
    loadInitial();
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
        await loadRates(_repository.banks.first.bankCode);
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
    // Check if we have cached rates for this bank
    if (_repository.getCachedRates(bankCode) != null && bankCode == selectedBankCode) {
      setState(() => errorMessage = null);
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

        // Ensure selectedCurrencyCode defaults to first available if current isn't in new bank's rates
        final newCurrencyList = useTransaction ? result.transactionRates : result.cashRates;
        if (selectedCurrencyCode == null || !newCurrencyList.any((r) => r.currencyCode == selectedCurrencyCode)) {
          selectedCurrencyCode = newCurrencyList.isNotEmpty
              ? newCurrencyList.first.currencyCode
              : null;
        }
        useTransaction = false; // Reset transaction toggle when bank changes
      });
      calculateConversion();
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = _getErrorMessage(e);
      });
    }
  }

  // Helper method to get user-friendly error messages
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

  // Check if we have valid data to show
  bool get hasValidData {
    return hasLoadedOnce &&
        errorMessage == null &&
        selectedBankCode != null &&
        bankRates != null;
  }

  // Retry method
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

  // Build error state widget
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
                color: colorScheme.onSurface.withOpacity(0.7),
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
      backgroundColor: theme.colorScheme.background,
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
      body: RefreshIndicator(
        onRefresh: () async {
          await _repository.forceRefresh();
          await loadInitial(force: true);
        },
        child: !hasLoadedOnce || isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? _buildErrorState()
            : _buildMainContent(theme),
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
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                "No exchange rates available for the selected bank or currency. Please try a different selection or check back later.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
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

    // Ensure selectedCash and selectedTxn are valid before passing to BankCurrencyRateItem
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildConversionCard(theme),
          const SizedBox(height: 16),
          // Only show result card if there's a converted amount
          if (convertedAmount != null && amountController.text.isNotEmpty) _buildResultCard(theme),
          const SizedBox(height: 16),
          _buildRatesCard(theme, selectedCash, selectedTxn),
        ],
      ),
    );
  }

  Widget _buildConversionCard(ThemeData theme) {
    final cashRates = bankRates?.cashRates ?? [];
    final hasValidTxnRate = bankRates?.transactionRates.any((r) =>
    r.currencyCode == selectedCurrencyCode &&
        r.buying > 0 &&
        r.selling > 0) ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bank Selector
          _buildDropdown(
            context,
            "Select Bank",
            selectedBankCode,
            _repository.banks.map((b) => b.bankCode).toList(),
            _repository.banks.map((b) => b.bankName).toList(),
                (val) {
              if (val != null) {
                loadRates(val);
              }
            },
          ),
          const SizedBox(height: 16),

          // Currency Selector
          _buildDropdown(
            context,
            "Select Currency",
            selectedCurrencyCode,
            cashRates.map((c) => c.currencyCode).toList(),
            cashRates.map((c) => "${c.currencyName} (${c.currencyCode})").toList(),
                (val) {
              setState(() => selectedCurrencyCode = val);
              calculateConversion();
            },
          ),
          const SizedBox(height: 16),

          // Transaction Rate Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Use Transaction Rate",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
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
          const SizedBox(height: 16),

          // Amount Input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                birrToForeign ? "Amount in ETB" : "Amount in ${selectedCurrencyCode ?? 'Foreign'}",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: "0.00",
                  hintStyle: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  suffixText: birrToForeign ? "ETB" : selectedCurrencyCode ?? "",
                  suffixStyle: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                onChanged: (_) => calculateConversion(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Conversion Direction Toggle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Conversion Direction",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => birrToForeign = true);
                          calculateConversion();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: birrToForeign
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              "ETB → ${selectedCurrencyCode ?? ""}",
                              style: theme.textTheme.bodyMedium?.copyWith(
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => birrToForeign = false);
                          calculateConversion();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !birrToForeign
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              "${selectedCurrencyCode ?? ""} → ETB",
                              style: theme.textTheme.bodyMedium?.copyWith(
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
      BuildContext context,
      String label,
      String? value,
      List<String> itemValues,
      List<String> itemLabels,
      ValueChanged<String?> onChanged,
      ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              dropdownColor: theme.colorScheme.surface,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.onSurfaceVariant),
              items: List.generate(itemValues.length, (index) {
                return DropdownMenuItem(
                  value: itemValues[index],
                  child: Text(
                    itemLabels[index],
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                );
              }),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Converted Amount",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            birrToForeign
                ? "${convertedAmount!.toStringAsFixed(2)} ${selectedCurrencyCode!}"
                : "${convertedAmount!.toStringAsFixed(2)} ETB",
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatesCard(ThemeData theme, BankCurrencyRate selectedCash, BankCurrencyRate selectedTxn) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          BankCurrencyRateItem(
            currencyName: selectedCash.currencyName,
            currencyCode: selectedCash.currencyCode,
            cashBuying: selectedCash.buying,
            cashSelling: selectedCash.selling,
            transactionBuying: selectedTxn.buying,
            transactionSelling: selectedTxn.selling,
          ),
        ],
      ),
    );
  }
}