class User {
  final int patronId;
  final String cardNumber;
  final String firstName;
  final String surname;
  final String? email;
  final String? phone;
  final String? libraryId;
  final String? categoryId;
  final bool isGuest;

  User({
    required this.patronId,
    required this.cardNumber,
    required this.firstName,
    required this.surname,
    this.email,
    this.phone,
    this.libraryId,
    this.categoryId,
    this.isGuest = false,
  });

  String get fullName => '$firstName $surname'.trim();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      patronId: json['patronId'] ?? 0,
      cardNumber: json['cardNumber'] ?? '',
      firstName: json['firstName'] ?? '',
      surname: json['surname'] ?? '',
      email: json['email'],
      phone: json['phone'],
      libraryId: json['libraryId'],
      categoryId: json['categoryId'],
      isGuest: _parseBool(json['isGuest']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  factory User.guest() {
    return User(
      patronId: 0,
      cardNumber: 'GUEST',
      firstName: 'Guest',
      surname: 'User',
      isGuest: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patronId': patronId,
      'cardNumber': cardNumber,
      'firstName': firstName,
      'surname': surname,
      'email': email,
      'phone': phone,
      'libraryId': libraryId,
      'categoryId': categoryId,
      'isGuest': isGuest,
    };
  }
}

class UserPreferences {
  final String language;
  final String theme;
  final bool notificationsEnabled;
  final String? homeLibraryId;

  UserPreferences({
    this.language = 'en',
    this.theme = 'light',
    this.notificationsEnabled = true,
    this.homeLibraryId,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      language: json['language'] ?? 'en',
      theme: json['theme'] ?? 'light',
      notificationsEnabled: _parseBool(json['notificationsEnabled'], defaultValue: true),
      homeLibraryId: json['homeLibraryId'],
    );
  }

  static bool _parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return defaultValue;
  }
}

class LibraryCard {
  final String cardNumber;
  final int patronId;
  final String fullName;
  final String? categoryId;
  final String? libraryId;
  final String? dateEnrolled;
  final String? dateExpiry;
  final bool isExpired;
  final int? daysUntilExpiry;
  final String status;
  final String? qrCode;
  final String? barcode;

  LibraryCard({
    required this.cardNumber,
    required this.patronId,
    required this.fullName,
    this.categoryId,
    this.libraryId,
    this.dateEnrolled,
    this.dateExpiry,
    this.isExpired = false,
    this.daysUntilExpiry,
    this.status = 'active',
    this.qrCode,
    this.barcode,
  });

  factory LibraryCard.fromJson(Map<String, dynamic> json) {
    final card = json['card'] ?? {};
    return LibraryCard(
      cardNumber: card['cardNumber'] ?? '',
      patronId: card['patronId'] ?? 0,
      fullName: card['fullName'] ?? '',
      categoryId: card['categoryId'],
      libraryId: card['libraryId'],
      dateEnrolled: card['dateEnrolled'],
      dateExpiry: card['dateExpiry'],
      isExpired: _parseBool(card['isExpired']),
      daysUntilExpiry: card['daysUntilExpiry'],
      status: card['status'] ?? 'active',
      qrCode: json['qrCode'],
      barcode: json['barcode'],
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }
}

class AccountSummary {
  final int loansTotal;
  final int loansOverdue;
  final int holdsTotal;
  final int holdsReady;
  final int favoritesTotal;
  final int recentlyViewedTotal;

  AccountSummary({
    this.loansTotal = 0,
    this.loansOverdue = 0,
    this.holdsTotal = 0,
    this.holdsReady = 0,
    this.favoritesTotal = 0,
    this.recentlyViewedTotal = 0,
  });

  factory AccountSummary.fromJson(Map<String, dynamic> json) {
    final loans = json['loans'] ?? {};
    final holds = json['holds'] ?? {};
    final favorites = json['favorites'] ?? {};
    final recentlyViewed = json['recentlyViewed'] ?? {};

    return AccountSummary(
      loansTotal: loans['total'] ?? 0,
      loansOverdue: loans['overdue'] ?? 0,
      holdsTotal: holds['total'] ?? 0,
      holdsReady: holds['ready'] ?? 0,
      favoritesTotal: favorites['total'] ?? 0,
      recentlyViewedTotal: recentlyViewed['total'] ?? 0,
    );
  }
}
