/**
 * GET /api/test/debug-books
 * Debug endpoint to test book loading
 */

import { getBooks } from '@/lib/koha';
import { formatBookResponse, paginatedResponse } from '@/lib/helpers';

export async function GET(request) {
  const debug = {
    step: 'start',
    kohaResult: null,
    formattedBooks: null,
    finalResponse: null,
    error: null,
  };

  try {
    // Step 1: Call Koha
    debug.step = 'calling_koha';
    const result = await getBooks({ page: 1, perPage: 5 });

    debug.kohaResult = {
      success: result.success,
      status: result.status,
      error: result.error,
      dataType: typeof result.data,
      isArray: Array.isArray(result.data),
      dataLength: Array.isArray(result.data) ? result.data.length : 0,
      firstItem: Array.isArray(result.data) && result.data.length > 0
        ? result.data[0]
        : null,
    };

    if (!result.success) {
      debug.error = 'Koha API failed';
      return Response.json(debug);
    }

    // Step 2: Format books
    debug.step = 'formatting_books';
    const books = Array.isArray(result.data)
      ? result.data.map(formatBookResponse)
      : [];

    debug.formattedBooks = {
      count: books.length,
      firstBook: books.length > 0 ? books[0] : null,
    };

    // Step 3: Create paginated response
    debug.step = 'creating_response';
    const response = paginatedResponse(books, 1, 5);

    debug.finalResponse = {
      success: response.success,
      dataCount: response.data?.length,
      pagination: response.pagination,
    };

    debug.step = 'complete';

    return Response.json({
      debug,
      actualResponse: response,
    });

  } catch (error) {
    debug.error = error.message;
    debug.stack = error.stack;
    return Response.json(debug, { status: 500 });
  }
}
