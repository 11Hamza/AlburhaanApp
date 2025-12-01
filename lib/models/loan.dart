import 'book.dart';

class Loan {
  final int checkoutId;
  final int patronId;
  final int? itemId;
  final int? biblioId;
  final String dueDate;
  final String? issueDate;
  final int renewals;
  final bool isOverdue;
  final int daysUntilDue;
  final bool canRenew;
  final String? renewalError;
  final Book? book;

  Loan({
    required this.checkoutId,
    required this.patronId,
    this.itemId,
    this.biblioId,
    required this.dueDate,
    this.issueDate,
    this.renewals = 0,
    this.isOverdue = false,
    this.daysUntilDue = 0,
    this.canRenew = true,
    this.renewalError,
    this.book,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      checkoutId: json['checkoutId'] ?? 0,
      patronId: json['patronId'] ?? 0,
      itemId: json['itemId'],
      biblioId: json['biblioId'],
      dueDate: json['dueDate'] ?? '',
      issueDate: json['issueDate'],
      renewals: json['renewals'] ?? 0,
      isOverdue: json['isOverdue'] ?? false,
      daysUntilDue: json['daysUntilDue'] ?? 0,
      canRenew: json['canRenew'] ?? true,
      renewalError: json['renewalError'],
      book: json['book'] != null ? Book.fromJson(json['book']) : null,
    );
  }

  DateTime get dueDateParsed => DateTime.parse(dueDate);

  String get statusText {
    if (isOverdue) return 'Overdue';
    if (daysUntilDue <= 3) return 'Due Soon';
    return 'On Loan';
  }
}

class LoansSummary {
  final int total;
  final int overdue;
  final int dueSoon;

  LoansSummary({
    this.total = 0,
    this.overdue = 0,
    this.dueSoon = 0,
  });

  factory LoansSummary.fromJson(Map<String, dynamic> json) {
    return LoansSummary(
      total: json['total'] ?? 0,
      overdue: json['overdue'] ?? 0,
      dueSoon: json['dueSoon'] ?? 0,
    );
  }
}

class LoanHistory {
  final int checkoutId;
  final int? itemId;
  final int? biblioId;
  final String? issueDate;
  final String? returnDate;
  final Book? book;

  LoanHistory({
    required this.checkoutId,
    this.itemId,
    this.biblioId,
    this.issueDate,
    this.returnDate,
    this.book,
  });

  factory LoanHistory.fromJson(Map<String, dynamic> json) {
    return LoanHistory(
      checkoutId: json['checkoutId'] ?? 0,
      itemId: json['itemId'],
      biblioId: json['biblioId'],
      issueDate: json['issueDate'],
      returnDate: json['returnDate'],
      book: json['book'] != null ? Book.fromJson(json['book']) : null,
    );
  }
}
