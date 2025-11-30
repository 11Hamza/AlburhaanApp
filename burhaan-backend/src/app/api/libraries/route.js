/**
 * GET /api/libraries
 * Get all library branches
 */

import { getLibraries } from '@/lib/koha';
import { errorResponse, successResponse } from '@/lib/auth';
import { formatLibraryResponse } from '@/lib/helpers';

export async function GET(request) {
  try {
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

    return successResponse({
      libraries,
      total: libraries.length,
    });

  } catch (error) {
    console.error('Libraries fetch error:', error);
    return errorResponse('Internal server error', 500);
  }
}
