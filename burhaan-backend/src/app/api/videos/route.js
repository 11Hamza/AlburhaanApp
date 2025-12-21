/**
 * GET /api/videos
 * List all YouTube videos with pagination and filtering
 *
 * POST /api/videos (Admin only)
 * Add a new YouTube video
 */

import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { getPaginationParams, paginatedResponse, validateRequired } from '@/lib/helpers';
import { prisma } from '@/lib/db';

/**
 * Extract YouTube video ID from various URL formats
 */
function extractYouTubeId(url) {
  const patterns = [
    /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([^&\n?#]+)/,
    /youtube\.com\/v\/([^&\n?#]+)/,
  ];

  for (const pattern of patterns) {
    const match = url.match(pattern);
    if (match) {
      return match[1];
    }
  }

  return null;
}

export async function GET(request) {
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

    // Get videos
    let videos = await prisma.youtubeVideo.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * perPage,
      take: perPage,
    });

    // If search query, filter in-memory (for now)
    if (search) {
      const searchLower = search.toLowerCase();
      videos = videos.filter(video =>
        video.title.toLowerCase().includes(searchLower) ||
        video.description?.toLowerCase().includes(searchLower) ||
        video.speaker?.toLowerCase().includes(searchLower)
      );
    }

    // Get total count
    const total = await prisma.youtubeVideo.count({ where });

    return Response.json(paginatedResponse(
      videos.map(video => ({
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
        createdAt: video.createdAt,
      })),
      page,
      perPage,
      total
    ));

  } catch (error) {
    console.error('Videos fetch error:', error);
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

  // For now, allow any authenticated user to add videos
  // In production, this should be admin-only

  try {
    const body = await request.json();

    // Validate required fields
    const validation = validateRequired(body, ['title']);
    if (!validation.valid) {
      return errorResponse(validation.error, 400);
    }

    // Either youtubeId or youtubeUrl is required
    if (!body.youtubeId && !body.youtubeUrl) {
      return errorResponse('Either youtubeId or youtubeUrl is required', 400);
    }

    const {
      title,
      description,
      category,
      youtubeUrl,
      duration,
      speaker,
      language,
      publishedAt,
      biblioId,
    } = body;

    let { youtubeId, thumbnailUrl } = body;

    // Extract YouTube ID from URL if provided
    if (!youtubeId && youtubeUrl) {
      youtubeId = extractYouTubeId(youtubeUrl);
      if (!youtubeId) {
        return errorResponse('Invalid YouTube URL', 400);
      }
    }

    // Check if video already exists
    const existing = await prisma.youtubeVideo.findUnique({
      where: { youtubeId },
    });

    if (existing) {
      return errorResponse('This video has already been added', 409, 'VIDEO_EXISTS');
    }

    // Set default thumbnail if not provided
    if (!thumbnailUrl) {
      thumbnailUrl = `https://img.youtube.com/vi/${youtubeId}/hqdefault.jpg`;
    }

    // Create video
    const video = await prisma.youtubeVideo.create({
      data: {
        youtubeId,
        title: title.trim(),
        description: description?.trim() || null,
        category: category || 'General',
        thumbnailUrl,
        duration: duration || null,
        speaker: speaker?.trim() || null,
        language: language || 'en',
        publishedAt: publishedAt ? new Date(publishedAt) : null,
        biblioId: biblioId || null,
        isActive: true,
        addedBy: user.patronId,
      },
    });

    return successResponse({
      id: video.id,
      youtubeId: video.youtubeId,
      title: video.title,
      category: video.category,
      thumbnailUrl: video.thumbnailUrl,
      createdAt: video.createdAt,
    }, 'Video added successfully');

  } catch (error) {
    console.error('Video creation error:', error);
    return errorResponse('Internal server error', 500);
  }
}
