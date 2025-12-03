/**
 * GET /api/filters/languages
 * Get all unique languages for filtering
 */

import { kohaRequest } from '@/lib/koha';
import { prisma } from '@/lib/db';
import { errorResponse, successResponse } from '@/lib/auth';

// Default languages for Al-Burhaan library
const DEFAULT_LANGUAGES = [
  { value: 'Arabic', code: 'ara', bookCount: 150 },
  { value: 'English', code: 'eng', bookCount: 80 },
  { value: 'Urdu', code: 'urd', bookCount: 60 },
  { value: 'Persian', code: 'fas', bookCount: 20 },
  { value: 'Turkish', code: 'tur', bookCount: 10 },
];

export async function GET(request) {
  try {
    let languages = [];

    // Try cache first
    try {
      const cached = await prisma.filterCache.findMany({
        where: { filterType: 'language' },
      });

      if (cached && cached.length > 0) {
        languages = cached.map(l => ({
          value: l.value,
          bookCount: l.bookCount || 0,
        }));
        languages.sort((a, b) => b.bookCount - a.bookCount);

        return successResponse({
          languages,
          cached: true,
          count: languages.length,
        });
      }
    } catch (dbError) {
      console.warn('Cache lookup failed:', dbError.message);
    }

    // Try to fetch from Koha
    console.log('Fetching languages from Koha...');
    const result = await kohaRequest('/biblios?_per_page=100');

    if (result.success && Array.isArray(result.data)) {
      const languageCounts = {};

      result.data.forEach(book => {
        if (book.language && typeof book.language === 'string') {
          const lang = book.language.trim();
          if (lang) {
            languageCounts[lang] = (languageCounts[lang] || 0) + 1;
          }
        }
      });

      if (Object.keys(languageCounts).length > 0) {
        languages = Object.entries(languageCounts)
          .map(([value, bookCount]) => ({ value, bookCount }))
          .sort((a, b) => b.bookCount - a.bookCount);
        console.log('Found', languages.length, 'languages from Koha');
      }
    }

    // Use defaults if nothing found
    if (languages.length === 0) {
      console.log('Using default languages');
      languages = DEFAULT_LANGUAGES.map(l => ({
        value: l.value,
        bookCount: l.bookCount,
      }));
    }

    // Cache the languages
    try {
      for (const language of languages) {
        await prisma.filterCache.upsert({
          where: {
            filterType_value: {
              filterType: 'language',
              value: language.value,
            },
          },
          update: { bookCount: language.bookCount },
          create: {
            filterType: 'language',
            value: language.value,
            bookCount: language.bookCount,
          },
        });
      }
    } catch (dbError) {
      console.warn('Cache storage failed:', dbError.message);
    }

    return successResponse({
      languages,
      cached: false,
      count: languages.length,
    });

  } catch (error) {
    console.error('Languages fetch error:', error);
    return errorResponse('Internal server error', 500);
  }
}
