# Al-Burhaan Library Backend

Next.js backend API for the Al-Burhaan Library mobile application. This backend acts as a middleware between the Flutter frontend and the Koha Library Management System.

## Features

- **Authentication**: Library card login, guest mode, JWT sessions
- **Book Catalog**: Browse, search, filter books with Koha integration
- **User Management**: Profile, digital library card with QR/barcode
- **Loans**: View current loans, loan history, renewals
- **Holds**: Place, view, and cancel holds
- **Favorites**: Save books (stored in PostgreSQL)
- **Multi-Library**: Support for multiple Al-Burhaan branches
- **Multi-Language**: English, Arabic, Urdu support

## Tech Stack

- **Framework**: Next.js 14+ (App Router)
- **Database**: PostgreSQL with Prisma ORM
- **Auth**: JWT tokens
- **External API**: Koha REST API

## Getting Started

### Prerequisites

- Node.js 18+
- PostgreSQL (optional, has in-memory fallback)
- Access to Koha API

### Installation

```bash
# Install dependencies
npm install

# Set up environment variables
cp .env.local.example .env.local
# Edit .env.local with your credentials

# Generate Prisma client (if using PostgreSQL)
npx prisma generate

# Run database migrations
npx prisma db push

# Start development server
npm run dev
```

## API Endpoints

Visit http://localhost:3000 after starting the server to see full API documentation.

### Quick Reference

| Category | Endpoints |
|----------|-----------|
| Auth | /api/auth/login, /api/auth/guest, /api/auth/logout |
| Books | /api/books, /api/books/:id, /api/books/search |
| Filters | /api/filters/subjects, /api/filters/classifications |
| User | /api/user/profile, /api/user/card, /api/user/summary |
| Loans | /api/loans, /api/loans/:id/renew, /api/loans/renew-all |
| Holds | /api/holds, /api/holds/:id |
| Favorites | /api/favorites, /api/favorites/:id |
| Libraries | /api/libraries, /api/libraries/:id |

## Development

```bash
npm run dev    # Development server
npm run build  # Build for production
npm start      # Start production server
npm run lint   # Lint code
```

## License

Private - Al-Burhaan Library
