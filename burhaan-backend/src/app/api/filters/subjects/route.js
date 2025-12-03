/**
 * GET /api/filters/subjects
 * Get all unique subject headings (MARC 650 field) for filtering
 *
 * These are cached in the database and refreshed periodically
 */

import { kohaRequest } from '@/lib/koha';
import { prisma } from '@/lib/db';
import { errorResponse, successResponse } from '@/lib/auth';

export async function GET(request) {
  try {
    // Try to get cached subjects first
    let subjects = [];

    try {
      const cached = await prisma.filterCache.findMany({
        where: { filterType: 'subject' },
      });

      if (cached && cached.length > 0) {
        subjects = cached.map(s => ({
          value: s.value,
          valueAr: s.valueAr,
          valueUr: s.valueUr,
          bookCount: s.bookCount,
        }));

        // Sort by book count (most popular first)
        subjects.sort((a, b) => b.bookCount - a.bookCount);

        return successResponse({
          subjects,
          cached: true,
          count: subjects.length,
        });
      }
    } catch (dbError) {
      console.warn('Cache lookup failed:', dbError.message);
    }

    // If no cache, fetch from Koha and build subject list
    // Note: This is expensive - should be run as a background job
    console.log('Fetching subjects from Koha...');
    const result = await kohaRequest('/biblios?_per_page=100');

    console.log('Subjects result success:', result.success, 'data length:', Array.isArray(result.data) ? result.data.length : 0);

    if (!result.success) {
      console.error('Failed to fetch subjects:', result.error);
      return errorResponse('Failed to fetch subjects', 500);
    }

    // Log sample book to see structure
    if (Array.isArray(result.data) && result.data.length > 0) {
      console.log('Sample book keys:', Object.keys(result.data[0]));
    }

    // Extract unique subjects from books
    const subjectCounts = {};

    if (Array.isArray(result.data)) {
      result.data.forEach(book => {
        // Subjects can be in various fields
        const bookSubjects = [];

        // Check subjects array
        if (Array.isArray(book.subjects)) {
          bookSubjects.push(...book.subjects);
        }

        // Check subject field
        if (book.subject) {
          if (Array.isArray(book.subject)) {
            bookSubjects.push(...book.subject);
          } else {
            bookSubjects.push(book.subject);
          }
        }

        // Count each subject
        bookSubjects.forEach(subject => {
          if (subject && typeof subject === 'string') {
            const trimmed = subject.trim();
            if (trimmed) {
              subjectCounts[trimmed] = (subjectCounts[trimmed] || 0) + 1;
            }
          }
        });
      });
    }

    // Convert to array and sort
    subjects = Object.entries(subjectCounts)
      .map(([value, bookCount]) => ({
        value,
        valueAr: null, // Can be populated with translations
        valueUr: null,
        bookCount,
      }))
      .sort((a, b) => b.bookCount - a.bookCount);

    // Cache the subjects
    try {
      for (const subject of subjects) {
        await prisma.filterCache.upsert({
          where: {
            filterType_value: {
              filterType: 'subject',
              value: subject.value,
            },
          },
          update: {
            bookCount: subject.bookCount,
          },
          create: {
            filterType: 'subject',
            value: subject.value,
            valueAr: subject.valueAr,
            valueUr: subject.valueUr,
            bookCount: subject.bookCount,
          },
        });
      }
    } catch (dbError) {
      console.warn('Cache storage failed:', dbError.message);
    }

    return successResponse({
      subjects,
      cached: false,
      count: subjects.length,
    });

  } catch (error) {
    console.error('Subjects fetch error:', error);
    return errorResponse('Internal server error', 500);
  }
}
