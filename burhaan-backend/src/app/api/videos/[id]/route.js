/**
 * GET /api/videos/[id]
 * Get video details
 *
 * DELETE /api/videos/[id]
 * Remove a video (Admin only)
 */

import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { prisma } from '@/lib/db';

export async function GET(request, { params }) {
  const { id } = await params;

  try {
    // Get the video
    const video = await prisma.youtubeVideo.findUnique({
      where: { id },
    });

    if (!video || !video.isActive) {
      return errorResponse('Video not found', 404);
    }

    return successResponse({
      id: video.id,
      youtubeId: video.youtubeId,
      title: video.title,
      description: video.description,
      category: video.category,
      thumbnailUrl: video.thumbnailUrl || `https://img.youtube.com/vi/${video.youtubeId}/hqdefault.jpg`,
      duration: video.duration,
      speaker: video.speaker,
      language: video.language,
      publishedAt: video.publishedAt,
      biblioId: video.biblioId,
      createdAt: video.createdAt,
      // Video URLs for embedding
      embedUrl: `https://www.youtube.com/embed/${video.youtubeId}`,
      watchUrl: `https://www.youtube.com/watch?v=${video.youtubeId}`,
    });

  } catch (error) {
    console.error('Video fetch error:', error);
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

  try {
    // Get the video
    const video = await prisma.youtubeVideo.findUnique({
      where: { id },
    });

    if (!video) {
      return errorResponse('Video not found', 404);
    }

    // Soft delete
    await prisma.youtubeVideo.update({
      where: { id },
      data: { isActive: false },
    });

    return successResponse({
      deleted: true,
    }, 'Video removed');

  } catch (error) {
    console.error('Video delete error:', error);
    return errorResponse('Internal server error', 500);
  }
}
