#!/usr/bin/env node
/**
 * Test script to verify total book count from Koha API
 * Run with: node scripts/test-book-count.js
 */

import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load .env.local
dotenv.config({ path: join(__dirname, '..', '.env.local') });

const KOHA_BASE_URL = process.env.KOHA_BASE_URL || 'https://library.al-burhaan.org/api/v1';
const KOHA_USERNAME = process.env.KOHA_USERNAME;
const KOHA_PASSWORD = process.env.KOHA_PASSWORD;

function getBasicAuthHeader() {
  const credentials = Buffer.from(`${KOHA_USERNAME}:${KOHA_PASSWORD}`).toString('base64');
  return `Basic ${credentials}`;
}

async function kohaRequest(endpoint, options = {}) {
  const url = `${KOHA_BASE_URL}${endpoint}`;

  const headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': getBasicAuthHeader(),
    ...options.headers,
  };

  try {
    const response = await fetch(url, { ...options, headers });

    // Get total count from X-Total-Count header
    const totalCount = response.headers.get('X-Total-Count');

    const contentType = response.headers.get('content-type');
    let data;

    if (contentType && contentType.includes('application/json')) {
      data = await response.json();
    } else {
      data = await response.text();
    }

    return {
      success: response.ok,
      status: response.status,
      data,
      totalCount: totalCount ? parseInt(totalCount, 10) : null,
      headers: Object.fromEntries(response.headers.entries()),
    };
  } catch (err) {
    return {
      success: false,
      status: 0,
      data: null,
      totalCount: null,
      error: err.message,
    };
  }
}

async function testBookCount() {
  console.log('='.repeat(60));
  console.log('KOHA BOOK COUNT TEST');
  console.log('='.repeat(60));
  console.log(`\nKoha API URL: ${KOHA_BASE_URL}`);
  console.log(`Username configured: ${KOHA_USERNAME ? 'Yes' : 'No'}`);
  console.log(`Password configured: ${KOHA_PASSWORD ? 'Yes' : 'No'}\n`);

  if (!KOHA_USERNAME || !KOHA_PASSWORD) {
    console.error('ERROR: KOHA_USERNAME and KOHA_PASSWORD must be set in .env.local');
    process.exit(1);
  }

  try {
    // Test 1: Get first page with small limit to get total count
    console.log('Test 1: Fetching book count from /biblios endpoint...');
    const result1 = await kohaRequest('/biblios?_per_page=1&_page=1');

    if (result1.success) {
      console.log(`  ✓ Status: ${result1.status}`);
      console.log(`  ✓ X-Total-Count header: ${result1.totalCount || 'Not provided'}`);
      console.log(`  ✓ Books in response: ${Array.isArray(result1.data) ? result1.data.length : 'N/A'}`);
    } else {
      console.log(`  ✗ Failed with status: ${result1.status}`);
      console.log(`  ✗ Error: ${result1.error || JSON.stringify(result1.data)}`);
      return;
    }

    // Test 2: Get a larger batch to verify pagination
    console.log('\nTest 2: Fetching 100 books to verify pagination...');
    const result2 = await kohaRequest('/biblios?_per_page=100&_page=1');

    if (result2.success) {
      console.log(`  ✓ Status: ${result2.status}`);
      console.log(`  ✓ Books returned: ${Array.isArray(result2.data) ? result2.data.length : 'N/A'}`);
      console.log(`  ✓ X-Total-Count: ${result2.totalCount || 'Not provided'}`);
    } else {
      console.log(`  ✗ Failed with status: ${result2.status}`);
    }

    // Test 3: Try different pages to see pagination
    console.log('\nTest 3: Testing pagination across pages...');
    let totalCounted = 0;
    let page = 1;
    const perPage = 100;
    const maxPages = 50; // Safety limit

    while (page <= maxPages) {
      const result = await kohaRequest(`/biblios?_per_page=${perPage}&_page=${page}`);

      if (!result.success) {
        console.log(`  ✗ Page ${page} failed`);
        break;
      }

      const booksOnPage = Array.isArray(result.data) ? result.data.length : 0;
      totalCounted += booksOnPage;

      if (page <= 5 || booksOnPage < perPage) {
        console.log(`  Page ${page}: ${booksOnPage} books (Total so far: ${totalCounted})`);
      } else if (page === 6) {
        console.log('  ... (skipping detailed output for middle pages)');
      }

      if (booksOnPage < perPage) {
        // Last page
        break;
      }

      page++;
    }

    console.log('\n' + '='.repeat(60));
    console.log('SUMMARY');
    console.log('='.repeat(60));
    console.log(`Total books counted by pagination: ${totalCounted}`);
    console.log(`X-Total-Count from API: ${result1.totalCount || 'Not provided'}`);
    console.log(`Pages fetched: ${page}`);

    if (result1.totalCount && totalCounted !== result1.totalCount) {
      console.log(`\n⚠ WARNING: Counted total (${totalCounted}) differs from API total (${result1.totalCount})`);
    }

    // Test 4: Sample book data
    console.log('\n' + '='.repeat(60));
    console.log('SAMPLE BOOK DATA');
    console.log('='.repeat(60));

    if (result2.success && Array.isArray(result2.data) && result2.data.length > 0) {
      const sample = result2.data[0];
      console.log('\nFirst book structure:');
      console.log(JSON.stringify(sample, null, 2).substring(0, 1000));

      console.log('\nAvailable fields:', Object.keys(sample).join(', '));
    }

  } catch (error) {
    console.error('\nERROR:', error.message);
    process.exit(1);
  }
}

// Run the test
testBookCount();
