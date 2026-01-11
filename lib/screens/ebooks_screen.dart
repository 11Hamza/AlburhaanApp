import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/content_provider.dart';
import '../models/ebook.dart';
import '../models/video.dart';

class EbooksScreen extends StatefulWidget {
  const EbooksScreen({super.key});

  @override
  State<EbooksScreen> createState() => _EbooksScreenState();
}

class _EbooksScreenState extends State<EbooksScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String _searchQuery = '';
  List<Ebook>? _searchResults; // null means showing cached data

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load from cache (instant if already loaded)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentProvider>().loadEbooks();
    });
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
      // Only load more when not searching
      if (_searchResults == null) {
        context.read<ContentProvider>().loadMoreEbooks();
      }
    }
  }

  void _onCategorySelected(String? category) {
    setState(() => _selectedCategory = category);
    if (category != null || _searchQuery.isNotEmpty) {
      _performSearch();
    } else {
      setState(() => _searchResults = null); // Back to cached data
    }
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty && _selectedCategory == null) {
      setState(() => _searchResults = null);
      return;
    }

    final results = await context.read<ContentProvider>().searchEbooks(
      query: _searchQuery.isNotEmpty ? _searchQuery : null,
      category: _selectedCategory,
    );
    setState(() => _searchResults = results);
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query);
    _performSearch();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _searchResults = null;
    });
  }

  Future<void> _openEbook(Ebook ebook) async {
    // Use accessUrl directly from the ebook (already returned in list)
    if (ebook.accessUrl != null && ebook.accessUrl!.isNotEmpty) {
      final uri = Uri.parse(ebook.accessUrl!);
      if (await canLaunchUrl(uri)) {
        // Open in-app browser instead of external app
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open eBook')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('eBook URL not available')),
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
      body: Consumer<ContentProvider>(
        builder: (context, provider, _) {
          final categories = provider.ebookCategories;
          final isLoading = provider.isLoadingEbooks && !provider.ebooksLoaded;
          final isLoadingMore = provider.isLoadingMoreEbooks;

          // Use search results if searching, otherwise use cached data
          final ebooks = _searchResults ?? provider.ebooks;

          return Column(
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
                            onPressed: _clearFilters,
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
              if (categories.isNotEmpty)
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length + 1,
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
                      final category = categories[index - 1];
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
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ebooks.isEmpty
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
                                    onPressed: _clearFilters,
                                    child: const Text('Clear filters'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => provider.refreshEbooks(),
                            child: GridView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.65,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: ebooks.length + (isLoadingMore && _searchResults == null ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= ebooks.length) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                return _EbookCard(
                                  ebook: ebooks[index],
                                  onTap: () => _openEbook(ebooks[index]),
                                );
                              },
                            ),
                          ),
              ),
            ],
          );
        },
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
                          Icons.open_in_new,
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
