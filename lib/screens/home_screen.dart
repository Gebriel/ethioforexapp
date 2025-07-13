import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/adhelper_admob.dart'; // Assuming this provides the ad creation
import '../models/bank.dart';
import '../repositories/currency_repository.dart';
import '../widgets/rate_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final CurrencyRepository _repository = CurrencyRepository();
  static const String _currencyPrefKey = 'selected_currency';
  String? selectedCurrency;
  bool isLoading = false;
  bool hasLoadedOnce = false;
  String? errorMessage;

  // Filter and Sort variables
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;
  bool _isFilterVisible = false;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  // AdMob Native Ad Variable
  // Declare a nullable Widget to hold our ad.
  Widget? _nativeAdWidget;

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );


    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadPreferences();
      _initializeNativeAd(); // Initialize the ad here
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _filterAnimationController.dispose();
    // It's good practice to dispose of ad resources if the helper supports it.
    // Assuming AdMobNativeTemplateHelper manages its own ad lifecycle,
    // we don't need to explicitly dispose _nativeAdWidget here, as it's just a reference.
    super.dispose();
  }

  void _initializeNativeAd() {
    // Only create the ad widget once.
    _nativeAdWidget ??= AdMobNativeTemplateHelper.createNativeTemplateAdWidget();
  }

  void _toggleFilter() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
    });
    if (_isFilterVisible) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
      _searchFocusNode.unfocus(); // Hide keyboard when closing filter
    }
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
        errorMessage = null;
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

  Future<void> fetchRates(String code) async {
    if (_repository.getCachedRates(code) != null) {
      setState(() {
        selectedCurrency = code;
        errorMessage = null;
      });
      await saveCurrencyPreference(code);
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _repository.getRates(code);
      setState(() {
        selectedCurrency = code;
        isLoading = false;
        errorMessage = null;
      });
      await saveCurrencyPreference(code);
    } catch (e) {
      setState(() {
        isLoading = false;
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
        selectedCurrency != null &&
        _repository.getCachedRates(selectedCurrency!) != null;
  }

  Future<void> retry() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    await fetchInitialData(force: true);
  }

  List<dynamic> _getFilteredAndSortedRates() {
    final currencyRates = selectedCurrency != null ? _repository.getCachedRates(selectedCurrency!) : null;
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

    if (_searchQuery.isNotEmpty) {
      rateData = rateData.where((item) {
        final bankName = item['bankName'].toString().toLowerCase();
        final bankCode = item['bankCode'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return bankName.contains(query) || bankCode.contains(query);
      }).toList();
    }

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

  Widget _buildCompactFilterBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _filterAnimation,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _filterAnimation,
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // This is key - only take needed space
                children: [
                  // Search Bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Search banks...',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sort Section
                  Row(
                    children: [
                      Icon(
                        Icons.sort,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sort by:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildSortChip('name', 'Name', Icons.account_balance),
                              const SizedBox(width: 6),
                              _buildSortChip('buying', 'Buy', Icons.trending_up),
                              const SizedBox(width: 6),
                              _buildSortChip('selling', 'Sell', Icons.trending_down),
                              const SizedBox(width: 6),
                              _buildSortChip('updated', 'Updated', Icons.schedule),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() => _sortAscending = !_sortAscending);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortChip(String value, String label, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _sortBy == value;

    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterStatusBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasActiveFilters = _searchQuery.isNotEmpty || _sortBy != 'name' || !_sortAscending;

    if (!hasActiveFilters) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _buildFilterSummary(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty || _sortBy != 'name' || !_sortAscending)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _sortBy = 'name';
                  _sortAscending = true;
                });
              },
              child: Icon(
                Icons.clear,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  String _buildFilterSummary() {
    List<String> filters = [];
    if (_searchQuery.isNotEmpty) {
      filters.add('Search: "$_searchQuery"');
    }
    if (_sortBy != 'name') {
      String sortLabel = _sortBy == 'buying' ? 'Buy' :
      _sortBy == 'selling' ? 'Sell' :
      _sortBy == 'updated' ? 'Updated' : 'Name';
      filters.add('Sort: $sortLabel ${_sortAscending ? '↑' : '↓'}');
    } else if (!_sortAscending) {
      filters.add('Sort: Name ↓');
    }
    return filters.join(' • ');
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
      floatingActionButton: hasValidData && filteredRates.isNotEmpty
          ? FloatingActionButton(
        onPressed: _toggleFilter,
        child: AnimatedRotation(
          turns: _isFilterVisible ? 0.5 : 0,
          duration: const Duration(milliseconds: 300),
          child: Icon(_isFilterVisible ? Icons.close : Icons.tune),
        ),
      )
          : null,
      body: Column(
        children: [
          // Currency Selector
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

          // Filter Status Bar
          if (hasValidData && filteredRates.isNotEmpty)
            _buildFilterStatusBar(),

          // Animated Filter Bar
          if (hasValidData && filteredRates.isNotEmpty)
            _buildCompactFilterBar(),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _repository.forceRefresh();
                await fetchInitialData(force: true);
                // After a refresh, you might want to re-check if the ad needs to be loaded.
                // However, if the ad is designed to persist, you might not need to re-initialize it here.
                // For simplicity, we'll keep the ad initialized once in initState.
              },
              child: !hasLoadedOnce
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                  ? _buildErrorState()
                  : filteredRates.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _searchQuery.isNotEmpty ? Icons.search_off : Icons.account_balance,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty
                          ? "No banks found matching '$_searchQuery'"
                          : "No exchange rates found.",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                children: [
                  // Ad Widget - positioned at the top of the rate list
                  // Use the stored _nativeAdWidget here
                  if (filteredRates.isNotEmpty && _nativeAdWidget != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _nativeAdWidget!, // Use the cached ad widget
                    ),
                  ],
                  // Rate List Items
                  ...filteredRates.map((item) {
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
          ),
        ],
      ),
    );
  }
}