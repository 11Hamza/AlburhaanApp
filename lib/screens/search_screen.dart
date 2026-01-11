import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/books_provider.dart';
import '../models/book.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showAdvanced = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _scrollController.dispose();
    // Clear search results when leaving the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) return;
      // Use Future.microtask to safely clear after dispose
    });
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {}); // Update UI for clear button visibility

    // Only use live search when not in advanced mode
    if (_showAdvanced) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      final booksProvider = context.read<BooksProvider>();
      if (_searchController.text.isNotEmpty) {
        booksProvider.liveSearch(_searchController.text);
      } else {
        booksProvider.clearSearchResults();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final booksProvider = context.read<BooksProvider>();
      if (booksProvider.searchHasMore && !booksProvider.isSearching) {
        // Could add loadMoreSearchResults here if needed
      }
    }
  }

  void _search() {
    final booksProvider = context.read<BooksProvider>();
    if (_showAdvanced) {
      booksProvider.searchBooks(
        keyword: _searchController.text,
        author: _authorController.text,
        isbn: _isbnController.text,
      );
    } else {
      booksProvider.liveSearch(_searchController.text);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<BooksProvider>().clearSearchResults();
  }

  void _showBookDetails(BuildContext context, Book book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FullBookDetailsSheet(book: book),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A365D),
        foregroundColor: Colors.white,
        title: const Text('Search Library'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by title, author, or keyword...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _search,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A365D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Search'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more, size: 20),
                          const SizedBox(width: 4),
                          const Text('Advanced'),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_showAdvanced) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _authorController,
                    decoration: InputDecoration(
                      hintText: 'Author name',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _isbnController,
                    decoration: InputDecoration(
                      hintText: 'ISBN',
                      prefixIcon: const Icon(Icons.qr_code),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Results
          Expanded(
            child: Consumer<BooksProvider>(
              builder: (context, booksProvider, _) {
                final results = booksProvider.searchResults;
                final isSearching = booksProvider.isSearching;
                final searchError = booksProvider.searchError;

                if (isSearching && results.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (searchError != null && results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Search failed',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _search,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Search for books'
                              : 'No results found',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Start typing to search'
                              : 'Try a different search term',
                          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final book = results[index];
                        return _SearchResultCard(
                          book: book,
                          onTap: () => _showBookDetails(context, book),
                        );
                      },
                    ),
                    // Loading indicator while typing
                    if (isSearching)
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Searching...', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _SearchResultCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 65,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFEEEEEE),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: book.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: book.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(Icons.book, color: Colors.grey),
                        )
                      : const Icon(Icons.book, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (book.author != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        book.author!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (book.publicationYear != null)
                          _Tag(book.publicationYear!),
                        if (book.youtubeUrl != null)
                          const _Tag('Video', color: Colors.red),
                        if (book.pdfUrl != null)
                          const _Tag('PDF', color: Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color? color;

  const _Tag(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color ?? Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// Full Book Details Sheet - shows ALL details in popup
class _FullBookDetailsSheet extends StatelessWidget {
  final Book book;

  const _FullBookDetailsSheet({required this.book});

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
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with cover and basic info
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
                              ? CachedNetworkImage(
                                  imageUrl: book.imageUrl!,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.book, size: 40, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (book.author != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      book.author!,
                                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (book.publicationYear != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  Text(
                                    book.publicationYear!,
                                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ],
                            if (book.publisher != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.business_outlined, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      book.publisher!,
                                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // All Book Details
                  const Text(
                    'Book Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _DetailItem('ISBN', book.isbn),
                  _DetailItem('Call Number', book.callNumber),
                  _DetailItem('Language', book.language),
                  _DetailItem('Physical Description', book.physicalDescription),
                  _DetailItem('Series', book.series),
                  if (book.subjects.isNotEmpty)
                    _DetailItem('Subjects', book.subjects.join(', ')),
                  _DetailItem('Notes', book.notes),

                  // Media Section
                  if (_hasAnyMedia()) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Available Media',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (book.youtubeUrl != null)
                      _MediaButton(
                        icon: Icons.play_circle_fill,
                        label: 'Watch Video',
                        subtitle: 'YouTube',
                        color: Colors.red,
                        onTap: () => _openUrl(book.youtubeUrl!),
                      ),
                    if (book.pdfUrl != null)
                      _MediaButton(
                        icon: Icons.picture_as_pdf,
                        label: 'View PDF',
                        subtitle: 'Document',
                        color: Colors.orange,
                        onTap: () => _openUrl(book.pdfUrl!),
                      ),
                    if (book.ebookUrl != null)
                      _MediaButton(
                        icon: Icons.menu_book,
                        label: 'Read E-Book',
                        subtitle: 'Online',
                        color: Colors.green,
                        onTap: () => _openUrl(book.ebookUrl!),
                      ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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

  bool _hasAnyMedia() {
    return book.youtubeUrl != null || book.pdfUrl != null || book.ebookUrl != null;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _DetailItem(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _MediaButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
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
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
