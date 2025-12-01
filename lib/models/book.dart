class Book {
  final int biblioId;
  final String title;
  final String? author;
  final String? isbn;
  final String? publicationYear;
  final String? publisher;
  final String? language;
  final List<String> subjects;
  final String? callNumber;
  final String? shelfNumber;
  final String? physicalDescription;
  final String? series;
  final String? notes;
  final String? imageUrl;
  final String? ebookUrl;
  final String? youtubeUrl;

  Book({
    required this.biblioId,
    required this.title,
    this.author,
    this.isbn,
    this.publicationYear,
    this.publisher,
    this.language,
    this.subjects = const [],
    this.callNumber,
    this.shelfNumber,
    this.physicalDescription,
    this.series,
    this.notes,
    this.imageUrl,
    this.ebookUrl,
    this.youtubeUrl,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      biblioId: json['biblioId'] ?? 0,
      title: json['title'] ?? 'Unknown Title',
      author: json['author'],
      isbn: json['isbn'],
      publicationYear: json['publicationYear'],
      publisher: json['publisher'],
      language: json['language'],
      subjects: json['subjects'] != null
          ? List<String>.from(json['subjects'])
          : [],
      callNumber: json['callNumber'],
      shelfNumber: json['shelfNumber'],
      physicalDescription: json['physicalDescription'],
      series: json['series'],
      notes: json['notes'],
      imageUrl: json['imageUrl'],
      ebookUrl: json['ebookUrl'],
      youtubeUrl: json['youtubeUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'biblioId': biblioId,
      'title': title,
      'author': author,
      'isbn': isbn,
      'publicationYear': publicationYear,
      'publisher': publisher,
      'language': language,
      'subjects': subjects,
      'callNumber': callNumber,
      'shelfNumber': shelfNumber,
      'physicalDescription': physicalDescription,
      'series': series,
      'notes': notes,
      'imageUrl': imageUrl,
      'ebookUrl': ebookUrl,
      'youtubeUrl': youtubeUrl,
    };
  }
}

class BookAvailability {
  final int biblioId;
  final int totalCopies;
  final int availableCopies;
  final bool isAvailable;
  final List<BranchAvailability> branches;

  BookAvailability({
    required this.biblioId,
    required this.totalCopies,
    required this.availableCopies,
    required this.isAvailable,
    required this.branches,
  });

  factory BookAvailability.fromJson(Map<String, dynamic> json) {
    return BookAvailability(
      biblioId: json['biblioId'] ?? 0,
      totalCopies: json['totalCopies'] ?? 0,
      availableCopies: json['availableCopies'] ?? 0,
      isAvailable: json['isAvailable'] ?? false,
      branches: (json['branches'] as List?)
              ?.map((b) => BranchAvailability.fromJson(b))
              .toList() ??
          [],
    );
  }
}

class BranchAvailability {
  final String libraryId;
  final String libraryName;
  final int total;
  final int available;
  final int checkedOut;
  final int onHold;

  BranchAvailability({
    required this.libraryId,
    required this.libraryName,
    required this.total,
    required this.available,
    required this.checkedOut,
    required this.onHold,
  });

  factory BranchAvailability.fromJson(Map<String, dynamic> json) {
    return BranchAvailability(
      libraryId: json['libraryId'] ?? '',
      libraryName: json['libraryName'] ?? '',
      total: json['total'] ?? 0,
      available: json['available'] ?? 0,
      checkedOut: json['checkedOut'] ?? 0,
      onHold: json['onHold'] ?? 0,
    );
  }
}

class FilterOption {
  final String value;
  final String? valueAr;
  final String? valueUr;
  final int bookCount;

  FilterOption({
    required this.value,
    this.valueAr,
    this.valueUr,
    this.bookCount = 0,
  });

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    return FilterOption(
      value: json['value'] ?? json['code'] ?? '',
      valueAr: json['valueAr'] ?? json['nameAr'],
      valueUr: json['valueUr'] ?? json['nameUr'],
      bookCount: json['bookCount'] ?? 0,
    );
  }

  String getLocalizedValue(String locale) {
    if (locale == 'ar' && valueAr != null) return valueAr!;
    if (locale == 'ur' && valueUr != null) return valueUr!;
    return value;
  }
}
