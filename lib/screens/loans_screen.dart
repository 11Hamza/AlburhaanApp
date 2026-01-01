import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../services/books_service.dart';
import '../models/loan.dart';
import 'book_detail_screen.dart';
import 'holds_screen.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();

  List<Loan> _loans = [];
  LoansSummary _summary = LoansSummary();
  bool _isLoading = true;
  bool _isRenewing = false;

  // History tab state
  List<LoanHistory> _history = [];
  bool _isLoadingHistory = true;
  bool _isLoadingMoreHistory = false;
  int _historyPage = 1;
  bool _hasMoreHistory = false;
  final ScrollController _historyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLoans();
    _loadHistory();

    // Add scroll listener for infinite scroll on history tab
    _historyScrollController.addListener(_onHistoryScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _historyScrollController.dispose();
    super.dispose();
  }

  void _onHistoryScroll() {
    if (_historyScrollController.position.pixels >=
            _historyScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMoreHistory &&
        _hasMoreHistory) {
      _loadMoreHistory();
    }
  }

  Future<void> _loadLoans() async {
    setState(() => _isLoading = true);

    final result = await _userService.getLoans();
    setState(() {
      _loans = result.loans;
      _summary = result.summary;
      _isLoading = false;
    });
  }

  Future<void> _renewLoan(Loan loan) async {
    final result = await _userService.renewLoan(loan.checkoutId);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan renewed successfully')),
      );
      _loadLoans();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to renew'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _renewAll() async {
    setState(() => _isRenewing = true);

    final result = await _userService.renewAllLoans();

    setState(() => _isRenewing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'Renewed ${result.renewed} loans'),
      ),
    );

    _loadLoans();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _historyPage = 1;
    });

    final result = await _userService.getLoanHistory(page: 1, perPage: 20);
    setState(() {
      _history = result.items;
      _hasMoreHistory = result.hasMore;
      _isLoadingHistory = false;
    });
  }

  Future<void> _loadMoreHistory() async {
    if (_isLoadingMoreHistory) return;

    setState(() => _isLoadingMoreHistory = true);

    final nextPage = _historyPage + 1;
    final result = await _userService.getLoanHistory(page: nextPage, perPage: 20);

    setState(() {
      _history.addAll(result.items);
      _historyPage = nextPage;
      _hasMoreHistory = result.hasMore;
      _isLoadingMoreHistory = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Loans')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64),
              const SizedBox(height: 16),
              const Text('Please login to view your loans'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Loans'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Current (${_summary.total})'),
            const Tab(text: 'Holds'),
            const Tab(text: 'History'),
          ],
        ),
        actions: [
          if (_loans.isNotEmpty)
            TextButton(
              onPressed: _isRenewing ? null : _renewAll,
              child: _isRenewing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Renew All'),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Current Loans Tab
          _buildLoansTab(),
          // Holds Tab
          const HoldsScreen(),
          // History Tab
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildLoansTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            const Text('No current loans'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLoans,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _loans.length + 1, // +1 for summary header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSummaryCard();
          }

          final loan = _loans[index - 1];
          return _LoanCard(
            loan: loan,
            onRenew: () => _renewLoan(loan),
            onTap: () {
              if (loan.biblioId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookDetailScreen(biblioId: loan.biblioId!),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: _summary.overdue > 0
          ? Colors.red.shade50
          : Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryItem(
              label: 'Total',
              value: '${_summary.total}',
              icon: Icons.book,
            ),
            _SummaryItem(
              label: 'Overdue',
              value: '${_summary.overdue}',
              icon: Icons.warning,
              color: Colors.red,
            ),
            _SummaryItem(
              label: 'Due Soon',
              value: '${_summary.dueSoon}',
              icon: Icons.schedule,
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            const Text('No loan history'),
            const SizedBox(height: 8),
            Text(
              'Books you\'ve borrowed will appear here',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        controller: _historyScrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _history.length + (_hasMoreHistory ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _history.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = _history[index];
          return _LoanHistoryCard(
            history: item,
            onTap: () {
              if (item.biblioId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookDetailScreen(biblioId: item.biblioId!),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Loan loan;
  final VoidCallback onRenew;
  final VoidCallback onTap;

  const _LoanCard({
    required this.loan,
    required this.onRenew,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dueDate = DateTime.tryParse(loan.dueDate);
    final formattedDate = dueDate != null
        ? '${dueDate.day}/${dueDate.month}/${dueDate.year}'
        : loan.dueDate;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loan.book?.title ?? 'Unknown Book',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: loan.isOverdue
                          ? Colors.red
                          : loan.daysUntilDue <= 3
                              ? Colors.orange
                              : Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      loan.statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: $formattedDate',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: loan.canRenew ? onRenew : null,
                    child: const Text('Renew'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoanHistoryCard extends StatelessWidget {
  final LoanHistory history;
  final VoidCallback onTap;

  const _LoanHistoryCard({
    required this.history,
    required this.onTap,
  });

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    final date = DateTime.tryParse(dateString);
    if (date == null) return dateString;
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      history.book?.title ?? 'Unknown Book',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Returned',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (history.book?.author != null) ...[
                const SizedBox(height: 4),
                Text(
                  history.book!.author!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Borrowed: ${_formatDate(history.issueDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Returned: ${_formatDate(history.returnDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
