import 'book.dart';

class Hold {
  final int holdId;
  final int patronId;
  final int biblioId;
  final int? itemId;
  final String holdDate;
  final String? expirationDate;
  final String pickupLibraryId;
  final String status;
  final String statusText;
  final int? priority;
  final String? notes;
  final Book? book;

  Hold({
    required this.holdId,
    required this.patronId,
    required this.biblioId,
    this.itemId,
    required this.holdDate,
    this.expirationDate,
    required this.pickupLibraryId,
    required this.status,
    required this.statusText,
    this.priority,
    this.notes,
    this.book,
  });

  factory Hold.fromJson(Map<String, dynamic> json) {
    return Hold(
      holdId: json['holdId'] ?? 0,
      patronId: json['patronId'] ?? 0,
      biblioId: json['biblioId'] ?? 0,
      itemId: json['itemId'],
      holdDate: json['holdDate'] ?? '',
      expirationDate: json['expirationDate'],
      pickupLibraryId: json['pickupLibraryId'] ?? '',
      status: json['status'] ?? '',
      statusText: json['statusText'] ?? 'Pending',
      priority: json['priority'],
      notes: json['notes'],
      book: json['book'] != null ? Book.fromJson(json['book']) : null,
    );
  }

  bool get isReady => status == 'W' || status == 'waiting' || statusText == 'Ready for Pickup';
  bool get isInTransit => status == 'T' || status == 'transit';

  DateTime get holdDateParsed => DateTime.parse(holdDate);
}

class HoldsSummary {
  final int total;
  final int ready;
  final int pending;

  HoldsSummary({
    this.total = 0,
    this.ready = 0,
    this.pending = 0,
  });

  factory HoldsSummary.fromJson(Map<String, dynamic> json) {
    return HoldsSummary(
      total: json['total'] ?? 0,
      ready: json['ready'] ?? 0,
      pending: json['pending'] ?? 0,
    );
  }
}
