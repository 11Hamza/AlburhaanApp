/**
 * GET /api/user/summary
 * Get a summary of the user's library activity
 * (current loans, holds, recently viewed)
 */

import { getPatronCheckouts, getPatronHolds } from '@/lib/koha';
import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { prisma } from '@/lib/db';

export async function GET(request) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;

  if (user.isGuest) {
    return successResponse({
      loans: { total: 0, overdue: 0 },
      holds: { total: 0, ready: 0 },
      favorites: { total: 0 },
      recentlyViewed: { total: 0 },
    });
  }

  try {
    // Fetch current checkouts
    const checkoutsResult = await getPatronCheckouts(user.patronId);
    let loansTotal = 0;
    let loansOverdue = 0;

    if (checkoutsResult.success && Array.isArray(checkoutsResult.data)) {
      loansTotal = checkoutsResult.data.length;
      const now = new Date();
      loansOverdue = checkoutsResult.data.filter(checkout => {
        const dueDate = new Date(checkout.due_date);
        return dueDate < now;
      }).length;
    }

    // Fetch current holds
    const holdsResult = await getPatronHolds(user.patronId);
    let holdsTotal = 0;
    let holdsReady = 0;

    if (holdsResult.success && Array.isArray(holdsResult.data)) {
      holdsTotal = holdsResult.data.length;
      holdsReady = holdsResult.data.filter(hold =>
        hold.status === 'W' || hold.status === 'waiting'
      ).length;
    }

    // Get favorites count from database
    let favoritesTotal = 0;
    try {
      const favorites = await prisma.favorite.findMany({
        where: { patronId: user.patronId },
      });
      favoritesTotal = favorites.length;
    } catch (dbError) {
      console.warn('Failed to fetch favorites count:', dbError.message);
    }

    // Get recently viewed count from database
    let recentlyViewedTotal = 0;
    try {
      const recentlyViewed = await prisma.recentlyViewed.findMany({
        where: { patronId: user.patronId },
      });
      recentlyViewedTotal = recentlyViewed.length;
    } catch (dbError) {
      console.warn('Failed to fetch recently viewed count:', dbError.message);
    }

    return successResponse({
      loans: {
        total: loansTotal,
        overdue: loansOverdue,
      },
      holds: {
        total: holdsTotal,
        ready: holdsReady,
      },
      favorites: {
        total: favoritesTotal,
      },
      recentlyViewed: {
        total: recentlyViewedTotal,
      },
    });

  } catch (error) {
    console.error('Summary fetch error:', error);
    return errorResponse('Internal server error', 500);
  }
}
