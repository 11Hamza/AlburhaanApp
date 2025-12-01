# Al-Burhaan Library App

A full-featured library management mobile application for Al-Burhaan Library, built with Flutter frontend and Next.js backend, integrating with the Koha Library Management System.

## Project Architecture

```
AlburhaanApp/                    # This repository
├── burhaan-backend/             # Next.js API backend
│   ├── src/app/api/             # API routes
│   ├── src/lib/                 # Core libraries (Koha client, auth, db)
│   └── prisma/                  # Database schema
└── README.md                    # This file

burhaan-app-frontend/            # Separate repository - Flutter frontend
├── lib/
│   ├── models/                  # Data models
│   ├── services/                # API services
│   ├── providers/               # State management
│   ├── screens/                 # UI screens
│   ├── l10n/                    # Localization
│   └── utils/                   # Constants and utilities
└── pubspec.yaml
```

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

## Backend (burhaan-backend)

### Tech Stack
- **Framework**: Next.js 14+ (App Router, JavaScript)
- **Database**: PostgreSQL with Prisma ORM (in-memory fallback for development)
- **Auth**: JWT tokens with refresh capability
- **External API**: Koha REST API

### API Endpoints

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

### Setup

```bash
cd burhaan-backend

# Install dependencies
npm install

# Configure environment
cp .env.local.example .env.local
# Edit .env.local with your Koha API credentials

# Start development server
npm run dev
```

The API will be available at `http://localhost:3000`

## Frontend (burhaan-app-frontend)

### Tech Stack
- **Framework**: Flutter 3.0+
- **State Management**: Provider
- **HTTP Client**: http package with token refresh
- **Storage**: SharedPreferences for local data
- **UI Libraries**: cached_network_image, qr_flutter, barcode_widget

### Screens

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

### Setup

```bash
cd burhaan-app-frontend

# Install dependencies
flutter pub get

# Configure API URL in lib/utils/constants.dart
# For Android emulator, use 10.0.2.2 instead of localhost

# Run the app
flutter run
```

## Testing

### Start the Backend
```bash
cd burhaan-backend
npm run dev
```

### Run the Frontend
```bash
cd burhaan-app-frontend
flutter run
```

### Test Endpoints
```bash
# Health check
curl http://localhost:3000/api/health

# Guest login
curl -X POST http://localhost:3000/api/auth/guest

# Get books
curl http://localhost:3000/api/books

# Search books
curl "http://localhost:3000/api/books/search?q=tajweed"
```

## Environment Variables

### Backend (.env.local)
```
KOHA_BASE_URL=https://library.al-burhaan.org/api/v1
KOHA_API_KEY=your_api_key
KOHA_API_SECRET=your_api_secret
KOHA_GUEST_USERNAME=guest
KOHA_GUEST_PASSWORD=guest_password
JWT_SECRET=your_jwt_secret
DATABASE_URL=postgresql://user:pass@localhost:5432/burhaan
```

## Koha Integration

The app integrates with Koha Library Management System for:
- Patron authentication (Basic Auth to Koha API)
- Book catalog (Biblios API)
- Checkouts/Loans management
- Holds/Reservations
- Patron information

### MARC Fields Used for Filtering
- **942$2**: Classification scheme (e.g., "Library of Congress Classification")
- **650$a**: Subject headings (e.g., "Tajwid", "Makhārij of Letters")

## Development Notes

### Guest Mode
Guest users authenticate using a pre-configured Koha patron account. This allows browsing the catalog without personal credentials.

### Token Refresh
JWT tokens expire after 24 hours. The frontend automatically refreshes tokens when API calls return 401 errors.

### Offline Support
The frontend caches book data and user preferences locally using SharedPreferences for offline access.

## License

Private - Al-Burhaan Library
