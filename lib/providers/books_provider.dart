import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/books_service.dart';

class BooksProvider extends ChangeNotifier {
  final BooksService _booksService = BooksService();

  List<Book> _books = [];
  Book? _selectedBook;
  BookAvailability? _selectedBookAvailability;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _currentQuery;
  int? _totalBooks; // Total book count from API

  // Filter options
  List<FilterOption> _subjects = [];
  List<FilterOption> _classifications = [];
  List<FilterOption> _languages = [];
  bool _filtersLoaded = false;

  // Selected filters
  String? _selectedSubject;
  String? _selectedClassification;
  String? _selectedLanguage;

  // Getters
  List<Book> get books => _books;
  Book? get selectedBook => _selectedBook;
  BookAvailability? get selectedBookAvailability => _selectedBookAvailability;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int? get totalBooks => _totalBooks;

  List<FilterOption> get subjects => _subjects;
  List<FilterOption> get classifications => _classifications;
  List<FilterOption> get languages => _languages;
  bool get filtersLoaded => _filtersLoaded;

  String? get selectedSubject => _selectedSubject;
  String? get selectedClassification => _selectedClassification;
  String? get selectedLanguage => _selectedLanguage;

  /// Load initial books
  Future<void> loadBooks({String? query}) async {
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    _currentQuery = query;
    notifyListeners();

    try {
      // Fetch total count in parallel if not already loaded
      final futures = <Future>[
        _booksService.getBooks(
          page: 1,
          perPage: 30,  // Load more items per page for faster browsing
          query: query,
          subject: _selectedSubject,
          language: _selectedLanguage,
        ),
      ];

      // Only fetch count if we don't have it or no filters applied
      final hasFilters = query != null || _selectedSubject != null || _selectedLanguage != null;
      if (_totalBooks == null && !hasFilters) {
        futures.add(_booksService.getTotalBookCount());
      }

      final results = await Future.wait(futures);
      final result = results[0] as PaginatedResult<Book>;

      _books = result.items;
      _hasMore = result.hasMore;

      // Use result.total if available, otherwise use fetched count, or keep existing
      if (result.total != null) {
        _totalBooks = result.total;
      } else if (results.length > 1 && results[1] != null) {
        _totalBooks = results[1] as int;
      }

      _currentPage = 1;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load more books (pagination)
  Future<void> loadMoreBooks() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _booksService.getBooks(
        page: _currentPage + 1,
        perPage: 30,  // Load more items per page for faster browsing
        query: _currentQuery,
        subject: _selectedSubject,
        language: _selectedLanguage,
      );

      _books.addAll(result.items);
      _hasMore = result.hasMore;
      if (result.total != null) _totalBooks = result.total;
      _currentPage++;
    } catch (e) {
      _error = e.toString();
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  /// Search books
  Future<void> searchBooks({
    String? keyword,
    String? title,
    String? author,
    String? isbn,
    String? subject,
    String? language,
    String? yearFrom,
    String? yearTo,
  }) async {
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final result = await _booksService.searchBooks(
        keyword: keyword,
        title: title,
        author: author,
        isbn: isbn,
        subject: subject ?? _selectedSubject,
        language: language ?? _selectedLanguage,
        yearFrom: yearFrom,
        yearTo: yearTo,
      );

      _books = result.items;
      _hasMore = result.hasMore;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load book details
  Future<void> loadBookDetails(int biblioId) async {
    _isLoading = true;
    _error = null;
    _selectedBook = null;
    _selectedBookAvailability = null;
    notifyListeners();

    try {
      // Load book and availability in parallel
      final results = await Future.wait([
        _booksService.getBookById(biblioId),
        _booksService.getBookAvailability(biblioId),
      ]);

      _selectedBook = results[0] as Book?;
      _selectedBookAvailability = results[1] as BookAvailability?;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load filter options
  Future<void> loadFilters() async {
    if (_filtersLoaded) return;

    try {
      final results = await Future.wait([
        _booksService.getSubjects(),
        _booksService.getClassifications(),
        _booksService.getLanguages(),
      ]);

      _subjects = results[0];
      _classifications = results[1];
      _languages = results[2];
      _filtersLoaded = true;
    } catch (e) {
      _error = e.toString();
    }

    notifyListeners();
  }

  /// Set selected filters
  void setSubjectFilter(String? subject) {
    _selectedSubject = subject;
    notifyListeners();
  }

  void setClassificationFilter(String? classification) {
    _selectedClassification = classification;
    notifyListeners();
  }

  void setLanguageFilter(String? language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedSubject = null;
    _selectedClassification = null;
    _selectedLanguage = null;
    notifyListeners();
  }

  /// Apply filters and reload
  Future<void> applyFilters() async {
    await loadBooks(query: _currentQuery);
  }

  /// Clear selected book
  void clearSelectedBook() {
    _selectedBook = null;
    _selectedBookAvailability = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh books
  Future<void> refresh() async {
    await loadBooks(query: _currentQuery);
  }
}
