/**
 * GET /api/libraries
 * Get all library branches
 */

import { getLibraries } from '@/lib/koha';
import { errorResponse, successResponse } from '@/lib/auth';
import { formatLibraryResponse } from '@/lib/helpers';
import cache, { CACHE_TTL } from '@/lib/cache';

export async function GET(request) {
  try {
    // Check cache first - libraries rarely change
    const cacheKey = 'libraries:all';
    const cached = cache.get(cacheKey);
    if (cached) {
      return successResponse(cached);
    }

    // Fetch libraries from Koha
    const result = await getLibraries();

    if (!result.success) {
      return errorResponse(result.error || 'Failed to fetch libraries', 500);
    }

    const libraries = Array.isArray(result.data)
      ? result.data.map(formatLibraryResponse)
      : [];

    // Sort alphabetically by name
    libraries.sort((a, b) => {
      const nameA = a.name?.toLowerCase() || '';
      const nameB = b.name?.toLowerCase() || '';
      return nameA.localeCompare(nameB);
    });

    const response = {
      libraries,
      total: libraries.length,
    };

    // Cache for 1 hour - libraries don't change often
    cache.set(cacheKey, response, CACHE_TTL.LIBRARIES);

    return successResponse(response);

  } catch (error) {
    console.error('Libraries fetch error:', error);
    return errorResponse('Internal server error', 500);
  }
}
