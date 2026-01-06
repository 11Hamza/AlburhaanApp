/**
 * GET /api/ebooks
 * List all eBooks/PDFs with pagination and filtering
 * Combines ebooks from database AND Koha books with PDF/ebook URLs
 *
 * POST /api/ebooks (Admin only)
 * Add a new eBook
 */

import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { getPaginationParams, paginatedResponse, validateRequired, formatBookResponse } from '@/lib/helpers';
import { prisma } from '@/lib/db';
import { getBooks } from '@/lib/koha';
import cache, { CACHE_TTL } from '@/lib/cache';

// Fallback cache for when global cache isn't warmed
let cachedKohaEbooks = [];
let cacheTime = null;
let isFetching = false;
const CACHE_DURATION = 12 * 60 * 60 * 1000; // 12 hours - same as books

/**
 * Fetch all ebooks/PDFs from Koha (background task)
 */
async function fetchKohaEbooks() {
  if (isFetching) return;
  isFetching = true;

  console.log('Background: Fetching ebooks from Koha...');
  const ebooks = [];
  let page = 1;
  let hasMore = true;
  const maxPages = 60;

  try {
    while (hasMore && page <= maxPages) {
      const result = await getBooks({ page, perPage: 100 });

      if (result.success && Array.isArray(result.data) && result.data.length > 0) {
        const pageEbooks = result.data
          .map(formatBookResponse)
          .filter(book => book.ebookUrl || book.pdfUrl)
          .map(book => ({
            id: `koha-${book.biblioId}`,
            title: book.title,
            author: book.author,
            description: null,
            category: 'Library',
            coverUrl: book.imageUrl,
            accessUrl: book.pdfUrl || book.ebookUrl,
            fileType: book.pdfUrl ? 'pdf' : 'ebook',
            language: book.language || 'en',
            createdAt: new Date().toISOString(),
            biblioId: book.biblioId,
          }));

        ebooks.push(...pageEbooks);

        if (result.data.length < 100) {
          hasMore = false;
        } else {
          page++;
        }
      } else {
        hasMore = false;
      }
    }

    cachedKohaEbooks = ebooks;
    cacheTime = Date.now();
    console.log(`Background: Cached ${ebooks.length} ebooks from Koha`);
  } catch (error) {
    console.error('Background ebook fetch error:', error);
  } finally {
    isFetching = false;
  }
}

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const { page, perPage } = getPaginationParams(searchParams);
    const category = searchParams.get('category');
    const search = searchParams.get('q') || searchParams.get('search');

    // Get eBooks from database
    const where = { isActive: true };
    if (category) {
      where.category = category;
    }

    let dbEbooks = await prisma.ebook.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });

    // If search query, filter in-memory
    if (search) {
      const searchLower = search.toLowerCase();
      dbEbooks = dbEbooks.filter(ebook =>
        ebook.title.toLowerCase().includes(searchLower) ||
        ebook.author?.toLowerCase().includes(searchLower) ||
        ebook.description?.toLowerCase().includes(searchLower)
      );
    }

    // Try global cache first (populated by cache-warmer)
    let kohaEbooks = cache.get('ebooks:all') || [];

    // Fallback to local cache if global cache is empty
    if (kohaEbooks.length === 0) {
      kohaEbooks = cachedKohaEbooks;

      // If local cache is also empty, fetch directly
      if (!cacheTime && cachedKohaEbooks.length === 0 && !isFetching) {
        console.log('Ebooks: No cache available, fetching...');
        await fetchKohaEbooks();
        kohaEbooks = cachedKohaEbooks;
      } else if (cacheTime && (Date.now() - cacheTime > CACHE_DURATION)) {
        fetchKohaEbooks().catch(() => {}); // Background refresh
      }
    }

    // Filter koha ebooks by search if provided
    if (search && kohaEbooks.length > 0) {
      const searchLower = search.toLowerCase();
      kohaEbooks = kohaEbooks.filter(ebook =>
        ebook.title?.toLowerCase().includes(searchLower) ||
        ebook.author?.toLowerCase().includes(searchLower)
      );
    }

    // Combine ebooks (database first, then Koha)
    const allEbooks = [];

    for (const ebook of dbEbooks) {
      allEbooks.push({
        id: ebook.id,
        title: ebook.title,
        author: ebook.author,
        description: ebook.description,
        category: ebook.category,
        coverUrl: ebook.coverUrl,
        accessUrl: ebook.fileUrl,
        fileType: ebook.format,
        fileSize: ebook.fileSize,
        pageCount: ebook.pageCount,
        language: ebook.language,
        createdAt: ebook.createdAt,
      });
    }

    for (const ebook of kohaEbooks) {
      allEbooks.push(ebook);
    }

    // Paginate combined results
    const total = allEbooks.length;
    const startIndex = (page - 1) * perPage;
    const paginatedEbooks = allEbooks.slice(startIndex, startIndex + perPage);

    return Response.json({
      ...paginatedResponse(paginatedEbooks, page, perPage, total),
      cached: cacheTime ? true : false,
      cacheAge: cacheTime ? Math.floor((Date.now() - cacheTime) / 1000) : null,
    });

  } catch (error) {
    console.error('eBooks fetch error:', error);
    return errorResponse('Internal server error', 500);
  }
}

export async function POST(request) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;

  // For now, we'll allow any authenticated user to add eBooks
  // In production, this should be admin-only

  try {
    const body = await request.json();

    // Validate required fields
    const validation = validateRequired(body, ['title', 'fileUrl', 'format']);
    if (!validation.valid) {
      return errorResponse(validation.error, 400);
    }

    const {
      title,
      author,
      description,
      category,
      coverUrl,
      fileUrl,
      format,
      fileSize,
      pageCount,
      language,
      publishedYear,
      biblioId, // Optional link to Koha biblio
    } = body;

    // Validate format
    const validFormats = ['epub', 'pdf', 'mobi'];
    if (!validFormats.includes(format.toLowerCase())) {
      return errorResponse(`Invalid format. Must be one of: ${validFormats.join(', ')}`, 400);
    }

    // Create eBook
    const ebook = await prisma.ebook.create({
      data: {
        title: title.trim(),
        author: author?.trim() || null,
        description: description?.trim() || null,
        category: category || 'General',
        coverUrl: coverUrl || null,
        fileUrl: fileUrl,
        format: format.toLowerCase(),
        fileSize: fileSize || null,
        pageCount: pageCount || null,
        language: language || 'en',
        publishedYear: publishedYear || null,
        biblioId: biblioId || null,
        isActive: true,
        addedBy: user.patronId,
      },
    });

    return successResponse({
      id: ebook.id,
      title: ebook.title,
      author: ebook.author,
      category: ebook.category,
      format: ebook.format,
      createdAt: ebook.createdAt,
    }, 'eBook added successfully');

  } catch (error) {
    console.error('eBook creation error:', error);
    return errorResponse('Internal server error', 500);
  }
}
