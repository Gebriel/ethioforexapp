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
  String? errorMessage; // Add error state

  // Filter and Sort variables
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'buying', 'selling', 'updated'
  bool _sortAscending = true;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchActive = _searchFocusNode.hasFocus;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadPreferences();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
      setState(() {
        hasLoadedOnce = true;
        errorMessage = null; // Clear any previous errors
      });
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
        errorMessage = null; // Clear error on success
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasLoadedOnce = true;
        errorMessage = _getErrorMessage(e); // Set error message
      });
    }
  }

  Future<void> fetchRates(String code) async {
    if (_repository.getCachedRates(code) != null) {
      setState(() {
        selectedCurrency = code;
        errorMessage = null; // Clear error when using cached data
      });
      await saveCurrencyPreference(code);
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null; // Clear previous errors
    });

    try {
      await _repository.getRates(code);
      setState(() {
        selectedCurrency = code;
        isLoading = false;
        errorMessage = null; // Clear error on success
      });
      await saveCurrencyPreference(code);
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = _getErrorMessage(e); // Set error message
      });
    }
  }

  // Helper method to get user-friendly error messages
  String _getErrorMessage(dynamic error) {
    // You can customize this based on your specific error types
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
        selectedCurrency != null &&
        _repository.getCachedRates(selectedCurrency!) != null;
  }

  // Retry method
  Future<void> retry() async {
    setState(() {
      isLoading = true;
      errorMessage = null; // Clear error when retrying
    });
    await fetchInitialData(force: true);
  }

  // Filter and Sort methods
  List<dynamic> _getFilteredAndSortedRates() {
    final currencies = _repository.currencies;
    final currencyRates = selectedCurrency != null ? _repository.getCachedRates(selectedCurrency!) : null;
    final rates = currencyRates?.cashRates ?? [];

    // Create list with all necessary data for filtering/sorting
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

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      rateData = rateData.where((item) {
        final bankName = item['bankName'].toString().toLowerCase();
        final bankCode = item['bankCode'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return bankName.contains(query) || bankCode.contains(query);
      }).toList();
    }

    // Sort the data
    rateData.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a['bankName'].toString().compareTo(b['bankName'].toString());
          break;
        case 'buying':
          comparison = (a['cashBuying'] as double).compareTo(b['cashBuying'] as double);
          break;
        case 'selling':
          comparison = (a['cashSelling'] as double).compareTo(b['cashSelling'] as double);
          break;
        case 'updated':
          comparison = (a['updatedAt'] as DateTime).compareTo(b['updatedAt'] as DateTime);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Filter banks...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: colorScheme.onSurfaceVariant,
                  ),
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

          // Sort Section - Always visible
          const SizedBox(height: 16),

          // Sort Options - Dynamic Layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.sort,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Sort',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildCompactSortChip('name', 'Name', Icons.account_balance),
                    _buildCompactSortChip('buying', 'Buy', Icons.trending_up),
                    _buildCompactSortChip('selling', 'Sell', Icons.trending_down),
                    _buildCompactSortChip('updated', 'Time', Icons.schedule),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() => _sortAscending = !_sortAscending);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSortChip(String value, String label, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _sortBy == value;

    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.1)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
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
    final currencies = _repository.currencies;
    final filteredRates = hasValidData ? _getFilteredAndSortedRates() : [];

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
        backgroundColor: theme.colorScheme.surface,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Currency Selector - Only show when we have valid data
          if (hasValidData) ...[
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
          ],

          // Filter and Sort Bar - Only show when we have valid data
          if (hasValidData && filteredRates.isNotEmpty)
            _buildFilterBar(),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _repository.forceRefresh();
                await fetchInitialData(force: true);
              },
              child: !hasLoadedOnce
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                  ? _buildErrorState() // Show error state
                  : filteredRates.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _searchQuery.isNotEmpty ? Icons.search_off : Icons.account_balance,
                      size: 64,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty
                          ? "No banks found matching '$_searchQuery'"
                          : "No exchange rates found.",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Text('Clear search'),
                      ),
                    ],
                  ],
                ),
              )
                  : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: filteredRates.map((item) {
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
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}