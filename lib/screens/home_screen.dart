import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/books_provider.dart';
import '../providers/auth_provider.dart';
import '../models/book.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final booksProvider = context.read<BooksProvider>();
      booksProvider.loadBooks();
      booksProvider.loadFilters();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final booksProvider = context.read<BooksProvider>();
      if (booksProvider.hasMore && !booksProvider.isLoadingMore) {
        booksProvider.loadMoreBooks();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Consumer<BooksProvider>(
        builder: (context, booksProvider, _) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Clean Header
              SliverAppBar(
                expandedHeight: 130,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF1A365D),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1A365D),
                          Color(0xFF2D4A6F),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Consumer<AuthProvider>(
                              builder: (context, auth, _) => Text(
                                'Welcome, ${auth.user?.firstName ?? 'Guest'}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Al-Burhaan Library',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white),
                    onPressed: () => _showFilters(context),
                  ),
                ],
              ),

              // Stats Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatsCard(
                          icon: Icons.library_books_outlined,
                          title: 'Total Books',
                          value: booksProvider.totalBooks?.toString() ?? '${booksProvider.books.length}+',
                          color: const Color(0xFF1A365D),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatsCard(
                          icon: Icons.category_outlined,
                          title: 'Categories',
                          value: '${booksProvider.subjects.length}',
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatsCard(
                          icon: Icons.language,
                          title: 'Languages',
                          value: '${booksProvider.languages.length}',
                          color: const Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Browse Collection',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A365D),
                        ),
                      ),
                      Text(
                        '${booksProvider.books.length} loaded',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
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
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(booksProvider.error!),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
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
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_books_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No books found'),
                      ],
                    ),
                  ),
                ),

              // Books Grid
              if (booksProvider.books.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final book = booksProvider.books[index];
                        return _BookCard(
                          book: book,
                          onTap: () => _showBookPreview(context, book),
                        );
                      },
                      childCount: booksProvider.books.length,
                    ),
                  ),
                ),

              // Loading More Indicator
              if (booksProvider.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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

// Stats Card
class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatsCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Book Card
class _BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _BookCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Book Cover
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: const Color(0xFFEEEEEE),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: book.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: book.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: Icon(Icons.book, size: 28, color: Colors.grey),
                          ),
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(Icons.book, size: 28, color: Colors.grey),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.book, size: 28, color: Colors.grey),
                        ),
                ),
              ),
            ),
            // Book Info
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  if (book.author != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      book.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Full Book Details Popup - shows ALL details
class _BookPreviewSheet extends StatelessWidget {
  final Book book;

  const _BookPreviewSheet({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with cover
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xFFEEEEEE),
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
                              ? CachedNetworkImage(imageUrl: book.imageUrl!, fit: BoxFit.cover)
                              : const Icon(Icons.book, size: 40, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(book.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            if (book.author != null) ...[
                              const SizedBox(height: 8),
                              _IconText(Icons.person_outline, book.author!),
                            ],
                            if (book.publicationYear != null) ...[
                              const SizedBox(height: 6),
                              _IconText(Icons.calendar_today_outlined, book.publicationYear!),
                            ],
                            if (book.publisher != null) ...[
                              const SizedBox(height: 6),
                              _IconText(Icons.business_outlined, book.publisher!),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Book Details Section
                  const Text('Book Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _DetailRow('ISBN', book.isbn),
                  _DetailRow('Call Number', book.callNumber),
                  _DetailRow('Language', book.language),
                  _DetailRow('Description', book.physicalDescription),
                  _DetailRow('Series', book.series),
                  if (book.subjects.isNotEmpty) _DetailRow('Subjects', book.subjects.join(', ')),
                  _DetailRow('Notes', book.notes),

                  // Media Section
                  if (_hasAnyMedia()) ...[
                    const SizedBox(height: 24),
                    const Text('Available Media', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (book.youtubeUrl != null) _MediaTile(Icons.play_circle_fill, 'Watch Video', 'YouTube', Colors.red, () => _openUrl(book.youtubeUrl!)),
                    if (book.pdfUrl != null) _MediaTile(Icons.picture_as_pdf, 'View PDF', 'Document', Colors.orange, () => _openUrl(book.pdfUrl!)),
                    if (book.ebookUrl != null) _MediaTile(Icons.menu_book, 'Read E-Book', 'Online', Colors.green, () => _openUrl(book.ebookUrl!)),
                  ],

                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A365D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Place Hold'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasAnyMedia() => book.youtubeUrl != null || book.pdfUrl != null || book.ebookUrl != null;

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _IconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[700]), maxLines: 2)),
      ],
    );
  }

  Widget _DetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600]))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _MediaTile(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}

// Filters Sheet
class _FiltersSheet extends StatelessWidget {
  final BooksProvider booksProvider;
  final ScrollController scrollController;

  const _FiltersSheet({required this.booksProvider, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filters', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              if (booksProvider.subjects.isNotEmpty) ...[
                const Text('Subject', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: booksProvider.subjects.take(20).map((s) {
                    final isSelected = booksProvider.selectedSubject == s.value;
                    return FilterChip(
                      label: Text(s.value, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (v) => booksProvider.setSubjectFilter(v ? s.value : null),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
              if (booksProvider.languages.isNotEmpty) ...[
                const Text('Language', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: booksProvider.languages.map((l) {
                    final isSelected = booksProvider.selectedLanguage == l.value;
                    return FilterChip(
                      label: Text(l.value, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (v) => booksProvider.setLanguageFilter(v ? l.value : null),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                booksProvider.applyFilters();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A365D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ),
      ],
    );
  }
}
