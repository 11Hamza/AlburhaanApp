import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/content_service.dart';
import '../models/ebook.dart';
import '../models/video.dart';

class EbooksScreen extends StatefulWidget {
  const EbooksScreen({super.key});

  @override
  State<EbooksScreen> createState() => _EbooksScreenState();
}

class _EbooksScreenState extends State<EbooksScreen> {
  final ContentService _service = ContentService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Ebook> _ebooks = [];
  List<ContentCategory> _categories = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _page = 1;
  int _total = 0;
  String? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadEbooks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadCategories() async {
    final categories = await _service.getCategories();
    setState(() {
      _categories = categories.where((c) => c.ebookCount > 0).toList();
    });
  }

  Future<void> _loadEbooks() async {
    setState(() {
      _isLoading = true;
      _page = 1;
    });

    final result = await _service.getEbooks(
      page: 1,
      category: _selectedCategory,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );

    setState(() {
      _ebooks = result.ebooks;
      _total = result.total;
      _isLoading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _ebooks.length >= _total) return;

    setState(() => _isLoadingMore = true);

    final result = await _service.getEbooks(
      page: _page + 1,
      category: _selectedCategory,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );

    setState(() {
      _ebooks.addAll(result.ebooks);
      _page++;
      _isLoadingMore = false;
    });
  }

  void _onCategorySelected(String? category) {
    setState(() => _selectedCategory = category);
    _loadEbooks();
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query);
    _loadEbooks();
  }

  Future<void> _openEbook(Ebook ebook) async {
    // Get ebook with access URL
    final details = await _service.getEbook(ebook.id);
    if (details?.accessUrl != null) {
      final uri = Uri.parse(details!.accessUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('eBook not available')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('eBooks Library'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search eBooks...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onSubmitted: _onSearch,
            ),
          ),

          // Category filters
          if (_categories.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _selectedCategory == null,
                        onSelected: (_) => _onCategorySelected(null),
                      ),
                    );
                  }
                  final category = _categories[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('${category.name} (${category.ebookCount})'),
                      selected: _selectedCategory == category.name,
                      onSelected: (_) => _onCategorySelected(category.name),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // Ebooks grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _ebooks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            const Text('No eBooks found'),
                            if (_searchQuery.isNotEmpty || _selectedCategory != null) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedCategory = null;
                                  });
                                  _loadEbooks();
                                },
                                child: const Text('Clear filters'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadEbooks,
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _ebooks.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _ebooks.length) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            return _EbookCard(
                              ebook: _ebooks[index],
                              onTap: () => _openEbook(_ebooks[index]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _EbookCard extends StatelessWidget {
  final Ebook ebook;
  final VoidCallback onTap;

  const _EbookCard({
    required this.ebook,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover
            Expanded(
              flex: 3,
              child: ebook.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: ebook.coverUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _PlaceholderCover(),
                    )
                  : _PlaceholderCover(),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ebook.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (ebook.author != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        ebook.author!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        if (ebook.fileType != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              ebook.fileType!.toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        const Spacer(),
                        Icon(
                          Icons.download,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.menu_book,
          size: 48,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
