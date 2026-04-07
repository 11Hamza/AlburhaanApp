# Al-Burhaan Library App

A Flutter mobile application for Al-Burhaan Library, integrating with a Next.js backend hosted on Vercel and the Koha Library Management System.

## Project Architecture

```
AlburhaanApp/                    # Flutter frontend (this repository)
├── lib/
│   ├── models/                  # Data models
│   ├── services/                # API services
│   ├── providers/               # State management
│   ├── screens/                 # UI screens
│   ├── l10n/                    # Localization
│   └── utils/                   # Constants and utilities
├── android/                     # Android platform files
├── ios/                         # iOS platform files
├── web/                         # Web platform files
└── pubspec.yaml
```

**Backend**: Hosted separately on Vercel at `https://alburhaan-backend.vercel.app`

## Features

### Core Functionality
- **Book Browsing**: View library catalog with cover images, details, and availability
- **Advanced Search**: Search by title, author, ISBN with Zebra search integration
- **Filtering**: Filter books by subjects (MARC 650$a) and classifications (MARC 942$2)
- **Multi-Library Support**: Switch between Al-Burhaan library branches

### User Features
- **Authentication**: Login with library card number + password, or guest mode
- **Digital Library Card**: Scannable QR code and barcode for physical checkouts
- **User Profile**: View account details, loans summary, and settings
- **Book Loans**: View current loans, loan history, renew books
- **Holds/Reservations**: Place holds on unavailable books, manage reservations
- **Favorites**: Save books for later (persisted in PostgreSQL)

### Multi-Language Support
- English (en)
- Arabic (ar) - RTL support
- Urdu (ur) - RTL support

### UI Features
- Dark mode support
- Responsive design for phones and tablets
- Offline-capable with cached data

## Tech Stack

- **Framework**: Flutter 3.0+
- **State Management**: Provider
- **HTTP Client**: http package with token refresh
- **Storage**: SharedPreferences for local data
- **UI Libraries**: cached_network_image, qr_flutter, barcode_widget

## Screens

| Screen | Description |
|--------|-------------|
| Splash | Initial loading with auth check |
| Login | Library card + password or guest mode |
| Home | Book grid with category filters |
| Search | Advanced search with author/ISBN filters |
| Book Detail | Full book info, availability, hold button |
| Loans | Current loans with renew, tabbed with holds |
| Holds | Active reservations with cancel option |
| Profile | User info, settings, language/theme toggle |
| Library Card | Digital card with QR/barcode toggle |
| Favorites | Saved books with swipe-to-delete |

## Setup

```bash
# Install dependencies
flutter pub get

# Configure API URL in lib/utils/constants.dart if needed
# Default points to production: https://alburhaan-backend.vercel.app/api

# Run the app
flutter run
```

### API Configuration

The API URL is configured in `lib/utils/constants.dart`:
- **Production**: `https://alburhaan-backend.vercel.app/api`
- **Android Emulator**: `http://10.0.2.2:3000/api` (for local backend testing)

## API Endpoints

The backend provides these endpoints:

| Category | Endpoints | Description |
|----------|-----------|-------------|
| Auth | `/api/auth/login`, `/api/auth/guest`, `/api/auth/logout`, `/api/auth/refresh` | Authentication |
| Books | `/api/books`, `/api/books/:id`, `/api/books/:id/availability`, `/api/books/search` | Book catalog |
| Filters | `/api/filters/subjects`, `/api/filters/classifications`, `/api/filters/languages` | Filter options |
| User | `/api/user/profile`, `/api/user/card`, `/api/user/summary` | User data |
| Loans | `/api/loans`, `/api/loans/:id`, `/api/loans/:id/renew`, `/api/loans/history`, `/api/loans/renew-all` | Loan management |
| Holds | `/api/holds`, `/api/holds/:id` | Hold management |
| Favorites | `/api/favorites`, `/api/favorites/:id` | Favorites |
| Libraries | `/api/libraries`, `/api/libraries/:id` | Library branches |

## Koha Integration

The app integrates with Koha Library Management System for:
- Patron authentication (Basic Auth to Koha API)
- Book catalog (Biblios API)
- Checkouts/Loans management
- Holds/Reservations
- Patron information

### MARC Fields Used for Filtering
- **942$2**: Classification scheme (e.g., "Library of Congress Classification")
- **650$a**: Subject headings (e.g., "Tajwid", "Makharij of Letters")

## Development Notes

### Guest Mode
Guest users authenticate using a pre-configured Koha patron account. This allows browsing the catalog without personal credentials.

### Token Refresh
JWT tokens expire after 24 hours. The frontend automatically refreshes tokens when API calls return 401 errors.

### Offline Support
The frontend caches book data and user preferences locally using SharedPreferences for offline access.

## License

Private - Al-Burhaan Library
