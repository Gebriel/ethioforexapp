import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bank.dart';
import '../models/history_rates_response.dart';
import '../repositories/bank_repository.dart';
import '../repositories/usd_history_repository.dart';
import '../widgets/bank_currency_rate_item.dart';
import '../widgets/usd_history_chart.dart';

class BankOverviewScreen extends StatefulWidget {
  const BankOverviewScreen({super.key});

  @override
  State<BankOverviewScreen> createState() => _BankOverviewScreenState();
}

class _BankOverviewScreenState extends State<BankOverviewScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final BankRepository _repository = BankRepository();
  final UsdHistoryRepository _usdHistoryRepository = UsdHistoryRepository();
  static const String _bankPrefKey = 'selected_bank';
  String? selectedBankCode;
  bool isLoading = false;
  bool hasLoadedOnce = false;
  String? errorMessage;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearchActive = false;
  bool _isFilterVisible = false;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  HistoryRatesResponse? usdHistory;
  bool isUsdLoading = false;

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
    _filterAnimationController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _toggleFilter() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
    });
    if (_isFilterVisible) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
      _searchFocusNode.unfocus();
    }
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
      setState(() {
        hasLoadedOnce = true;
        errorMessage = null;
      });
      await _maybeFetchUsdHistory(selectedBankCode!);
      return;
    }

    if (!hasLoadedOnce) setState(() => isLoading = true);

    try {
      await _repository.initialize();
      final defaultCode = _repository.banks.any((b) => b.bankCode == selectedBankCode)
          ? selectedBankCode!
          : _repository.banks.first.bankCode;

      await _repository.getRates(defaultCode);
      await _maybeFetchUsdHistory(defaultCode);

      setState(() {
        selectedBankCode = defaultCode;
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

  Future<void> loadRates(String bankCode) async {
    if (_repository.getCachedRates(bankCode) != null && bankCode == selectedBankCode) {
      setState(() => errorMessage = null);
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _repository.getRates(bankCode);
      await _maybeFetchUsdHistory(bankCode);
      setState(() {
        selectedBankCode = bankCode;
        isLoading = false;
        errorMessage = null;
      });
      await saveBankPreference(bankCode);
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
        selectedBankCode != null &&
        _repository.getCachedRates(selectedBankCode!) != null;
  }

  Future<void> retry() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    await loadInitialData(force: true);
  }

  Future<void> _maybeFetchUsdHistory(String bankCode) async {
    if (usdHistory != null && selectedBankCode == bankCode) return;

    final cached = _usdHistoryRepository.getCached(bankCode);
    if (cached != null) {
      if (mounted) {
        setState(() {
          usdHistory = cached;
          isUsdLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => isUsdLoading = true);
    }

    try {
      final response = await _usdHistoryRepository.getUsdHistory(bankCode);
      if (mounted) {
        setState(() {
          usdHistory = response;
          isUsdLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isUsdLoading = false);
      }
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

  Widget _buildCompactFilterBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _filterAnimation,
      builder: (context, child) {
        return Container(
          height: _filterAnimation.value * 80, // Smaller height for just search
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          hintText: 'Search currencies...',
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterStatusBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_searchQuery.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Search: "$_searchQuery"',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
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
    super.build(context);
    final theme = Theme.of(context);
    final bankRates = selectedBankCode != null
        ? _repository.getCachedRates(selectedBankCode!)
        : null;
    final filteredRates = hasValidData ? _getFilteredRates() : [];

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
          child: Icon(_isFilterVisible ? Icons.close : Icons.search),
        ),
      )
          : null,
      body: Column(
        children: [
          // Bank Selector
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
                _usdHistoryRepository.clearCache();
                await loadInitialData(force: true);
              },
              child: !hasLoadedOnce || isLoading
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
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty
                          ? "No currencies found matching '$_searchQuery'"
                          : "No rates available.",
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
                              errorBuilder: (_, __, ___) =>
                              const SizedBox(),
                            ),
                          ),
                        ),
                      ),
                    ),

                  if (isUsdLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  if (usdHistory != null &&
                      usdHistory!.cashRates.length > 1)
                    SliverToBoxAdapter(
                      child: UsdHistoryChart(
                        rates: usdHistory!.cashRates,
                      ),
                    ),

                  SliverList(
                    delegate: SliverChildBuilderDelegate((
                        context,
                        index,
                        ) {
                      final item = filteredRates[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
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
                    }, childCount: filteredRates.length),
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