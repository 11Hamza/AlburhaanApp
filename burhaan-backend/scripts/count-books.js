/**
 * Test script to count all books and videos from Koha
 * Run with: node scripts/count-books.js
 */

const KOHA_BASE_URL = process.env.KOHA_BASE_URL || 'https://library.al-burhaan.org/api/v1';
const KOHA_USERNAME = process.env.KOHA_USERNAME;
const KOHA_PASSWORD = process.env.KOHA_PASSWORD;

function getBasicAuthHeader() {
  const credentials = Buffer.from(`${KOHA_USERNAME}:${KOHA_PASSWORD}`).toString('base64');
  return `Basic ${credentials}`;
}

async function fetchAllBooks() {
  let allBooks = [];
  let page = 1;
  const perPage = 100; // Max per page for faster fetching
  let hasMore = true;

  console.log('Starting to fetch all books from Koha...');
  console.log(`Base URL: ${KOHA_BASE_URL}`);
  console.log(`Credentials set: ${!!KOHA_USERNAME && !!KOHA_PASSWORD}`);
  console.log('');

  while (hasMore) {
    const url = `${KOHA_BASE_URL}/biblios?_page=${page}&_per_page=${perPage}`;
    console.log(`Fetching page ${page}...`);

    try {
      const response = await fetch(url, {
        headers: {
          'Authorization': getBasicAuthHeader(),
          'Accept': 'application/json',
        },
      });

      if (!response.ok) {
        console.error(`Error on page ${page}: ${response.status} ${response.statusText}`);
        break;
      }

      const data = await response.json();

      if (Array.isArray(data) && data.length > 0) {
        allBooks = allBooks.concat(data);
        console.log(`  Got ${data.length} books (total: ${allBooks.length})`);

        // Check if we got a full page (more might exist)
        if (data.length < perPage) {
          hasMore = false;
          console.log('  Last page (partial page received)');
        } else {
          page++;
        }
      } else {
        hasMore = false;
        console.log('  No more books');
      }
    } catch (error) {
      console.error(`Error fetching page ${page}:`, error.message);
      break;
    }
  }

  return allBooks;
}

function analyzeBooks(books) {
  console.log('\n========== ANALYSIS ==========\n');
  console.log(`Total books: ${books.length}`);

  // Count books with YouTube URLs
  const youtubeBooks = books.filter(book => {
    const url = book.url || '';
    return url.includes('youtube.com') || url.includes('youtu.be');
  });
  console.log(`Books with YouTube URLs: ${youtubeBooks.length}`);

  if (youtubeBooks.length > 0) {
    console.log('\nYouTube books:');
    youtubeBooks.slice(0, 10).forEach((book, i) => {
      console.log(`  ${i + 1}. "${book.title}" - ${book.url}`);
    });
    if (youtubeBooks.length > 10) {
      console.log(`  ... and ${youtubeBooks.length - 10} more`);
    }
  }

  // Count by media type if available
  const mediaTypes = {};
  books.forEach(book => {
    const type = book.item_type || book.medium || 'unknown';
    mediaTypes[type] = (mediaTypes[type] || 0) + 1;
  });

  console.log('\nBooks by item type:');
  Object.entries(mediaTypes)
    .sort((a, b) => b[1] - a[1])
    .forEach(([type, count]) => {
      console.log(`  ${type}: ${count}`);
    });

  // Sample of fields available
  if (books.length > 0) {
    console.log('\nSample book fields:');
    console.log(Object.keys(books[0]).join(', '));
  }
}

async function main() {
  // Load env from .env.local if running locally
  try {
    const { config } = await import('dotenv');
    config({ path: '.env.local' });
  } catch (e) {
    // dotenv not available, use existing env
  }

  if (!KOHA_USERNAME || !KOHA_PASSWORD) {
    console.error('Error: KOHA_USERNAME and KOHA_PASSWORD must be set');
    console.error('Run with: KOHA_USERNAME=xxx KOHA_PASSWORD=xxx node scripts/count-books.js');
    process.exit(1);
  }

  const books = await fetchAllBooks();
  analyzeBooks(books);
}

main().catch(console.error);
