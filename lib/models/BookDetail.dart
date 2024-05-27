class BookDetail {
  final int biblioId;
  final String title;
  final String author;
  final String? isbn;
  final String? publicationYear;
  final String? publisher;
  final String? imageUrl;
  final String? ebookUrl;
  final String? shelvingLocation;
  final String? callNumber;
  final String? language;
  final String? physicalDescription;
  final List<String>? subjects;
  final String? series;
  final String? notes;
  final String? youtubeUrl; // Add youtubeUrl for video content
  final List<String>? urls;
  final String? electronicLocation;
  final List<Map<String, dynamic>>? holdings;

  BookDetail({
    required this.biblioId,
    required this.title,
    required this.author,
    this.isbn,
    this.publicationYear,
    this.publisher,
    this.imageUrl,
    this.ebookUrl,
    this.shelvingLocation,
    this.callNumber,
    this.language,
    this.physicalDescription,
    this.subjects,
    this.series,
    this.notes,
    this.youtubeUrl, // Initialize youtubeUrl
    this.urls,
    this.electronicLocation,
    this.holdings,
  });

  factory BookDetail.fromJson(Map<String, dynamic> json) {
    String? youtubeUrl;
    if (json['url'] != null) {
      final uri = Uri.parse(json['url']);
      if (uri.host.contains('youtu.be')) {
        youtubeUrl = 'https://www.youtube.com/embed/${uri.pathSegments.last}';
      } else {
        youtubeUrl = json['url'];
      }
    }

    return BookDetail(
      biblioId: json['biblio_id'],
      title: json['title'],
      author: json['author'],
      isbn: json['isbn'],
      publicationYear: json['publication_year'],
      publisher: json['publisher'],
      imageUrl: "https://library.al-burhaan.org/cgi-bin/koha/opac-image.pl?thumbnail=1&biblionumber=${json['biblio_id']}&filetype=image",
      ebookUrl: json['ebook_url'],
      shelvingLocation: json['shelving_location'],
      callNumber: json['call_number'],
      language: json['language'],
      physicalDescription: json['physical_description'],
      subjects: (json['subjects'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      series: json['series'],
      notes: json['notes'],
      youtubeUrl: youtubeUrl, // Assign the modified YouTube URL
      urls: (json['urls'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      electronicLocation: json['electronic_location'],
      holdings: (json['holdings'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'biblio_id': biblioId,
      'title': title,
      'author': author,
      'isbn': isbn,
      'publication_year': publicationYear,
      'publisher': publisher,
      'image_url': imageUrl,
      'ebook_url': ebookUrl,
      'shelving_location': shelvingLocation,
      'call_number': callNumber,
      'language': language,
      'physical_description': physicalDescription,
      'subjects': subjects?.map((e) => e.toString()).toList(),
      'series': series,
      'notes': notes,
      'youtube_url': youtubeUrl, // Include youtubeUrl in JSON
      'urls': urls?.map((e) => e.toString()).toList(),
      'electronic_location': electronicLocation,
      'holdings': holdings?.map((e) => Map<String, dynamic>.from(e)).toList(),
    };
  }
}
