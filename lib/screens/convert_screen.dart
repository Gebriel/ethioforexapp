import 'package:flutter/material.dart';
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
    } catch (_) {}
    setState(() => isLoading = false);
  }

  Future<void> loadRates(String bankCode) async {
    final result = await _repository.getRates(bankCode);
    setState(() {
      selectedBankCode = bankCode;
      bankRates = result;
      selectedCurrencyCode = result.cashRates.isNotEmpty
          ? result.cashRates.first.currencyCode
          : null;
    });
    calculateConversion();
  }

  void calculateConversion() {
    final input = double.tryParse(amountController.text);
    if (input == null || selectedCurrencyCode == null || bankRates == null) {
      setState(() => convertedAmount = null);
      return;
    }

    final rateList = useTransaction
        ? bankRates!.transactionRates
        : bankRates!.cashRates;

    if (rateList.isEmpty) {
      setState(() => convertedAmount = null);
      return;
    }

    final rate = rateList.firstWhere(
          (r) => r.currencyCode == selectedCurrencyCode,
      orElse: () => rateList.first,
    );

    double result;
    if (birrToForeign) {
      result = input / rate.buying;
    } else {
      result = input * rate.selling;
    }

    setState(() => convertedAmount = result);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Currency Converter")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final cashRates = bankRates?.cashRates ?? [];
    final txnRates = bankRates?.transactionRates ?? [];

    final selectedCash = cashRates.firstWhere(
          (r) => r.currencyCode == selectedCurrencyCode,
      orElse: () => cashRates.first,
    );
    final selectedTxn = txnRates.firstWhere(
          (r) => r.currencyCode == selectedCurrencyCode,
      orElse: () => selectedCash,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Currency Converter")),
      body: cashRates.isEmpty
          ? const Center(child: Text("No exchange rates available."))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              isExpanded: true,
              value: selectedBankCode,
              items: _repository.banks.map((b) {
                return DropdownMenuItem(
                  value: b.bankCode,
                  child: Text(b.bankName),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) loadRates(val);
              },
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedCurrencyCode,
              items: cashRates.map((c) {
                return DropdownMenuItem(
                  value: c.currencyCode,
                  child: Text("${c.currencyName} (${c.currencyCode})"),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => selectedCurrencyCode = val);
                calculateConversion();
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("Use Transaction Rate"),
                Switch(
                  value: useTransaction,
                  onChanged: (val) => setState(() {
                    useTransaction = val;
                    calculateConversion();
                  }),
                ),
              ],
            ),
            Row(
              children: [
                const Text("Birr → Foreign"),
                Switch(
                  value: birrToForeign,
                  onChanged: (val) => setState(() {
                    birrToForeign = val;
                    calculateConversion();
                  }),
                ),
              ],
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter amount",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => calculateConversion(),
            ),
            const SizedBox(height: 16),
            if (convertedAmount != null)
              Text(
                birrToForeign
                    ? "≈ ${convertedAmount!.toStringAsFixed(2)} ${selectedCurrencyCode!}"
                    : "≈ ${convertedAmount!.toStringAsFixed(2)} ETB",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
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
      ),
    );
  }
}
