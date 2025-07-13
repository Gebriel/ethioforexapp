import 'package:flutter/material.dart';
import '../models/bank.dart';
import '../repositories/currency_repository.dart';
import '../widgets/rate_list_item.dart';
import '../helpers/adhelper_admob_summary_page.dart'; // Add this import for the ad helper

class UsdSummaryScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const UsdSummaryScreen({super.key, this.onBackPressed});

  @override
  State<UsdSummaryScreen> createState() => _UsdSummaryScreenState();
}

class _UsdSummaryScreenState extends State<UsdSummaryScreen> {
  final CurrencyRepository _repository = CurrencyRepository();
  static const String _fixedCurrency = 'USD';
  bool isLoading = false;
  bool hasLoadedOnce = false;
  String? errorMessage;

  // AdMob Native Ad Variable
  Widget? _nativeAdWidget;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchUsdRates();
      _initializeNativeAd(); // Initialize the ad
    });
  }

  @override
  void dispose() {
    // Clean up ad resources if needed
    super.dispose();
  }

  void _initializeNativeAd() {
    // Only create the ad widget once
    _nativeAdWidget ??= AdMobNativeTemplateHelper.createNativeTemplateAdWidget();
  }

  Future<void> fetchUsdRates({bool force = false}) async {
    if (!force &&
        _repository.isInitialized &&
        _repository.getCachedRates(_fixedCurrency) != null) {
      setState(() {
        hasLoadedOnce = true;
        errorMessage = null;
      });
      return;
    }

    if (!hasLoadedOnce) setState(() => isLoading = true);

    try {
      await _repository.initialize();
      await _repository.getRates(_fixedCurrency);

      setState(() {
        isLoading = false;
        hasLoadedOnce = true;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasLoadedOnce = true;
        errorMessage = _getErrorMessage(e);
      });
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
        _repository.getCachedRates(_fixedCurrency) != null;
  }

  Future<void> retry() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    await fetchUsdRates(force: true);
  }

  List<Map<String, dynamic>> _getSortedRatesByLatest() {
    final currencyRates = _repository.getCachedRates(_fixedCurrency);
    final rates = currencyRates?.cashRates ?? [];

    List<Map<String, dynamic>> rateData = rates.map((r) {
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

      return {
        'rate': r,
        'txn': txn,
        'bank': bank,
        'bankName': r.bankName,
        'bankLogo': bank?.bankLogo ?? '',
        'bankCode': r.bankCode,
        'cashBuying': r.buying,
        'cashSelling': r.selling,
        'transactionBuying': txn.buying,
        'transactionSelling': txn.selling,
        'updatedAt': r.updatedAt,
      };
    }).toList();

    // Sort by latest updated first
    rateData.sort((a, b) {
      return (b['updatedAt'] as DateTime).compareTo(a['updatedAt'] as DateTime);
    });

    return rateData;
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

  Widget _buildSummaryHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rates = _getSortedRatesByLatest();

    if (rates.isEmpty) return const SizedBox.shrink();

    // Get the latest update time
    final latestUpdate = rates.first['updatedAt'] as DateTime;
    final now = DateTime.now();
    final difference = now.difference(latestUpdate);

    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      timeAgo = 'Just now';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_money,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'USD Exchange Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: colorScheme.onSurfaceVariant,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Latest update: $timeAgo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${rates.length} banks',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleBackPress() {
    if (widget.onBackPressed != null) {
      widget.onBackPressed!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedRates = hasValidData ? _getSortedRatesByLatest() : [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "USD Summary",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBackPress,
        ),
        actions: [
          if (hasValidData)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => fetchUsdRates(force: true),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _repository.forceRefresh();
          await fetchUsdRates(force: true);
        },
        child: !hasLoadedOnce
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? _buildErrorState()
            : sortedRates.isEmpty
            ? Center(
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
                "No USD exchange rates found.",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        )
            : ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // Summary header as first item in the scrollable list
            _buildSummaryHeader(),
            // Add the ad widget here, as part of the scrollable content
            if (_nativeAdWidget != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _nativeAdWidget!,
              ),
            ],
            // Rate list items
            ...sortedRates.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RateListItem(
                  bankName: item['bankName'],
                  bankLogo: item['bankLogo'],
                  bankCode: item['bankCode'],
                  cashBuying: item['cashBuying'],
                  cashSelling: item['cashSelling'],
                  transactionBuying: item['transactionBuying'],
                  transactionSelling: item['transactionSelling'],
                  updatedAt: item['updatedAt'],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}