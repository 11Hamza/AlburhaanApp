# Al-Burhaan Library Flutter App

Mobile application for the Al-Burhaan Library, connecting to the Next.js backend API.

## Features

- **Browse Books**: View library catalog with images and details
- **Search**: Search by title, author, ISBN with filters
- **Book Details**: Full metadata, availability, subjects
- **User Authentication**: Login with library card or guest mode
- **Digital Library Card**: QR code and barcode for scanning
- **Loans Management**: View current loans, renew books
- **Holds**: Place and manage reservations
- **Favorites**: Save books for later
- **Multi-Language**: English, Arabic, Urdu with RTL support
- **Dark Mode**: Light and dark theme support

## Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / Xcode for mobile development

### Installation

```bash
# Clone the repository
git clone <repo-url>
cd burhaan-app-frontend

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Configuration

Update the API URL in `lib/utils/constants.dart`:

```dart
static const String baseUrl = 'http://your-backend-url:3000/api';
```

For Android emulator, use `10.0.2.2` instead of `localhost`.

## Project Structure

```
lib/
├── main.dart              # App entry point
├── models/                # Data models
│   ├── book.dart
│   ├── user.dart
│   ├── loan.dart
│   ├── hold.dart
│   ├── library.dart
│   └── favorite.dart
├── services/              # API services
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── books_service.dart
│   ├── user_service.dart
│   └── storage_service.dart
├── providers/             # State management
│   ├── auth_provider.dart
│   ├── books_provider.dart
│   └── settings_provider.dart
├── screens/               # UI screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── main_screen.dart
│   ├── home_screen.dart
│   ├── book_detail_screen.dart
│   ├── search_screen.dart
│   ├── loans_screen.dart
│   ├── holds_screen.dart
│   ├── profile_screen.dart
│   ├── library_card_screen.dart
│   └── favorites_screen.dart
├── widgets/               # Reusable widgets
├── l10n/                  # Localization
│   └── app_localizations.dart
└── utils/                 # Utilities
    └── constants.dart
```

## Screens

| Screen | Description |
|--------|-------------|
| Splash | App loading with auth check |
| Login | Card number + password or guest |
| Home | Book grid with filters |
| Search | Advanced search with filters |
| Book Detail | Full book info, availability, hold |
| Loans | Current loans with renew |
| Holds | Active reservations |
| Profile | User info, settings, logout |
| Library Card | Digital card with QR/barcode |
| Favorites | Saved books |

## Localization

Supports 3 languages:
- English (en)
- Arabic (ar) - RTL
- Urdu (ur) - RTL

Add translations in `lib/l10n/app_localizations.dart`.

## State Management

Uses Provider for state management:
- `AuthProvider` - Authentication state
- `BooksProvider` - Books and filters
- `SettingsProvider` - Theme and language

## Backend Connection

The app connects to the Next.js backend API. Ensure:
1. Backend is running (`npm run dev` in backend folder)
2. API URL is correctly configured
3. For physical devices, use your computer's IP address

## Build

```bash
# Android
flutter build apk

# iOS
flutter build ios

# Web
flutter build web
```

## License

Private - Al-Burhaan Library
