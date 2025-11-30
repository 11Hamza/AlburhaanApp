/**
 * GET /api/filters/languages
 * Get all unique languages for filtering
 */

import { kohaRequest } from '@/lib/koha';
import { prisma } from '@/lib/db';
import { errorResponse, successResponse } from '@/lib/auth';

// Language code to name mapping
const LANGUAGE_NAMES = {
  ara: { en: 'Arabic', ar: 'العربية', ur: 'عربی' },
  eng: { en: 'English', ar: 'الإنجليزية', ur: 'انگریزی' },
  urd: { en: 'Urdu', ar: 'الأردية', ur: 'اردو' },
  fas: { en: 'Persian/Farsi', ar: 'الفارسية', ur: 'فارسی' },
  tur: { en: 'Turkish', ar: 'التركية', ur: 'ترکی' },
  fre: { en: 'French', ar: 'الفرنسية', ur: 'فرانسیسی' },
  ger: { en: 'German', ar: 'الألمانية', ur: 'جرمن' },
  spa: { en: 'Spanish', ar: 'الإسبانية', ur: 'ہسپانوی' },
  ind: { en: 'Indonesian', ar: 'الإندونيسية', ur: 'انڈونیشیائی' },
  mal: { en: 'Malay', ar: 'الملايو', ur: 'مالے' },
};

export async function GET(request) {
  try {
    // Try to get cached languages first
    let languages = [];

    try {
      const cached = await prisma.filterCache.findMany({
        where: { filterType: 'language' },
      });

      if (cached && cached.length > 0) {
        languages = cached.map(l => ({
          code: l.value,
          name: LANGUAGE_NAMES[l.value]?.en || l.value,
          nameAr: l.valueAr || LANGUAGE_NAMES[l.value]?.ar || null,
          nameUr: l.valueUr || LANGUAGE_NAMES[l.value]?.ur || null,
          bookCount: l.bookCount,
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

    // Fetch from Koha
    const result = await kohaRequest('/biblios?_per_page=1000');

    if (!result.success) {
      return errorResponse('Failed to fetch languages', 500);
    }

    // Extract unique languages
    const languageCounts = {};

    if (Array.isArray(result.data)) {
      result.data.forEach(book => {
        const language = book.language;

        if (language && typeof language === 'string') {
          const trimmed = language.trim().toLowerCase();
          if (trimmed) {
            languageCounts[trimmed] = (languageCounts[trimmed] || 0) + 1;
          }
        }
      });
    }

    // Convert to array with names
    languages = Object.entries(languageCounts)
      .map(([code, bookCount]) => ({
        code,
        name: LANGUAGE_NAMES[code]?.en || code,
        nameAr: LANGUAGE_NAMES[code]?.ar || null,
        nameUr: LANGUAGE_NAMES[code]?.ur || null,
        bookCount,
      }))
      .sort((a, b) => b.bookCount - a.bookCount);

    // Cache the languages
    try {
      for (const language of languages) {
        await prisma.filterCache.upsert({
          where: {
            filterType_value: {
              filterType: 'language',
              value: language.code,
            },
          },
          update: {
            bookCount: language.bookCount,
          },
          create: {
            filterType: 'language',
            value: language.code,
            valueAr: language.nameAr,
            valueUr: language.nameUr,
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
