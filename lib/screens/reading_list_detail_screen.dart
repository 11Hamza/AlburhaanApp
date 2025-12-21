import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/reading_list_service.dart';
import '../models/reading_list.dart';
import 'book_detail_screen.dart';

class ReadingListDetailScreen extends StatefulWidget {
  final String listId;
  final String listName;

  const ReadingListDetailScreen({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<ReadingListDetailScreen> createState() => _ReadingListDetailScreenState();
}

class _ReadingListDetailScreenState extends State<ReadingListDetailScreen> {
  final ReadingListService _service = ReadingListService();
  ReadingList? _list;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    setState(() => _isLoading = true);
    final list = await _service.getReadingList(widget.listId);
    setState(() {
      _list = list;
      _isLoading = false;
    });
  }

  Future<void> _updateItemStatus(ReadingListItem item, String newStatus) async {
    final success = await _service.updateListItem(
      listId: widget.listId,
      itemId: item.id,
      status: newStatus,
    );

    if (success) {
      _loadList();
    }
  }

  Future<void> _removeItem(ReadingListItem item) async {
    final success = await _service.removeFromList(
      listId: widget.listId,
      itemId: item.id,
    );

    if (success) {
      setState(() {
        _list?.items?.removeWhere((i) => i.id == item.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book removed from list')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_list?.name ?? widget.listName),
        actions: [
          if (_list != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => _EditListDialog(list: _list!),
                  );
                  if (result != null) {
                    await _service.updateReadingList(
                      id: widget.listId,
                      name: result['name'],
                      description: result['description'],
                      isPublic: result['isPublic'],
                    );
                    _loadList();
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit List'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _list == null
              ? const Center(child: Text('List not found'))
              : _list!.items?.isEmpty ?? true
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          const Text('No books in this list'),
                          const SizedBox(height: 8),
                          Text(
                            'Add books from the book details page',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadList,
                      child: Column(
                        children: [
                          // List info header
                          if (_list!.description != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                              child: Text(
                                _list!.description!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          // Status filter chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                _StatusChip(
                                  label: 'All',
                                  count: _list!.items!.length,
                                  isSelected: true,
                                ),
                                const SizedBox(width: 8),
                                _StatusChip(
                                  label: 'To Read',
                                  count: _list!.items!.where((i) => i.status == 'to_read').length,
                                ),
                                const SizedBox(width: 8),
                                _StatusChip(
                                  label: 'Reading',
                                  count: _list!.items!.where((i) => i.status == 'reading').length,
                                ),
                                const SizedBox(width: 8),
                                _StatusChip(
                                  label: 'Completed',
                                  count: _list!.items!.where((i) => i.status == 'completed').length,
                                ),
                              ],
                            ),
                          ),
                          // Books list
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _list!.items!.length,
                              itemBuilder: (context, index) {
                                final item = _list!.items![index];
                                return _ReadingListItemCard(
                                  item: item,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BookDetailScreen(
                                          biblioId: item.biblioId,
                                        ),
                                      ),
                                    );
                                  },
                                  onStatusChange: (status) => _updateItemStatus(item, status),
                                  onRemove: () => _removeItem(item),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;

  const _StatusChip({
    required this.label,
    required this.count,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) {},
    );
  }
}

class _ReadingListItemCard extends StatelessWidget {
  final ReadingListItem item;
  final VoidCallback onTap;
  final Function(String) onStatusChange;
  final VoidCallback onRemove;

  const _ReadingListItemCard({
    required this.item,
    required this.onTap,
    required this.onStatusChange,
    required this.onRemove,
  });

  Color _getStatusColor(BuildContext context) {
    switch (item.status) {
      case 'reading':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'to_read':
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  IconData _getStatusIcon() {
    switch (item.status) {
      case 'reading':
        return Icons.auto_stories;
      case 'completed':
        return Icons.check_circle;
      case 'to_read':
      default:
        return Icons.bookmark_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = item.book;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Cover
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 60,
                    height: 80,
                    child: book?.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: book!.imageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              child: const Icon(Icons.book),
                            ),
                          )
                        : Container(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: const Icon(Icons.book),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book?.title ?? 'Unknown Book',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (book?.author != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          book!.author!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Status chip
                      Row(
                        children: [
                          Icon(
                            _getStatusIcon(),
                            size: 16,
                            color: _getStatusColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.statusLabel,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: _getStatusColor(context),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'remove') {
                      onRemove();
                    } else {
                      onStatusChange(value);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'to_read',
                      child: Row(
                        children: [
                          Icon(Icons.bookmark_outline),
                          SizedBox(width: 8),
                          Text('Mark as To Read'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reading',
                      child: Row(
                        children: [
                          Icon(Icons.auto_stories, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Mark as Reading'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'completed',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Mark as Completed'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Remove from List'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditListDialog extends StatefulWidget {
  final ReadingList list;

  const _EditListDialog({required this.list});

  @override
  State<_EditListDialog> createState() => _EditListDialogState();
}

class _EditListDialogState extends State<_EditListDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late bool _isPublic;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.list.name);
    _descController = TextEditingController(text: widget.list.description ?? '');
    _isPublic = widget.list.isPublic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Reading List'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'List Name *',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Public'),
              subtitle: const Text('Others can see this list'),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a list name')),
              );
              return;
            }
            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'description': _descController.text.trim().isEmpty
                  ? null
                  : _descController.text.trim(),
              'isPublic': _isPublic,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
