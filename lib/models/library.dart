class Library {
  final String libraryId;
  final String name;
  final String? address1;
  final String? address2;
  final String? address3;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? phone;
  final String? fax;
  final String? email;
  final String? url;
  final String? notes;
  final bool isActive;

  Library({
    required this.libraryId,
    required this.name,
    this.address1,
    this.address2,
    this.address3,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.phone,
    this.fax,
    this.email,
    this.url,
    this.notes,
    this.isActive = true,
  });

  String get fullAddress {
    final parts = [address1, address2, address3, city, state, postalCode, country]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  factory Library.fromJson(Map<String, dynamic> json) {
    return Library(
      libraryId: json['libraryId'] ?? '',
      name: json['name'] ?? '',
      address1: json['address1'],
      address2: json['address2'],
      address3: json['address3'],
      city: json['city'],
      state: json['state'],
      postalCode: json['postalCode'],
      country: json['country'],
      phone: json['phone'],
      fax: json['fax'],
      email: json['email'],
      url: json['url'],
      notes: json['notes'],
      isActive: json['isActive'] ?? true,
    );
  }
}
