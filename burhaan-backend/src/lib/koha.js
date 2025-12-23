/**
 * Koha API Client
 * Handles all communication with the Koha Library Management System API
 */

const KOHA_BASE_URL = process.env.KOHA_BASE_URL || 'https://library.al-burhaan.org/api/v1';
const KOHA_USERNAME = process.env.KOHA_USERNAME;
const KOHA_PASSWORD = process.env.KOHA_PASSWORD;

// Log config on first load (for debugging)
console.log('Koha Config:', {
  baseUrl: KOHA_BASE_URL,
  usernameSet: !!KOHA_USERNAME,
  passwordSet: !!KOHA_PASSWORD,
});

/**
 * Create Basic Auth header
 */
function getBasicAuthHeader(username = KOHA_USERNAME, password = KOHA_PASSWORD) {
  const credentials = Buffer.from(`${username}:${password}`).toString('base64');
  return `Basic ${credentials}`;
}

/**
 * Make authenticated request to Koha API with timeout
 */
async function kohaRequest(endpoint, options = {}, userCredentials = null) {
  const url = `${KOHA_BASE_URL}${endpoint}`;

  // Add timeout using AbortController
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 30000); // 30 second timeout

  const headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    ...options.headers,
  };

  // Use user credentials if provided, otherwise use system credentials
  if (userCredentials) {
    headers['Authorization'] = getBasicAuthHeader(userCredentials.username, userCredentials.password);
  } else {
    headers['Authorization'] = getBasicAuthHeader();
  }

  try {
    console.log('Koha request:', url);
    const response = await fetch(url, {
      ...options,
      headers,
      signal: controller.signal,
    });
    clearTimeout(timeoutId);

    // Handle different response types
    const contentType = response.headers.get('content-type');
    let data;

    if (contentType && contentType.includes('application/json')) {
      data = await response.json();
    } else {
      data = await response.text();
    }

    if (!response.ok) {
      return {
        success: false,
        status: response.status,
        error: data.error || data.message || 'Request failed',
        data: null,
      };
    }

    return {
      success: true,
      status: response.status,
      data,
      error: null,
    };
  } catch (error) {
    clearTimeout(timeoutId);
    console.error('Koha API Error:', error.name, error.message);
    return {
      success: false,
      status: 500,
      error: error.message || 'Network error',
      data: null,
    };
  }
}

/**
 * Validate user credentials against Koha using password validation endpoint
 */
async function validateCredentials(cardNumber, password) {
  try {
    // Use Koha's password validation endpoint
    const url = `${KOHA_BASE_URL}/auth/password/validation`;

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': getBasicAuthHeader(),
      },
      body: JSON.stringify({
        identifier: cardNumber,
        password: password,
      }),
    });

    // 204 No Content means valid credentials
    // 400 means invalid credentials
    return response.status === 204 || response.status === 200;
  } catch (error) {
    console.error('Credential validation error:', error);
    return false;
  }
}

/**
 * Get patron by card number (uses system credentials)
 */
async function getPatronByCardNumber(cardNumber) {
  const query = JSON.stringify({ cardnumber: cardNumber });
  const result = await kohaRequest(`/patrons?q=${encodeURIComponent(query)}`);

  console.log('getPatronByCardNumber result:', JSON.stringify(result, null, 2));

  if (result.success && result.data && result.data.length > 0) {
    return result.data[0];
  }

  return null;
}

/**
 * Get patron by ID
 */
async function getPatronById(patronId) {
  return kohaRequest(`/patrons/${patronId}`);
}

/**
 * Get all libraries/branches
 */
async function getLibraries() {
  return kohaRequest('/libraries');
}

/**
 * Get library by ID
 */
async function getLibraryById(libraryId) {
  return kohaRequest(`/libraries/${libraryId}`);
}

/**
 * Get books (biblios) with pagination and filters
 * Note: Subject/language filtering requires MARC field search which isn't
 * directly supported - these filters are ignored for now
 */
async function getBooks({ page = 1, perPage = 10, query = null, filters = {} } = {}) {
  let url = `/biblios?_page=${page}&_per_page=${perPage}`;

  // Build query object for filtering
  // Only use fields that Koha biblios endpoint actually supports
  const queryObj = {};

  if (query) {
    // Search in title
    queryObj.title = { '-like': `%${query}%` };
  }

  if (filters.author) {
    queryObj.author = { '-like': `%${filters.author}%` };
  }

  if (filters.isbn) {
    queryObj.isbn = filters.isbn;
  }

  // Note: subject and language filters are not directly supported by Koha biblios API
  // They would need MARC field searching which requires a different approach
  // For now, we skip these filters to avoid 500 errors
  if (filters.subject) {
    console.log('Subject filter requested but not supported by Koha biblios API:', filters.subject);
  }

  if (filters.language) {
    console.log('Language filter requested but not supported by Koha biblios API:', filters.language);
  }

  if (Object.keys(queryObj).length > 0) {
    url += `&q=${encodeURIComponent(JSON.stringify(queryObj))}`;
  }

  return kohaRequest(url);
}

/**
 * Get book by ID
 */
async function getBookById(biblioId) {
  return kohaRequest(`/biblios/${biblioId}`);
}

/**
 * Get items for a book (for availability)
 */
async function getBookItems(biblioId) {
  return kohaRequest(`/biblios/${biblioId}/items`);
}

/**
 * Search books with advanced filters
 */
async function searchBooks({
  keyword = '',
  title = '',
  author = '',
  isbn = '',
  subject = '',
  language = '',
  page = 1,
  perPage = 10
} = {}) {
  const queryObj = {};

  if (keyword) {
    // For keyword search, search across multiple fields
    queryObj['-or'] = [
      { title: { '-like': `%${keyword}%` } },
      { author: { '-like': `%${keyword}%` } },
    ];
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
    queryObj.subject = { '-like': `%${subject}%` };
  }

  let url = `/biblios?_page=${page}&_per_page=${perPage}`;

  if (Object.keys(queryObj).length > 0) {
    url += `&q=${encodeURIComponent(JSON.stringify(queryObj))}`;
  }

  return kohaRequest(url);
}

/**
 * Get patron's current checkouts
 */
async function getPatronCheckouts(patronId) {
  return kohaRequest(`/checkouts?patron_id=${patronId}`);
}

/**
 * Get patron's checkout history
 */
async function getPatronCheckoutHistory(patronId) {
  return kohaRequest(`/checkouts?patron_id=${patronId}&checked_in=1`);
}

/**
 * Renew a checkout
 */
async function renewCheckout(checkoutId) {
  return kohaRequest(`/checkouts/${checkoutId}/renewal`, {
    method: 'POST',
  });
}

/**
 * Check if checkout is renewable
 */
async function checkRenewability(checkoutId) {
  return kohaRequest(`/checkouts/${checkoutId}/allows_renewal`);
}

/**
 * Get patron's holds
 */
async function getPatronHolds(patronId) {
  return kohaRequest(`/holds?patron_id=${patronId}`);
}

/**
 * Place a hold
 */
async function placeHold({ patronId, biblioId, pickupLibraryId, notes = '' }) {
  return kohaRequest('/holds', {
    method: 'POST',
    body: JSON.stringify({
      patron_id: patronId,
      biblio_id: biblioId,
      pickup_library_id: pickupLibraryId,
      notes,
    }),
  });
}

/**
 * Cancel a hold
 */
async function cancelHold(holdId) {
  return kohaRequest(`/holds/${holdId}`, {
    method: 'DELETE',
  });
}

/**
 * Update a hold (e.g., change pickup location)
 */
async function updateHold(holdId, updates) {
  return kohaRequest(`/holds/${holdId}`, {
    method: 'PATCH',
    body: JSON.stringify(updates),
  });
}

/**
 * Get patron's account (fines/balance) - for future use
 */
async function getPatronAccount(patronId) {
  return kohaRequest(`/patrons/${patronId}/account`);
}

// Export all functions
export {
  kohaRequest,
  validateCredentials,
  getPatronByCardNumber,
  getPatronById,
  getLibraries,
  getLibraryById,
  getBooks,
  getBookById,
  getBookItems,
  searchBooks,
  getPatronCheckouts,
  getPatronCheckoutHistory,
  renewCheckout,
  checkRenewability,
  getPatronHolds,
  placeHold,
  cancelHold,
  updateHold,
  getPatronAccount,
  getBasicAuthHeader,
  KOHA_BASE_URL,
};
