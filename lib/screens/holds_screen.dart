import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/hold.dart';
import 'book_detail_screen.dart';

class HoldsScreen extends StatefulWidget {
  const HoldsScreen({super.key});

  @override
  State<HoldsScreen> createState() => _HoldsScreenState();
}

class _HoldsScreenState extends State<HoldsScreen> {
  final UserService _userService = UserService();

  List<Hold> _holds = [];
  HoldsSummary _summary = HoldsSummary();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHolds();
  }

  Future<void> _loadHolds() async {
    setState(() => _isLoading = true);

    final result = await _userService.getHolds();
    setState(() {
      _holds = result.holds;
      _summary = result.summary;
      _isLoading = false;
    });
  }

  Future<void> _cancelHold(Hold hold) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Hold'),
        content: Text('Cancel hold on "${hold.book?.title ?? 'this book'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _userService.cancelHold(hold.holdId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hold cancelled')),
        );
        _loadHolds();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel hold'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_holds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            const Text('No current holds'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHolds,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _holds.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSummaryCard();
          }

          final hold = _holds[index - 1];
          return _HoldCard(
            hold: hold,
            onCancel: () => _cancelHold(hold),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookDetailScreen(biblioId: hold.biblioId),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: _summary.ready > 0
          ? Colors.green.shade50
          : Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryItem(
              label: 'Total',
              value: '${_summary.total}',
              icon: Icons.bookmark,
            ),
            _SummaryItem(
              label: 'Ready',
              value: '${_summary.ready}',
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            _SummaryItem(
              label: 'Pending',
              value: '${_summary.pending}',
              icon: Icons.schedule,
              color: Colors.orange,
            ),
          ],
        ),
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
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _HoldCard extends StatelessWidget {
  final Hold hold;
  final VoidCallback onCancel;
  final VoidCallback onTap;

  const _HoldCard({
    required this.hold,
    required this.onCancel,
    required this.onTap,
  });

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
                      hold.book?.title ?? 'Unknown Book',
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
                      color: hold.isReady
                          ? Colors.green
                          : hold.isInTransit
                              ? Colors.blue
                              : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      hold.statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (hold.priority != null)
                Text(
                  'Queue position: ${hold.priority}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Pickup: ${hold.pickupLibraryId}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
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
