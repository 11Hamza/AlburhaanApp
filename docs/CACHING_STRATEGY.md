# Al-Burhaan App Caching Strategy

## Problem Statement

- **5,000-10,000 books** in the library
- **Vercel free tier** limits (100K function invocations/month)
- **1,000+ users** expected
- Current issues:
  - Books pagination doesn't load instantly when scrolling
  - Videos/ebooks only load when clicking buttons
  - Backend filters ALL books for videos/ebooks (inefficient)
  - Too many API calls per user

## Cost Analysis

| Scenario | Calls/User | 1000 Users | Vercel Free Tier |
|----------|------------|------------|------------------|
| Current (no cache) | ~50-100/session | 50K-100K/month | EXCEEDS LIMIT |
| With caching | ~5-10/session | 5K-10K/month | SAFE |

---

## Multi-Layer Caching Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER DEVICE                              │
├─────────────────────────────────────────────────────────────────┤
│  Layer 4: Provider Memory Cache (instant, current session)      │
│  Layer 3: Local Database - Hive (offline, persists)            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      VERCEL EDGE (CDN)                          │
├─────────────────────────────────────────────────────────────────┤
│  Layer 2: Edge Cache (s-maxage, stale-while-revalidate)        │
│  Layer 1: Static JSON Files (nightly generated, zero compute)  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    KOHA DATABASE                                 │
├─────────────────────────────────────────────────────────────────┤
│  Nightly sync job generates static catalog files                │
└─────────────────────────────────────────────────────────────────┘
```

---

## Layer 1: Static JSON Files (Backend)

### Concept
Generate static JSON files nightly containing the full catalog. Serve from CDN with zero function invocations.

### Files to Generate
```
/public/data/
  ├── catalog.json          # All 5000+ books (paginated chunks)
  ├── catalog-page-1.json   # Books 1-100
  ├── catalog-page-2.json   # Books 101-200
  ├── ...
  ├── videos.json           # All videos (pre-filtered)
  ├── ebooks.json           # All ebooks (pre-filtered)
  ├── categories.json       # Categories with counts
  ├── subjects.json         # Subject filters
  └── manifest.json         # Metadata + last updated timestamp
```

### Backend Implementation (Next.js API Route)

```typescript
// /api/sync/generate-static.ts (run via cron)
import { writeFileSync } from 'fs';
import path from 'path';

export async function generateStaticCatalog() {
  const books = await fetchAllBooksFromKoha();
  
  // Generate paginated chunks
  const pageSize = 100;
  const totalPages = Math.ceil(books.length / pageSize);
  
  for (let i = 0; i < totalPages; i++) {
    const chunk = books.slice(i * pageSize, (i + 1) * pageSize);
    writeFileSync(
      path.join(process.cwd(), `public/data/catalog-page-${i + 1}.json`),
      JSON.stringify(chunk)
    );
  }
  
  // Generate filtered lists
  const videos = books.filter(b => b.youtubeUrl);
  const ebooks = books.filter(b => b.ebookUrl || b.pdfUrl);
  
  writeFileSync(
    path.join(process.cwd(), 'public/data/videos.json'),
    JSON.stringify(videos)
  );
  
  writeFileSync(
    path.join(process.cwd(), 'public/data/ebooks.json'),
    JSON.stringify(ebooks)
  );
  
  // Manifest with timestamp
  writeFileSync(
    path.join(process.cwd(), 'public/data/manifest.json'),
    JSON.stringify({
      lastUpdated: new Date().toISOString(),
      totalBooks: books.length,
      totalVideos: videos.length,
      totalEbooks: ebooks.length,
      totalPages,
      pageSize
    })
  );
}
```

### Cron Job Setup (Vercel)
```json
// vercel.json
{
  "crons": [
    {
      "path": "/api/sync/generate-static",
      "schedule": "0 3 * * *"  // 3 AM daily
    }
  ]
}
```

### Cost: 1 function call/day = 30/month

---

## Layer 2: Vercel Edge Caching (API Routes)

### For Dynamic Queries (Search, Availability)
```typescript
// /api/books/search.ts
export const config = {
  runtime: 'edge',
};

export default async function handler(req: Request) {
  const response = await searchBooks(req);
  
  return new Response(JSON.stringify(response), {
    headers: {
      'Content-Type': 'application/json',
      // Cache for 5 minutes, serve stale for 1 hour while revalidating
      'Cache-Control': 's-maxage=300, stale-while-revalidate=3600',
    },
  });
}
```

### Cache Headers Explained
| Header | Effect |
|--------|--------|
| `s-maxage=300` | CDN caches for 5 minutes |
| `stale-while-revalidate=3600` | Serve stale for 1 hour while fetching fresh |

---

## Layer 3: Local Database (Flutter - Hive)

### Why Hive?
- Pure Dart (no native dependencies)
- Fast (comparable to SharedPreferences)
- Type-safe with adapters
- Works on all platforms

### Setup

```yaml
# pubspec.yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.6
```

### Implementation

```dart
// lib/services/cache_service.dart
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String booksBox = 'books_cache';
  static const String videosBox = 'videos_cache';
  static const String ebooksBox = 'ebooks_cache';
  static const String metaBox = 'cache_meta';
  
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(BookAdapter());
    Hive.registerAdapter(VideoAdapter());
    Hive.registerAdapter(EbookAdapter());
    
    // Open boxes
    await Hive.openBox<Book>(booksBox);
    await Hive.openBox<Video>(videosBox);
    await Hive.openBox<Ebook>(ebooksBox);
    await Hive.openBox(metaBox);
  }
  
  // Check if cache is stale (older than 1 hour)
  static bool isCacheStale(String key) {
    final meta = Hive.box(metaBox);
    final lastUpdated = meta.get('${key}_updated') as DateTime?;
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated).inHours >= 1;
  }
  
  // Books cache
  static Future<List<Book>> getCachedBooks() async {
    final box = Hive.box<Book>(booksBox);
    return box.values.toList();
  }
  
  static Future<void> cacheBooks(List<Book> books) async {
    final box = Hive.box<Book>(booksBox);
    await box.clear();
    await box.addAll(books);
    
    final meta = Hive.box(metaBox);
    await meta.put('books_updated', DateTime.now());
  }
  
  // Videos cache
  static Future<List<Video>> getCachedVideos() async {
    final box = Hive.box<Video>(videosBox);
    return box.values.toList();
  }
  
  static Future<void> cacheVideos(List<Video> videos) async {
    final box = Hive.box<Video>(videosBox);
    await box.clear();
    await box.addAll(videos);
    
    final meta = Hive.box(metaBox);
    await meta.put('videos_updated', DateTime.now());
  }
  
  // Ebooks cache
  static Future<List<Ebook>> getCachedEbooks() async {
    final box = Hive.box<Ebook>(ebooksBox);
    return box.values.toList();
  }
  
  static Future<void> cacheEbooks(List<Ebook> ebooks) async {
    final box = Hive.box<Ebook>(ebooksBox);
    await box.clear();
    await box.addAll(ebooks);
    
    final meta = Hive.box(metaBox);
    await meta.put('ebooks_updated', DateTime.now());
  }
}
```

### Hive Adapters (Auto-generated)

```dart
// lib/models/book.dart
import 'package:hive/hive.dart';

part 'book.g.dart';

@HiveType(typeId: 0)
class Book extends HiveObject {
  @HiveField(0)
  final String biblioId;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String? author;
  
  // ... other fields
}
```

Run: `flutter pub run build_runner build`

---

## Layer 4: Provider with Stale-While-Revalidate

### Pattern
1. Return cached data immediately (instant UI)
2. Fetch fresh data in background
3. Update UI when fresh data arrives

```dart
// lib/providers/books_provider.dart
class BooksProvider extends ChangeNotifier {
  List<Book> _books = [];
  bool _isLoading = false;
  bool _isBackgroundRefreshing = false;
  
  List<Book> get books => _books;
  bool get isLoading => _isLoading && _books.isEmpty;
  bool get isBackgroundRefreshing => _isBackgroundRefreshing;
  
  /// Load books with stale-while-revalidate pattern
  Future<void> loadBooks({bool forceRefresh = false}) async {
    // Step 1: Return cached data immediately
    if (_books.isEmpty) {
      _isLoading = true;
      notifyListeners();
      
      final cachedBooks = await CacheService.getCachedBooks();
      if (cachedBooks.isNotEmpty) {
        _books = cachedBooks;
        _isLoading = false;
        notifyListeners();
      }
    }
    
    // Step 2: Check if we need to fetch fresh data
    final shouldFetch = forceRefresh || 
                        _books.isEmpty || 
                        CacheService.isCacheStale('books');
    
    if (!shouldFetch) return;
    
    // Step 3: Fetch in background
    _isBackgroundRefreshing = true;
    notifyListeners();
    
    try {
      final freshBooks = await _booksService.getAllBooks();
      
      // Update cache
      await CacheService.cacheBooks(freshBooks);
      
      // Update UI
      _books = freshBooks;
      _isBackgroundRefreshing = false;
      notifyListeners();
    } catch (e) {
      _isBackgroundRefreshing = false;
      // Keep showing cached data on error
      if (_books.isEmpty) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }
}
```

---

## Preloading Strategy

### App Startup Sequence

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize cache service
  await CacheService.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BooksProvider()),
        ChangeNotifierProvider(create: (_) => ContentProvider()),
        // ...
      ],
      child: const MyApp(),
    ),
  );
}

// lib/app.dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _preloadData();
  }
  
  Future<void> _preloadData() async {
    // Load ALL data in parallel on app start
    await Future.wait([
      context.read<BooksProvider>().loadBooks(),
      context.read<ContentProvider>().loadVideos(),
      context.read<ContentProvider>().loadEbooks(),
    ]);
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(...);
  }
}
```

---

## Backend Database Changes (Recommended)

### Current Problem
Videos and ebooks are filtered by querying ALL books and checking for URLs.

### Solution: Separate Tables/Views

```sql
-- Create materialized views for videos and ebooks
CREATE MATERIALIZED VIEW videos AS
SELECT * FROM books WHERE youtube_url IS NOT NULL;

CREATE MATERIALIZED VIEW ebooks AS
SELECT * FROM books WHERE ebook_url IS NOT NULL OR pdf_url IS NOT NULL;

-- Refresh nightly
REFRESH MATERIALIZED VIEW videos;
REFRESH MATERIALIZED VIEW ebooks;
```

### API Endpoints
```
GET /api/videos     → SELECT * FROM videos (instant, indexed)
GET /api/ebooks     → SELECT * FROM ebooks (instant, indexed)
```

---

## Implementation Checklist

### Phase 1: Quick Wins (1-2 days)
- [ ] Add Hive for local caching
- [ ] Implement stale-while-revalidate in providers
- [ ] Preload videos/ebooks on app start
- [ ] Add loading indicators for background refresh

### Phase 2: Backend Optimization (2-3 days)
- [ ] Create materialized views for videos/ebooks
- [ ] Add cache headers to API routes
- [ ] Set up nightly cron job for static JSON generation

### Phase 3: Static Catalog (3-4 days)
- [ ] Generate paginated static JSON files
- [ ] Update Flutter app to fetch from static URLs
- [ ] Implement incremental sync (only fetch changes)

---

## Expected Results

| Metric | Before | After |
|--------|--------|-------|
| Initial load time | 2-3s | <500ms (cached) |
| Pagination scroll | 500-1000ms | Instant (preloaded) |
| Videos/Ebooks tab | 1-2s | Instant (preloaded) |
| API calls/user | 50-100 | 5-10 |
| Monthly API calls (1K users) | 50K-100K | 5K-10K |
| Vercel function invocations | EXCEEDS | SAFE |

---

## File Structure After Implementation

```
lib/
├── services/
│   ├── cache_service.dart      # NEW: Hive cache management
│   ├── books_service.dart      # Updated: static JSON support
│   ├── content_service.dart    # Updated: preload support
│   └── api_service.dart
├── providers/
│   ├── books_provider.dart     # Updated: SWR pattern
│   └── content_provider.dart   # Updated: SWR pattern
├── models/
│   ├── book.dart               # Updated: Hive adapter
│   ├── video.dart              # Updated: Hive adapter
│   └── ebook.dart              # Updated: Hive adapter
└── main.dart                   # Updated: cache init + preload
```

---

## Backend Optimization Guide (RECOMMENDED)

### Problem: High API Call Volume

With 1000 users, each making 50-100 API calls per session:
- **Worst case**: 100,000 function invocations/month
- **Vercel free tier limit**: 100,000/month
- **Result**: You'll hit the limit quickly

### Solution 1: Edge Caching (Immediate Win)

Add cache headers to your API routes:

```typescript
// /api/books/route.ts
export async function GET(request: Request) {
  const data = await fetchBooksFromKoha();
  
  return new Response(JSON.stringify(data), {
    headers: {
      'Content-Type': 'application/json',
      // Cache for 5 minutes at edge, serve stale for 1 hour
      'Cache-Control': 'public, s-maxage=300, stale-while-revalidate=3600',
    },
  });
}
```

**Result**: 1000 users hitting the same endpoint within 5 minutes = 1 function call (not 1000)

### Solution 2: Static JSON Generation (Best for Catalog)

Generate static JSON files nightly:

```typescript
// /api/cron/generate-catalog/route.ts
import { writeFileSync } from 'fs';
import path from 'path';

export async function GET() {
  const books = await fetchAllBooksFromKoha();
  
  // Write to public folder (served as static files - FREE)
  writeFileSync(
    path.join(process.cwd(), 'public/data/catalog.json'),
    JSON.stringify(books)
  );
  
  // Generate separate video/ebook files
  const videos = books.filter(b => b.youtubeUrl);
  const ebooks = books.filter(b => b.ebookUrl || b.pdfUrl);
  
  writeFileSync(
    path.join(process.cwd(), 'public/data/videos.json'),
    JSON.stringify(videos)
  );
  
  writeFileSync(
    path.join(process.cwd(), 'public/data/ebooks.json'),
    JSON.stringify(ebooks)
  );
  
  return Response.json({ success: true, count: books.length });
}
```

Add to `vercel.json`:
```json
{
  "crons": [{
    "path": "/api/cron/generate-catalog",
    "schedule": "0 3 * * *"
  }]
}
```

**Result**: 
- Static files served from CDN = 0 function calls
- Only 1 cron job/day = 30 function calls/month

### Solution 3: Separate Video/Ebook Endpoints

Instead of filtering all books, create dedicated endpoints:

```typescript
// /api/videos/route.ts
export async function GET() {
  // Direct query - only fetch books with youtube URLs
  const videos = await db.query(`
    SELECT * FROM books 
    WHERE youtube_url IS NOT NULL
    ORDER BY created_at DESC
  `);
  
  return Response.json(videos);
}

// /api/ebooks/route.ts  
export async function GET() {
  const ebooks = await db.query(`
    SELECT * FROM books 
    WHERE ebook_url IS NOT NULL OR pdf_url IS NOT NULL
    ORDER BY created_at DESC
  `);
  
  return Response.json(ebooks);
}
```

### Vercel Free Tier Budget

| Resource | Free Limit | Optimized Usage |
|----------|------------|-----------------|
| Function Invocations | 100K/month | ~5K/month |
| Edge Requests | 1M/month | ~50K/month |
| Bandwidth | 100GB/month | ~5GB/month |
| Cron Jobs | 1/day | 1/day |

### Implementation Priority

1. **Week 1**: Add cache headers to all API routes (immediate 10x reduction)
2. **Week 2**: Set up static JSON generation for catalog
3. **Week 3**: Create dedicated video/ebook endpoints
4. **Optional**: Move to Edge Functions for even better caching
