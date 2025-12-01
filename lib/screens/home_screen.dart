import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/books_provider.dart';
import '../models/book.dart';
import 'book_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Al-Burhaan Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilters(context),
          ),
        ],
      ),
      body: Consumer<BooksProvider>(
        builder: (context, booksProvider, _) {
          if (booksProvider.isLoading && booksProvider.books.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (booksProvider.error != null && booksProvider.books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(booksProvider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => booksProvider.loadBooks(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (booksProvider.books.isEmpty) {
            return const Center(
              child: Text('No books found'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => booksProvider.refresh(),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification) {
                  if (notification.metrics.extentAfter < 200) {
                    booksProvider.loadMoreBooks();
                  }
                }
                return false;
              },
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: booksProvider.books.length +
                    (booksProvider.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= booksProvider.books.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final book = booksProvider.books[index];
                  return _BookCard(book: book);
                },
              ),
            ),
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
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _FiltersSheet(
          booksProvider: booksProvider,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;

  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BookDetailScreen(biblioId: book.biblioId),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Book Cover
            Expanded(
              flex: 3,
              child: book.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: book.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: const Center(
                          child: Icon(Icons.book, size: 48),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: const Center(
                          child: Icon(Icons.book, size: 48),
                        ),
                      ),
                    )
                  : Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: const Center(
                        child: Icon(Icons.book, size: 48),
                      ),
                    ),
            ),
            // Book Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    if (book.author != null)
                      Text(
                        book.author!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
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

class _FiltersSheet extends StatelessWidget {
  final BooksProvider booksProvider;
  final ScrollController scrollController;

  const _FiltersSheet({
    required this.booksProvider,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Title
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
              // Subjects
              if (booksProvider.subjects.isNotEmpty) ...[
                Text(
                  'Subject',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: booksProvider.subjects.take(20).map((subject) {
                    final isSelected =
                        booksProvider.selectedSubject == subject.value;
                    return FilterChip(
                      label: Text(subject.value),
                      selected: isSelected,
                      onSelected: (selected) {
                        booksProvider.setSubjectFilter(
                          selected ? subject.value : null,
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Languages
              if (booksProvider.languages.isNotEmpty) ...[
                Text(
                  'Language',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: booksProvider.languages.map((language) {
                    final isSelected =
                        booksProvider.selectedLanguage == language.value;
                    return FilterChip(
                      label: Text(language.value),
                      selected: isSelected,
                      onSelected: (selected) {
                        booksProvider.setLanguageFilter(
                          selected ? language.value : null,
                        );
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
          child: FilledButton(
            onPressed: () {
              booksProvider.applyFilters();
              Navigator.pop(context);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text('Apply Filters'),
            ),
          ),
        ),
      ],
    );
  }
}
