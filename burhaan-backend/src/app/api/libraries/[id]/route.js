/**
 * GET /api/libraries/[id]
 * Get details of a specific library branch
 */

import { getLibraryById } from '@/lib/koha';
import { errorResponse, successResponse } from '@/lib/auth';
import { formatLibraryResponse } from '@/lib/helpers';

export async function GET(request, { params }) {
  try {
    const { id } = await params;

    // Fetch library from Koha
    const result = await getLibraryById(id);

    if (!result.success) {
      if (result.status === 404) {
        return errorResponse('Library not found', 404);
      }
      return errorResponse(result.error || 'Failed to fetch library', 500);
    }

    const library = formatLibraryResponse(result.data);

    return successResponse(library);

  } catch (error) {
    console.error('Library detail error:', error);
    return errorResponse('Internal server error', 500);
  }
}
