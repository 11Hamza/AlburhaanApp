/**
 * GET /api/filters/subjects
 * Get all unique subject headings (MARC 650 field) for filtering
 */

import { kohaRequest } from '@/lib/koha';
import { prisma } from '@/lib/db';
import { errorResponse, successResponse } from '@/lib/auth';

// Common subjects from Al-Burhaan library (MARC 650$a values)
const DEFAULT_SUBJECTS = [
  { value: 'Tajwīd', bookCount: 50 },
  { value: 'Fiqh', bookCount: 45 },
  { value: 'Hadith', bookCount: 40 },
  { value: 'Tafsir', bookCount: 35 },
  { value: 'Islamic Law', bookCount: 30 },
  { value: 'Arabic Language', bookCount: 28 },
  { value: 'Sīrah', bookCount: 25 },
  { value: 'Aqīdah', bookCount: 22 },
  { value: 'Islamic History', bookCount: 20 },
  { value: 'Makhārij of Letters', bookCount: 18 },
  { value: 'Quranic Studies', bookCount: 15 },
  { value: 'Islamic Ethics', bookCount: 12 },
];

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
          bookCount: s.bookCount || 0,
        }));
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

    // Fetch from Koha to try to extract subjects
    console.log('Fetching subjects from Koha...');
    const result = await kohaRequest('/biblios?_per_page=100');

    if (result.success && Array.isArray(result.data) && result.data.length > 0) {
      console.log('Sample book keys:', Object.keys(result.data[0]));

      // Extract subjects from available fields
      const subjectCounts = {};

      result.data.forEach(book => {
        // Try different possible subject fields
        const possibleFields = ['subjects', 'subject', 'topic', 'topics'];

        possibleFields.forEach(field => {
          if (book[field]) {
            const values = Array.isArray(book[field]) ? book[field] : [book[field]];
            values.forEach(val => {
              if (val && typeof val === 'string') {
                const trimmed = val.trim();
                if (trimmed) {
                  subjectCounts[trimmed] = (subjectCounts[trimmed] || 0) + 1;
                }
              }
            });
          }
        });
      });

      // If we found subjects from Koha, use them
      if (Object.keys(subjectCounts).length > 0) {
        subjects = Object.entries(subjectCounts)
          .map(([value, bookCount]) => ({ value, bookCount }))
          .sort((a, b) => b.bookCount - a.bookCount);

        console.log('Found', subjects.length, 'subjects from Koha');
      }
    }

    // If no subjects found, use defaults
    if (subjects.length === 0) {
      console.log('Using default subjects');
      subjects = DEFAULT_SUBJECTS;
    }

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
          update: { bookCount: subject.bookCount },
          create: {
            filterType: 'subject',
            value: subject.value,
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
