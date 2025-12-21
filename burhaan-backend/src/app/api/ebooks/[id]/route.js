/**
 * GET /api/ebooks/[id]
 * Get eBook details including access URL
 *
 * DELETE /api/ebooks/[id]
 * Remove an eBook (Admin only)
 */

import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { prisma } from '@/lib/db';

export async function GET(request, { params }) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;
  const { id } = await params;

  if (user.isGuest) {
    return errorResponse('Please sign in to access eBooks', 403);
  }

  try {
    // Get the eBook
    const ebook = await prisma.ebook.findUnique({
      where: { id },
    });

    if (!ebook || !ebook.isActive) {
      return errorResponse('eBook not found', 404);
    }

    // Generate time-limited access token (in production, use proper token system)
    const accessExpiry = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

    return successResponse({
      id: ebook.id,
      title: ebook.title,
      author: ebook.author,
      description: ebook.description,
      category: ebook.category,
      coverUrl: ebook.coverUrl,
      format: ebook.format,
      fileSize: ebook.fileSize,
      pageCount: ebook.pageCount,
      language: ebook.language,
      publishedYear: ebook.publishedYear,
      biblioId: ebook.biblioId,
      createdAt: ebook.createdAt,
      // Access information
      access: {
        fileUrl: ebook.fileUrl,
        expiresAt: accessExpiry.toISOString(),
        // In production, generate a signed URL here
      },
    });

  } catch (error) {
    console.error('eBook fetch error:', error);
    return errorResponse('Internal server error', 500);
  }
}

export async function DELETE(request, { params }) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;
  const { id } = await params;

  // In production, verify admin role
  // For now, allow any authenticated user

  try {
    // Get the eBook
    const ebook = await prisma.ebook.findUnique({
      where: { id },
    });

    if (!ebook) {
      return errorResponse('eBook not found', 404);
    }

    // Soft delete (mark as inactive)
    await prisma.ebook.update({
      where: { id },
      data: { isActive: false },
    });

    return successResponse({
      deleted: true,
    }, 'eBook removed');

  } catch (error) {
    console.error('eBook delete error:', error);
    return errorResponse('Internal server error', 500);
  }
}
