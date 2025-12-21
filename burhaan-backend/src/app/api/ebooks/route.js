/**
 * GET /api/ebooks
 * List all eBooks with pagination and filtering
 *
 * POST /api/ebooks (Admin only)
 * Add a new eBook
 */

import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { getPaginationParams, paginatedResponse, validateRequired } from '@/lib/helpers';
import { prisma } from '@/lib/db';

export async function GET(request) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;

  // Guests can browse eBooks but can't access them
  if (user.isGuest) {
    return successResponse({
      ebooks: [],
      message: 'Please sign in to access eBooks',
      requiresAuth: true,
    });
  }

  try {
    const { searchParams } = new URL(request.url);
    const { page, perPage } = getPaginationParams(searchParams);
    const category = searchParams.get('category');
    const search = searchParams.get('q');

    // Build query
    const where = { isActive: true };
    if (category) {
      where.category = category;
    }

    // Get eBooks
    let ebooks = await prisma.ebook.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * perPage,
      take: perPage,
    });

    // If search query, filter in-memory (for now)
    if (search) {
      const searchLower = search.toLowerCase();
      ebooks = ebooks.filter(ebook =>
        ebook.title.toLowerCase().includes(searchLower) ||
        ebook.author?.toLowerCase().includes(searchLower) ||
        ebook.description?.toLowerCase().includes(searchLower)
      );
    }

    // Get total count
    const total = await prisma.ebook.count({ where });

    return Response.json(paginatedResponse(
      ebooks.map(ebook => ({
        id: ebook.id,
        title: ebook.title,
        author: ebook.author,
        description: ebook.description,
        category: ebook.category,
        coverUrl: ebook.coverUrl,
        format: ebook.format, // epub, pdf
        fileSize: ebook.fileSize,
        pageCount: ebook.pageCount,
        language: ebook.language,
        publishedYear: ebook.publishedYear,
        createdAt: ebook.createdAt,
        // Don't expose file URL in list - require specific request
      })),
      page,
      perPage,
      total
    ));

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
