import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/books_provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../models/library.dart';
import 'media_viewer_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final int biblioId;

  const BookDetailScreen({super.key, required this.biblioId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _isFavorite = false;
  bool _loadingFavorite = false;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadBook();
    _checkFavorite();
  }

  Future<void> _loadBook() async {
    final booksProvider = context.read<BooksProvider>();
    await booksProvider.loadBookDetails(widget.biblioId);
  }

  Future<void> _checkFavorite() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isGuest) {
      final isFav = await _userService.isFavorited(widget.biblioId);
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

    setState(() => _loadingFavorite = true);

    if (_isFavorite) {
      await _userService.removeFromFavorites(widget.biblioId);
    } else {
      await _userService.addToFavorites(widget.biblioId);
    }

    setState(() {
      _isFavorite = !_isFavorite;
      _loadingFavorite = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<BooksProvider>(
        builder: (context, booksProvider, _) {
          if (booksProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final book = booksProvider.selectedBook;
          final availability = booksProvider.selectedBookAvailability;

          if (book == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64),
                  const SizedBox(height: 16),
                  const Text('Book not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // App Bar with Cover Image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: book.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: book.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: const Icon(Icons.book, size: 64),
                          ),
                        )
                      : Container(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: const Icon(Icons.book, size: 64),
                        ),
                ),
                actions: [
                  // Favorite button
                  IconButton(
                    icon: _loadingFavorite
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : null,
                          ),
                    onPressed: _loadingFavorite ? null : _toggleFavorite,
                  ),
                ],
              ),

              // Book Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        book.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),

                      // Author
                      if (book.author != null) ...[
                        Text(
                          'by ${book.author}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Availability
                      if (availability != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  availability.isAvailable
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: availability.isAvailable
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        availability.isAvailable
                                            ? 'Available'
                                            : 'Not Available',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${availability.availableCopies} of ${availability.totalCopies} copies available',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _placeHold(context),
                              icon: const Icon(Icons.bookmark_add),
                              label: const Text('Place Hold'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_hasAnyMedia(book))
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MediaViewerScreen(book: book),
                                  ),
                                ),
                                icon: const Icon(Icons.play_circle_outline),
                                label: const Text('Media'),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Book Info
                      Text(
                        'Details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'ISBN', value: book.isbn),
                      _DetailRow(label: 'Publisher', value: book.publisher),
                      _DetailRow(label: 'Year', value: book.publicationYear),
                      _DetailRow(label: 'Language', value: book.language),
                      _DetailRow(label: 'Call Number', value: book.callNumber),
                      _DetailRow(label: 'Physical Description', value: book.physicalDescription),
                      _DetailRow(label: 'Series', value: book.series),

                      // Subjects
                      if (book.subjects.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Subjects',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: book.subjects.map((subject) {
                            return Chip(label: Text(subject));
                          }).toList(),
                        ),
                      ],

                      // Notes
                      if (book.notes != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Notes',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(book.notes!),
                      ],

                      // Media Section
                      if (_hasAnyMedia(book)) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Available Media',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Column(
                            children: [
                              if (book.youtubeUrl != null)
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.play_circle_filled, color: Colors.red),
                                  ),
                                  title: const Text('Video Lecture'),
                                  subtitle: const Text('Watch on YouTube'),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () => _openUrl(book.youtubeUrl!),
                                ),
                              if (book.pdfUrl != null)
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.picture_as_pdf, color: Colors.orange),
                                  ),
                                  title: const Text('PDF Document'),
                                  subtitle: const Text('View or Download'),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () => _openUrl(book.pdfUrl!),
                                ),
                              if (book.ebookUrl != null)
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.menu_book, color: Colors.green),
                                  ),
                                  title: const Text('E-Book'),
                                  subtitle: const Text('Read Online'),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () => _openUrl(book.ebookUrl!),
                                ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _placeHold(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final booksProvider = context.read<BooksProvider>();
    final book = booksProvider.selectedBook;

    if (authProvider.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to place holds')),
      );
      return;
    }

    // Fetch libraries first
    final libraries = await _userService.getLibraries();
    if (!mounted || libraries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load pickup locations')),
      );
      return;
    }

    // Show confirmation dialog with pickup selection
    Library? selectedLibrary = libraries.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.bookmark_add,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Request This Book')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book title
                if (book != null) ...[
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
                ],

                // Explanation
                const Text(
                  'You are requesting to borrow this book. Our librarian will review and confirm your hold request.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Pickup location dropdown
                const Text(
                  'Pickup Location',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 16),

                // Important notes
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
                        '• Check your Holds tab for status updates\n'
                        '• You will be notified when ready for pickup\n'
                        '• Holds must be collected within 5 days',
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
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _userService.placeHold(
        biblioId: widget.biblioId,
        pickupLibraryId: selectedLibrary!.libraryId,
      );

      // Dismiss loading
      if (mounted) Navigator.pop(context);

      if (result.success && mounted) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: const Text('Request Submitted'),
            content: const Text(
              'Your hold request has been submitted successfully.\n\n'
              'Please check your Holds tab for updates. You will be notified when the book is ready for pickup.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to place hold'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openEbook(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  bool _hasAnyMedia(book) {
    return book.youtubeUrl != null ||
        book.pdfUrl != null ||
        book.ebookUrl != null;
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value!,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
