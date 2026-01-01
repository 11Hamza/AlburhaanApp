import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // App
      'app_name': 'Al-Burhaan Library',

      // Auth
      'login': 'Login',
      'logout': 'Logout',
      'welcome': 'Welcome to',
      'card_number': 'Library Card Number',
      'password': 'Password',
      'continue_guest': 'Continue as Guest',
      'login_failed': 'Login failed',

      // Navigation
      'home': 'Home',
      'search': 'Search',
      'loans': 'Loans',
      'profile': 'Profile',

      // Books
      'books': 'Books',
      'book_details': 'Book Details',
      'author': 'Author',
      'publisher': 'Publisher',
      'isbn': 'ISBN',
      'language': 'Language',
      'year': 'Year',
      'subjects': 'Subjects',
      'available': 'Available',
      'not_available': 'Not Available',
      'place_hold': 'Place Hold',
      'read_book': 'Read',

      // Search
      'search_books': 'Search books...',
      'advanced_search': 'Advanced Search',
      'filters': 'Filters',
      'apply_filters': 'Apply Filters',
      'clear': 'Clear',

      // Loans
      'current_loans': 'Current Loans',
      'loan_history': 'Loan History',
      'due_date': 'Due Date',
      'renew': 'Renew',
      'renew_all': 'Renew All',
      'overdue': 'Overdue',
      'due_soon': 'Due Soon',

      // Holds
      'holds': 'Holds',
      'place_hold': 'Place Hold',
      'cancel_hold': 'Cancel Hold',
      'pickup_location': 'Pickup Location',
      'queue_position': 'Queue Position',
      'ready_pickup': 'Ready for Pickup',

      // Favorites
      'favorites': 'Favorites',
      'add_favorite': 'Add to Favorites',
      'remove_favorite': 'Remove from Favorites',

      // Profile
      'library_card': 'Library Card',
      'settings': 'Settings',
      'dark_mode': 'Dark Mode',
      'notifications': 'Notifications',

      // General
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'no_results': 'No results found',
    },
    'ar': {
      // App
      'app_name': 'مكتبة البرهان',

      // Auth
      'login': 'تسجيل الدخول',
      'logout': 'تسجيل الخروج',
      'welcome': 'مرحباً بك في',
      'card_number': 'رقم بطاقة المكتبة',
      'password': 'كلمة المرور',
      'continue_guest': 'المتابعة كزائر',
      'login_failed': 'فشل تسجيل الدخول',

      // Navigation
      'home': 'الرئيسية',
      'search': 'بحث',
      'loans': 'الإعارات',
      'profile': 'الملف الشخصي',

      // Books
      'books': 'الكتب',
      'book_details': 'تفاصيل الكتاب',
      'author': 'المؤلف',
      'publisher': 'الناشر',
      'isbn': 'رقم ISBN',
      'language': 'اللغة',
      'year': 'السنة',
      'subjects': 'المواضيع',
      'available': 'متاح',
      'not_available': 'غير متاح',
      'place_hold': 'حجز',
      'read_book': 'قراءة',

      // Search
      'search_books': 'البحث عن كتب...',
      'advanced_search': 'بحث متقدم',
      'filters': 'التصفية',
      'apply_filters': 'تطبيق التصفية',
      'clear': 'مسح',

      // Loans
      'current_loans': 'الإعارات الحالية',
      'loan_history': 'سجل الإعارات',
      'due_date': 'تاريخ الاستحقاق',
      'renew': 'تجديد',
      'renew_all': 'تجديد الكل',
      'overdue': 'متأخر',
      'due_soon': 'قريب الاستحقاق',

      // Holds
      'holds': 'الحجوزات',
      'place_hold': 'إضافة حجز',
      'cancel_hold': 'إلغاء الحجز',
      'pickup_location': 'موقع الاستلام',
      'queue_position': 'الترتيب في الطابور',
      'ready_pickup': 'جاهز للاستلام',

      // Favorites
      'favorites': 'المفضلة',
      'add_favorite': 'إضافة للمفضلة',
      'remove_favorite': 'إزالة من المفضلة',

      // Profile
      'library_card': 'بطاقة المكتبة',
      'settings': 'الإعدادات',
      'dark_mode': 'الوضع الداكن',
      'notifications': 'الإشعارات',

      // General
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'retry': 'إعادة المحاولة',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'save': 'حفظ',
      'no_results': 'لا توجد نتائج',
    },
    'ur': {
      // App
      'app_name': 'البرہان لائبریری',

      // Auth
      'login': 'لاگ ان',
      'logout': 'لاگ آؤٹ',
      'welcome': 'خوش آمدید',
      'card_number': 'لائبریری کارڈ نمبر',
      'password': 'پاس ورڈ',
      'continue_guest': 'مہمان کے طور پر جاری رکھیں',
      'login_failed': 'لاگ ان ناکام',

      // Navigation
      'home': 'ہوم',
      'search': 'تلاش',
      'loans': 'ادھار',
      'profile': 'پروفائل',

      // Books
      'books': 'کتابیں',
      'book_details': 'کتاب کی تفصیلات',
      'author': 'مصنف',
      'publisher': 'ناشر',
      'isbn': 'ISBN نمبر',
      'language': 'زبان',
      'year': 'سال',
      'subjects': 'موضوعات',
      'available': 'دستیاب',
      'not_available': 'دستیاب نہیں',
      'place_hold': 'ریزرو کریں',
      'read_book': 'پڑھیں',

      // Search
      'search_books': 'کتابیں تلاش کریں...',
      'advanced_search': 'اعلیٰ تلاش',
      'filters': 'فلٹرز',
      'apply_filters': 'فلٹرز لگائیں',
      'clear': 'صاف کریں',

      // Loans
      'current_loans': 'موجودہ ادھار',
      'loan_history': 'ادھار کی تاریخ',
      'due_date': 'واپسی کی تاریخ',
      'renew': 'تجدید',
      'renew_all': 'سب تجدید کریں',
      'overdue': 'تاخیر',
      'due_soon': 'جلد واپسی',

      // Holds
      'holds': 'ریزرویشن',
      'place_hold': 'ریزرو کریں',
      'cancel_hold': 'ریزرویشن منسوخ',
      'pickup_location': 'وصولی کا مقام',
      'queue_position': 'قطار میں مقام',
      'ready_pickup': 'وصولی کے لیے تیار',

      // Favorites
      'favorites': 'پسندیدہ',
      'add_favorite': 'پسندیدہ میں شامل',
      'remove_favorite': 'پسندیدہ سے ہٹائیں',

      // Profile
      'library_card': 'لائبریری کارڈ',
      'settings': 'ترتیبات',
      'dark_mode': 'ڈارک موڈ',
      'notifications': 'اطلاعات',

      // General
      'loading': 'لوڈ ہو رہا ہے...',
      'error': 'خرابی',
      'retry': 'دوبارہ کوشش',
      'cancel': 'منسوخ',
      'confirm': 'تصدیق',
      'save': 'محفوظ',
      'no_results': 'کوئی نتیجہ نہیں ملا',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // Convenience getters
  String get appName => translate('app_name');
  String get login => translate('login');
  String get logout => translate('logout');
  String get home => translate('home');
  String get search => translate('search');
  String get loans => translate('loans');
  String get profile => translate('profile');
  String get favorites => translate('favorites');
  String get holds => translate('holds');
  String get settings => translate('settings');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar', 'ur'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
