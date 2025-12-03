/**
 * GET /api/test/book-count
 * Test endpoint to verify total book count from Koha
 */

import { getBooks } from '@/lib/koha';

export async function GET(request) {
  try {
    console.log('Starting book count test...');

    // Test 1: Get first page to see X-Total-Count
    const result1 = await getBooks({ page: 1, perPage: 1 });

    // Test 2: Get 100 books
    const result2 = await getBooks({ page: 1, perPage: 100 });

    // Test 3: Count pages by iterating
    let totalCounted = 0;
    let page = 1;
    const perPage = 100;
    const pageDetails = [];

    while (page <= 100) { // Safety limit of 100 pages (10,000 books max)
      const result = await getBooks({ page, perPage });

      if (!result.success) {
        pageDetails.push({ page, error: result.error });
        break;
      }

      const booksOnPage = Array.isArray(result.data) ? result.data.length : 0;
      totalCounted += booksOnPage;

      if (page <= 5 || booksOnPage < perPage) {
        pageDetails.push({ page, count: booksOnPage, totalSoFar: totalCounted });
      }

      if (booksOnPage < perPage) {
        // Last page
        break;
      }

      page++;
    }

    const summary = {
      test1: {
        description: 'First page (1 book) to check total count header',
        success: result1.success,
        booksReturned: Array.isArray(result1.data) ? result1.data.length : 0,
      },
      test2: {
        description: 'First 100 books',
        success: result2.success,
        booksReturned: Array.isArray(result2.data) ? result2.data.length : 0,
      },
      test3: {
        description: 'Pagination count',
        totalPages: page,
        totalBooksCounted: totalCounted,
        pageDetails: pageDetails.slice(0, 10), // First 10 pages only
      },
      summary: {
        totalBooks: totalCounted,
        pagesChecked: page,
        expectedThousands: totalCounted >= 1000 ? 'Yes' : 'No - Only ' + totalCounted + ' books found',
      },
      sampleBook: result2.success && Array.isArray(result2.data) && result2.data.length > 0
        ? result2.data[0]
        : null,
    };

    return Response.json({
      success: true,
      message: 'Book count test completed',
      results: summary,
    });

  } catch (error) {
    console.error('Book count test error:', error);
    return Response.json({
      success: false,
      error: error.message,
    }, { status: 500 });
  }
}
