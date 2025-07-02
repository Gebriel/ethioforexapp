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

  @override
  void initState() {
    super.initState();
    loadInitial();
  }

  Future<void> loadInitial() async {
    try {
      await _repository.initialize();
      if (_repository.banks.isNotEmpty) {
        await loadRates(_repository.banks.first.bankCode);
      }
    } catch (_) {
      // Consider adding a visual error feedback (e.g., snackbar) here
      debugPrint("Error loading initial data:");
    }
    setState(() => isLoading = false);
  }

  Future<void> loadRates(String bankCode) async {
    // Show a temporary loading state for rates if needed, or rely on existing isLoading
    final result = await _repository.getRates(bankCode);
    setState(() {
      selectedBankCode = bankCode;
      bankRates = result;
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
        backgroundColor: theme.colorScheme.surface, // AppBar is also a 'surface' element
        automaticallyImplyLeading: false, // You can set this to true if you add a drawer/back button
      ),
      body: _buildMainContent(theme),
    );
  }

  Widget _buildMainContent(ThemeData theme) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)); // Use primary color for loading
    }

    final cashRates = bankRates?.cashRates ?? [];
    if (cashRates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            "No exchange rates available for the selected bank or currency. Please try a different selection or check back later.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.7)),
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
      orElse: () => txnRates.isNotEmpty ? txnRates.first : selectedCash, // Fallback to cash if no txn rate
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
          _buildRatesCard(theme, selectedCash, selectedTxn), // Pass rates here
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
        color: theme.colorScheme.surface, // Card background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08), // Soft shadow
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Adjusted vertical padding
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest, // Use this for distinct textbox-like background
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Use Transaction Rate",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant, // Use secondary text color
                  ),
                ),
                Switch.adaptive( // Use adaptive for platform specific look
                  value: useTransaction,
                  onChanged: hasValidTxnRate
                      ? (val) {
                    setState(() => useTransaction = val);
                    calculateConversion();
                  }
                      : null,
                  activeColor: theme.colorScheme.primary, // Green accent
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Amount Input - Make it look like a text box
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
                    color: theme.colorScheme.onSurface.withOpacity(0.4), // Lighter hint
                  ),
                  filled: true, // Crucial for background color
                  fillColor: theme.colorScheme.surfaceContainerHighest, // Use for background
                  border: OutlineInputBorder( // Define border for a box look
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none, // No actual line border, rely on fill color
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16, // Consistent padding
                  ),
                  suffixText: birrToForeign ? "ETB" : selectedCurrencyCode ?? "",
                  suffixStyle: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withOpacity(0.7), // Suffix also prominent
                  ),
                ),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface, // Main input text color
                ),
                onChanged: (_) => calculateConversion(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Conversion Direction Toggle - Make it look like a segmented control/tab
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
                  color: theme.colorScheme.surfaceContainerHighest, // Background of the segmented control
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4), // Padding around the two buttons
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => birrToForeign = true);
                          calculateConversion();
                        },
                        child: AnimatedContainer( // Use AnimatedContainer for smooth color transition
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: birrToForeign
                                ? theme.colorScheme.primary // Active button color
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              "ETB → ${selectedCurrencyCode ?? ""}",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: birrToForeign
                                    ? theme.colorScheme.onPrimary // Text color for active button
                                    : theme.colorScheme.onSurfaceVariant, // Text color for inactive
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8), // Space between buttons
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => birrToForeign = false);
                          calculateConversion();
                        },
                        child: AnimatedContainer( // Use AnimatedContainer for smooth color transition
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !birrToForeign
                                ? theme.colorScheme.primary // Active button color
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              "${selectedCurrencyCode ?? ""} → ETB",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: !birrToForeign
                                    ? theme.colorScheme.onPrimary // Text color for active button
                                    : theme.colorScheme.onSurfaceVariant, // Text color for inactive
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

  // Modified _buildDropdown to use a distinct background
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
            color: theme.colorScheme.onSurfaceVariant, // Use secondary text color
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surfaceContainerHighest, // Distinct background for dropdown
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface, // Text color for dropdown value
              ),
              dropdownColor: theme.colorScheme.surface, // Dropdown menu background
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.onSurfaceVariant), // Icon color
              items: List.generate(itemValues.length, (index) {
                return DropdownMenuItem(
                  value: itemValues[index],
                  child: Text(
                    itemLabels[index],
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface, // Text color for dropdown items
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
        crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
        children: [
          Text(
            "Converted Amount",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant, // Secondary text color
            ),
          ),
          const SizedBox(height: 8),
          Text(
            birrToForeign
                ? "${convertedAmount!.toStringAsFixed(2)} ${selectedCurrencyCode!}"
                : "${convertedAmount!.toStringAsFixed(2)} ETB",
            style: theme.textTheme.displaySmall?.copyWith( // Use displaySmall for large number
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary, // Highlight with primary (green)
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
          // BankCurrencyRateItem already designed to fit this style
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