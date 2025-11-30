/**
 * GET /api/filters/classifications
 * Get all unique classification schemes (MARC 942$2 field) for filtering
 */

import { kohaRequest } from '@/lib/koha';
import { prisma } from '@/lib/db';
import { errorResponse, successResponse } from '@/lib/auth';

export async function GET(request) {
  try {
    // Try to get cached classifications first
    let classifications = [];

    try {
      const cached = await prisma.filterCache.findMany({
        where: { filterType: 'classification' },
      });

      if (cached && cached.length > 0) {
        classifications = cached.map(c => ({
          value: c.value,
          valueAr: c.valueAr,
          valueUr: c.valueUr,
          bookCount: c.bookCount,
        }));

        classifications.sort((a, b) => b.bookCount - a.bookCount);

        return successResponse({
          classifications,
          cached: true,
          count: classifications.length,
        });
      }
    } catch (dbError) {
      console.warn('Cache lookup failed:', dbError.message);
    }

    // Fetch from Koha
    const result = await kohaRequest('/biblios?_per_page=1000');

    if (!result.success) {
      return errorResponse('Failed to fetch classifications', 500);
    }

    // Extract unique classifications
    const classificationCounts = {};

    if (Array.isArray(result.data)) {
      result.data.forEach(book => {
        // Classification can be in various fields
        const classification = book.classification_scheme ||
                              book.cn_source ||
                              book.call_number_source;

        if (classification && typeof classification === 'string') {
          const trimmed = classification.trim();
          if (trimmed) {
            classificationCounts[trimmed] = (classificationCounts[trimmed] || 0) + 1;
          }
        }
      });
    }

    // Convert to array and sort
    classifications = Object.entries(classificationCounts)
      .map(([value, bookCount]) => ({
        value,
        valueAr: null,
        valueUr: null,
        bookCount,
      }))
      .sort((a, b) => b.bookCount - a.bookCount);

    // Cache the classifications
    try {
      for (const classification of classifications) {
        await prisma.filterCache.upsert({
          where: {
            filterType_value: {
              filterType: 'classification',
              value: classification.value,
            },
          },
          update: {
            bookCount: classification.bookCount,
          },
          create: {
            filterType: 'classification',
            value: classification.value,
            valueAr: classification.valueAr,
            valueUr: classification.valueUr,
            bookCount: classification.bookCount,
          },
        });
      }
    } catch (dbError) {
      console.warn('Cache storage failed:', dbError.message);
    }

    return successResponse({
      classifications,
      cached: false,
      count: classifications.length,
    });

  } catch (error) {
    console.error('Classifications fetch error:', error);
    return errorResponse('Internal server error', 500);
  }
}
