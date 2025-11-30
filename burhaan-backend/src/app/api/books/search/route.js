/**
 * GET /api/books/search
 * Advanced book search with multiple parameters
 *
 * Query params:
 * - keyword: Search across multiple fields
 * - title: Search in title
 * - author: Search by author
 * - isbn: Search by ISBN
 * - subject: Search by subject (650 field)
 * - language: Filter by language
 * - year_from: Publication year range start
 * - year_to: Publication year range end
 * - page: Page number (default: 1)
 * - per_page: Items per page (default: 10)
 * - sort: Sort field (title, author, year)
 * - order: Sort order (asc, desc)
 */

import { searchBooks, kohaRequest } from '@/lib/koha';
import { formatBookResponse, getPaginationParams, paginatedResponse } from '@/lib/helpers';
import { errorResponse } from '@/lib/auth';

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const { page, perPage } = getPaginationParams(searchParams);

    // Get search parameters
    const keyword = searchParams.get('keyword') || '';
    const title = searchParams.get('title') || '';
    const author = searchParams.get('author') || '';
    const isbn = searchParams.get('isbn') || '';
    const subject = searchParams.get('subject') || '';
    const language = searchParams.get('language') || '';
    const yearFrom = searchParams.get('year_from') || '';
    const yearTo = searchParams.get('year_to') || '';

    // Build search query for Koha
    const queryObj = {};
    const queryParts = [];

    if (keyword) {
      // Keyword searches across title and author
      queryParts.push({ title: { '-like': `%${keyword}%` } });
      queryParts.push({ author: { '-like': `%${keyword}%` } });
    }

    if (title) {
      queryObj.title = { '-like': `%${title}%` };
    }

    if (author) {
      queryObj.author = { '-like': `%${author}%` };
    }

    if (isbn) {
      queryObj.isbn = isbn;
    }

    if (subject) {
      // Subject is stored in MARC 650 field
      queryObj.subject = { '-like': `%${subject}%` };
    }

    if (language) {
      queryObj.language = language;
    }

    // Build the final query
    let finalQuery = {};

    if (queryParts.length > 0) {
      finalQuery['-or'] = queryParts;
    }

    // Merge with other filters
    finalQuery = { ...finalQuery, ...queryObj };

    // Build URL
    let url = `/biblios?_page=${page}&_per_page=${perPage}`;

    if (Object.keys(finalQuery).length > 0) {
      url += `&q=${encodeURIComponent(JSON.stringify(finalQuery))}`;
    }

    // Make request to Koha
    const result = await kohaRequest(url);

    if (!result.success) {
      return errorResponse(result.error || 'Search failed', result.status || 500);
    }

    // Format book responses
    let books = Array.isArray(result.data)
      ? result.data.map(formatBookResponse)
      : [];

    // Apply year filter (client-side since Koha might not support range queries)
    if (yearFrom || yearTo) {
      books = books.filter(book => {
        if (!book.publicationYear) return true;
        const year = parseInt(book.publicationYear, 10);
        if (isNaN(year)) return true;
        if (yearFrom && year < parseInt(yearFrom, 10)) return false;
        if (yearTo && year > parseInt(yearTo, 10)) return false;
        return true;
      });
    }

    // Apply sorting (client-side)
    const sort = searchParams.get('sort');
    const order = searchParams.get('order') || 'asc';

    if (sort) {
      books.sort((a, b) => {
        let valA, valB;

        switch (sort) {
          case 'title':
            valA = a.title?.toLowerCase() || '';
            valB = b.title?.toLowerCase() || '';
            break;
          case 'author':
            valA = a.author?.toLowerCase() || '';
            valB = b.author?.toLowerCase() || '';
            break;
          case 'year':
            valA = parseInt(a.publicationYear, 10) || 0;
            valB = parseInt(b.publicationYear, 10) || 0;
            break;
          default:
            return 0;
        }

        if (valA < valB) return order === 'asc' ? -1 : 1;
        if (valA > valB) return order === 'asc' ? 1 : -1;
        return 0;
      });
    }

    return Response.json(paginatedResponse(books, page, perPage));

  } catch (error) {
    console.error('Search error:', error);
    return errorResponse('Internal server error', 500);
  }
}
