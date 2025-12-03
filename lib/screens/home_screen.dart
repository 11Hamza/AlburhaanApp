import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/books_provider.dart';
import '../providers/auth_provider.dart';
import '../models/book.dart';
import 'book_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final booksProvider = context.read<BooksProvider>();
      booksProvider.loadBooks();
      booksProvider.loadFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Consumer<BooksProvider>(
        builder: (context, booksProvider, _) {
          return CustomScrollView(
            slivers: [
              // Modern App Bar with Gradient
              SliverAppBar(
                expandedHeight: 180,
                floating: false,
                pinned: true,
                backgroundColor: colorScheme.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.primaryContainer,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              _getGreeting(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onPrimary.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Consumer<AuthProvider>(
                              builder: (context, auth, _) => Text(
                                auth.user?.firstName ?? 'Guest',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Stats Row
                            Row(
                              children: [
                                _StatCard(
                                  icon: Icons.library_books,
                                  label: 'Books',
                                  value: '${booksProvider.books.length}+',
                                  color: colorScheme.onPrimary,
                                ),
                                const SizedBox(width: 16),
                                _StatCard(
                                  icon: Icons.category,
                                  label: 'Categories',
                                  value: '${booksProvider.subjects.length}',
                                  color: colorScheme.onPrimary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.search, color: colorScheme.onPrimary),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.filter_list, color: colorScheme.onPrimary),
                    onPressed: () => _showFilters(context),
                  ),
                ],
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.auto_stories,
                          label: 'Browse All',
                          color: Colors.blue,
                          onTap: () => booksProvider.loadBooks(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.new_releases,
                          label: 'New Arrivals',
                          color: Colors.orange,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.favorite,
                          label: 'Favorites',
                          color: Colors.red,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Section Title - Featured
              if (booksProvider.books.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Featured Books',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Horizontal Featured Books
              if (booksProvider.books.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: booksProvider.books.take(10).length,
                      itemBuilder: (context, index) {
                        final book = booksProvider.books[index];
                        return _FeaturedBookCard(
                          book: book,
                          onTap: () => _showBookPreview(context, book),
                        );
                      },
                    ),
                  ),
                ),

              // Section Title - All Books
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'Library Collection',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Loading State
              if (booksProvider.isLoading && booksProvider.books.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),

              // Error State
              if (booksProvider.error != null && booksProvider.books.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                        const SizedBox(height: 16),
                        Text(booksProvider.error!),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => booksProvider.loadBooks(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Empty State
              if (!booksProvider.isLoading && booksProvider.books.isEmpty && booksProvider.error == null)
                const SliverFillRemaining(
                  child: Center(child: Text('No books found')),
                ),

              // Books Grid
              if (booksProvider.books.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= booksProvider.books.length) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final book = booksProvider.books[index];
                        return _ModernBookCard(
                          book: book,
                          onTap: () => _showBookPreview(context, book),
                        );
                      },
                      childCount: booksProvider.books.length + (booksProvider.hasMore ? 1 : 0),
                    ),
                  ),
                ),

              // Load More Trigger
              if (booksProvider.books.isNotEmpty && booksProvider.hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: booksProvider.isLoadingMore
                          ? const CircularProgressIndicator()
                          : TextButton(
                              onPressed: () => booksProvider.loadMoreBooks(),
                              child: const Text('Load More'),
                            ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _showFilters(BuildContext context) {
    final booksProvider = context.read<BooksProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _FiltersSheet(
            booksProvider: booksProvider,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  void _showBookPreview(BuildContext context, Book book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookPreviewSheet(book: book),
    );
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Quick Action Card
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Featured Book Card (Horizontal)
class _FeaturedBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _FeaturedBookCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: book.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: book.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.book, size: 40),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.book, size: 40),
                          ),
                        )
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.book, size: 40),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modern Book Card (Grid)
class _ModernBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _ModernBookCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Book Cover
            Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: book.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: book.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: Icon(Icons.book, size: 40, color: Colors.grey),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: Icon(Icons.book, size: 40, color: Colors.grey),
                            ),
                          ),
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.book, size: 40, color: Colors.grey),
                          ),
                        ),
                ),
              ),
            ),
            // Book Info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (book.author != null)
                    Text(
                      book.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Book Preview Bottom Sheet
class _BookPreviewSheet extends StatelessWidget {
  final Book book;

  const _BookPreviewSheet({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Cover and Title Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover
                      Container(
                        width: 120,
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: book.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: book.imageUrl!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.book, size: 48),
                                ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (book.author != null)
                              Row(
                                children: [
                                  Icon(Icons.person, size: 16, color: colorScheme.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      book.author!,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 6),
                            if (book.publicationYear != null)
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Text(
                                    book.publicationYear.toString(),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            const SizedBox(height: 6),
                            if (book.isbn != null)
                              Row(
                                children: [
                                  Icon(Icons.qr_code, size: 16, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ISBN: ${book.isbn}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookDetailScreen(biblioId: book.biblioId),
                              ),
                            );
                          },
                          icon: const Icon(Icons.info_outline),
                          label: const Text('Full Details'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.favorite_border),
                          label: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Place Hold Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () {},
                      icon: const Icon(Icons.bookmark_add),
                      label: const Text('Place Hold'),
                    ),
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

// Filters Sheet
class _FiltersSheet extends StatelessWidget {
  final BooksProvider booksProvider;
  final ScrollController scrollController;

  const _FiltersSheet({
    required this.booksProvider,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Title
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filters', style: theme.textTheme.titleLarge),
              TextButton(
                onPressed: () {
                  booksProvider.clearFilters();
                  Navigator.pop(context);
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Filter Options
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              if (booksProvider.subjects.isNotEmpty) ...[
                Text('Subject', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: booksProvider.subjects.take(20).map((subject) {
                    final isSelected = booksProvider.selectedSubject == subject.value;
                    return FilterChip(
                      label: Text(subject.value),
                      selected: isSelected,
                      onSelected: (selected) {
                        booksProvider.setSubjectFilter(selected ? subject.value : null);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
              if (booksProvider.languages.isNotEmpty) ...[
                Text('Language', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: booksProvider.languages.map((language) {
                    final isSelected = booksProvider.selectedLanguage == language.value;
                    return FilterChip(
                      label: Text(language.value),
                      selected: isSelected,
                      onSelected: (selected) {
                        booksProvider.setLanguageFilter(selected ? language.value : null);
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        // Apply Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                booksProvider.applyFilters();
                Navigator.pop(context);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Apply Filters'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
