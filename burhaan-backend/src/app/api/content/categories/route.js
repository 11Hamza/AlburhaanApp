/**
 * GET /api/content/categories
 * Get all content categories with counts
 */

import { successResponse, errorResponse } from '@/lib/auth';
import { prisma } from '@/lib/db';

// Predefined categories for digital content
const CONTENT_CATEGORIES = [
  { id: 'islamic-studies', name: 'Islamic Studies', icon: 'mosque' },
  { id: 'quran', name: 'Quran & Tafsir', icon: 'book' },
  { id: 'hadith', name: 'Hadith', icon: 'scroll' },
  { id: 'fiqh', name: 'Fiqh (Islamic Law)', icon: 'balance' },
  { id: 'arabic', name: 'Arabic Language', icon: 'language' },
  { id: 'seerah', name: 'Seerah (Biography)', icon: 'history' },
  { id: 'aqeedah', name: 'Aqeedah (Creed)', icon: 'star' },
  { id: 'children', name: 'Children', icon: 'child' },
  { id: 'general', name: 'General', icon: 'folder' },
];

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const contentType = searchParams.get('type'); // 'ebooks', 'videos', or null for all

    const categories = await Promise.all(
      CONTENT_CATEGORIES.map(async (category) => {
        let ebookCount = 0;
        let videoCount = 0;

        if (!contentType || contentType === 'ebooks') {
          ebookCount = await prisma.ebook.count({
            where: {
              category: category.id,
              isActive: true,
            },
          });
        }

        if (!contentType || contentType === 'videos') {
          videoCount = await prisma.youtubeVideo.count({
            where: {
              category: category.id,
              isActive: true,
            },
          });
        }

        return {
          ...category,
          ebookCount,
          videoCount,
          totalCount: ebookCount + videoCount,
        };
      })
    );

    // Filter out empty categories if requested
    const includeEmpty = searchParams.get('includeEmpty') === 'true';
    const filteredCategories = includeEmpty
      ? categories
      : categories.filter(c => c.totalCount > 0);

    // Calculate totals
    const totalEbooks = categories.reduce((sum, c) => sum + c.ebookCount, 0);
    const totalVideos = categories.reduce((sum, c) => sum + c.videoCount, 0);

    return successResponse({
      categories: filteredCategories,
      summary: {
        totalEbooks,
        totalVideos,
        totalContent: totalEbooks + totalVideos,
        categoryCount: filteredCategories.length,
      },
    });

  } catch (error) {
    console.error('Categories fetch error:', error);
    return errorResponse('Internal server error', 500);
  }
}
