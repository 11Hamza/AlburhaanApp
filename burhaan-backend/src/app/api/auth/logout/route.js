/**
 * POST /api/auth/logout
 * Logout and invalidate the current session
 */

import { extractToken, errorResponse, successResponse } from '@/lib/auth';
import { prisma } from '@/lib/db';

export async function POST(request) {
  try {
    const authHeader = request.headers.get('authorization');
    const token = extractToken(authHeader);

    if (!token) {
      return errorResponse('No token provided', 400);
    }

    // Delete session from database
    try {
      await prisma.session.delete({
        where: { token },
      });
    } catch (dbError) {
      // Session might not exist in DB (in-memory mode)
      console.warn('Session deletion failed:', dbError.message);
    }

    return successResponse(null, 'Logged out successfully');

  } catch (error) {
    console.error('Logout error:', error);
    return errorResponse('Failed to logout', 500);
  }
}
