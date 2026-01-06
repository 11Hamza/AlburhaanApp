import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/books_provider.dart';
import '../providers/auth_provider.dart';
import '../models/book.dart';
import '../models/reading_list.dart';
import '../models/library.dart';
import '../services/reading_list_service.dart';
import '../services/user_service.dart';
import '../services/books_service.dart';
import 'search_screen.dart';
import 'ebooks_screen.dart';
import 'videos_screen.dart';

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
    // Trigger loading earlier (500px before end) for smoother scrolling
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
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

              // Digital Content Quick Access
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickAccessCard(
                          icon: Icons.menu_book,
                          title: 'eBooks',
                          subtitle: 'Digital library',
                          color: const Color(0xFF7B1FA2),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EbooksScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAccessCard(
                          icon: Icons.play_circle_filled,
                          title: 'Videos',
                          subtitle: 'Watch & learn',
                          color: const Color(0xFFC62828),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const VideosScreen()),
                          ),
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

// Quick Access Card for Digital Content
class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.7), size: 16),
          ],
        ),
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
class _BookPreviewSheet extends StatefulWidget {
  final Book book;

  const _BookPreviewSheet({required this.book});

  @override
  State<_BookPreviewSheet> createState() => _BookPreviewSheetState();
}

class _BookPreviewSheetState extends State<_BookPreviewSheet> {
  final ReadingListService _readingListService = ReadingListService();
  final UserService _userService = UserService();
  final BooksService _booksService = BooksService();

  Book get book => widget.book;

  // State
  BookAvailability? _availability;
  bool _isFavorite = false;
  bool _isLoadingAvailability = true;
  bool _isTogglingFavorite = false;
  bool _isPlacingHold = false;

  @override
  void initState() {
    super.initState();
    _loadBookData();
  }

  Future<void> _loadBookData() async {
    final authProvider = context.read<AuthProvider>();

    // Load availability
    final availability = await _booksService.getBookAvailability(book.biblioId);
    if (mounted) {
      setState(() {
        _availability = availability;
        _isLoadingAvailability = false;
      });
    }

    // Check if favorited (only for logged in users)
    if (!authProvider.isGuest) {
      final isFav = await _userService.isFavorited(book.biblioId);
      if (mounted) {
        setState(() => _isFavorite = isFav);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to save favorites')),
      );
      return;
    }

    setState(() => _isTogglingFavorite = true);

    bool success;
    if (_isFavorite) {
      success = await _userService.removeFromFavorites(book.biblioId);
    } else {
      success = await _userService.addToFavorites(book.biblioId);
    }

    if (mounted) {
      setState(() {
        if (success) _isFavorite = !_isFavorite;
        _isTogglingFavorite = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? (_isFavorite ? 'Added to favorites' : 'Removed from favorites')
              : 'Failed to update favorites'),
        ),
      );
    }
  }

  Future<void> _showPlaceHoldDialog() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to place holds')),
      );
      return;
    }

    // STEP 1: Confirm they want to request this book
    final wantToRequest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.bookmark_add,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Request This Book?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.book, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      book.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You are requesting to borrow this book. Would you like to proceed?',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Continue'),
          ),
        ],
      ),
    );

    if (wantToRequest != true || !mounted) return;

    // STEP 2: Fetch libraries and show selection dialog
    final libraries = await _userService.getLibraries();
    if (!mounted) return;

    if (libraries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pickup locations available')),
      );
      return;
    }

    // Show library selection dialog with notes
    Library? selectedLibrary = libraries.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Pickup Location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<Library>(
                  value: selectedLibrary,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: libraries.map((lib) {
                    return DropdownMenuItem(
                      value: lib,
                      child: Text(lib.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedLibrary = value);
                  },
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.amber.shade800),
                          const SizedBox(width: 8),
                          Text(
                            'Please Note',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Our librarian will review your request\n'
                        '• Check your Holds tab for status updates\n'
                        '• Holds must be collected within 5 days once ready',
                        style: TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Confirm Request'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedLibrary != null && mounted) {
      await _placeHold(selectedLibrary!);
    }
  }

  Future<void> _placeHold(Library library) async {
    setState(() => _isPlacingHold = true);

    final result = await _userService.placeHold(
      biblioId: book.biblioId,
      pickupLibraryId: library.libraryId,
    );

    if (mounted) {
      setState(() => _isPlacingHold = false);

      if (result.success) {
        // Show success dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: const Text('Request Submitted!'),
            content: const Text(
              'Your hold request has been submitted.\n\n'
              'Our librarian will review and confirm your request. '
              'Please check your Holds tab for updates.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.pop(context); // Close the sheet
      } else {
        // Show error dialog with details
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
            title: const Text('Unable to Place Hold'),
            content: Text(
              result.error ?? 'Failed to place hold. Please try again or contact the library.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _showAddToReadingListDialog() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to use reading lists')),
      );
      return;
    }

    // Fetch reading lists
    final lists = await _readingListService.getReadingLists();

    if (!mounted) return;

    if (lists.isEmpty) {
      // Offer to create a new list
      await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Reading Lists'),
          content: const Text('You don\'t have any reading lists yet. Would you like to create one?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await _showCreateListDialog();
              },
              child: const Text('Create List'),
            ),
          ],
        ),
      );
      return;
    }

    // Show list selection dialog
    final selectedList = await showDialog<ReadingList>(
      context: context,
      builder: (context) => _ReadingListSelectionDialog(
        lists: lists,
        onCreateNew: () async {
          Navigator.pop(context);
          await _showCreateListDialog();
        },
      ),
    );

    if (selectedList != null && mounted) {
      await _addBookToList(selectedList);
    }
  }

  Future<void> _showCreateListDialog() async {
    final nameController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Reading List'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'List Name',
            hintText: 'e.g., Books to Read',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && mounted) {
      final newList = await _readingListService.createReadingList(name: name);
      if (newList != null && mounted) {
        await _addBookToList(newList);
      }
    }
  }

  Future<void> _addBookToList(ReadingList list) async {
    final item = await _readingListService.addBookToList(
      listId: list.id,
      biblioId: book.biblioId,
    );

    if (mounted) {
      if (item != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to "${list.name}"')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add book (may already be in list)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

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
                  // Header with cover and favorite button
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
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(book.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ),
                                // Favorite button
                                IconButton(
                                  onPressed: _isTogglingFavorite ? null : _toggleFavorite,
                                  icon: _isTogglingFavorite
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Icon(
                                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                                          color: _isFavorite ? Colors.red : Colors.grey,
                                        ),
                                ),
                              ],
                            ),
                            if (book.author != null) ...[
                              const SizedBox(height: 4),
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

                  const SizedBox(height: 16),

                  // Availability Section
                  _buildAvailabilitySection(),

                  const SizedBox(height: 16),

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

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isPlacingHold ? null : _showPlaceHoldDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A365D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isPlacingHold
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Place Hold'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _showAddToReadingListDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B1FA2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Icon(Icons.playlist_add),
                      ),
                    ],
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

  Widget _buildAvailabilitySection() {
    if (_isLoadingAvailability) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            Text('Checking availability...'),
          ],
        ),
      );
    }

    if (_availability == null) {
      return const SizedBox.shrink();
    }

    final isAvailable = _availability!.isAvailable;
    final availableCount = _availability!.availableCopies;
    final totalCount = _availability!.totalCopies;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAvailable ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAvailable ? Icons.check_circle : Icons.schedule,
                color: isAvailable ? Colors.green[700] : Colors.orange[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isAvailable ? 'Available' : 'Not Available',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isAvailable ? Colors.green[700] : Colors.orange[700],
                ),
              ),
              const Spacer(),
              Text(
                '$availableCount of $totalCount copies',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (_availability!.branches.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _availability!.branches.where((b) => b.available > 0).take(3).map((branch) {
                return Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    '${branch.libraryName}: ${branch.available}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.white,
                );
              }).toList(),
            ),
          ],
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
      ),
    );
  }
}

// Library Selection Dialog for Place Hold
class _LibrarySelectionDialog extends StatelessWidget {
  final List<Library> libraries;

  const _LibrarySelectionDialog({required this.libraries});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Pickup Location'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: libraries.length,
          itemBuilder: (context, index) {
            final library = libraries[index];
            return ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(library.name),
              subtitle: library.fullAddress.isNotEmpty ? Text(library.fullAddress, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
              onTap: () => Navigator.pop(context, library),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

// Reading List Selection Dialog
class _ReadingListSelectionDialog extends StatelessWidget {
  final List<ReadingList> lists;
  final VoidCallback onCreateNew;

  const _ReadingListSelectionDialog({
    required this.lists,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add to Reading List'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...lists.map((list) => ListTile(
              leading: const Icon(Icons.list_alt),
              title: Text(list.name),
              subtitle: Text('${list.itemCount} books'),
              onTap: () => Navigator.pop(context, list),
            )),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add, color: Colors.green),
              title: const Text('Create New List'),
              onTap: onCreateNew,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
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
