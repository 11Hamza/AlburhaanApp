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
    let data = null;

    // Only try to parse body if there's content
    const responseText = await response.text();
    if (responseText) {
      if (contentType && contentType.includes('application/json')) {
        try {
          data = JSON.parse(responseText);
        } catch {
          data = responseText;
        }
      } else {
        data = responseText;
      }
    }

    if (!response.ok) {
      return {
        success: false,
        status: response.status,
        error: data?.error || data?.message || 'Request failed',
        errorCode: data?.error_code || null,
        data: data, // Preserve full error response for debugging
        total: null,
      };
    }

    // Get total count from Koha headers
    // Koha uses X-Total-Count or x-total-count
    const totalCount = response.headers.get('X-Total-Count')
      || response.headers.get('x-total-count')
      || response.headers.get('Total-Count');

    // Log headers for debugging
    console.log('Koha response headers:', {
      'X-Total-Count': response.headers.get('X-Total-Count'),
      'x-total-count': response.headers.get('x-total-count'),
      'content-type': response.headers.get('content-type'),
    });

    return {
      success: true,
      status: response.status,
      data,
      error: null,
      total: totalCount ? parseInt(totalCount, 10) : null,
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
    console.log('DEBUG: Validating credentials at:', url);

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

    console.log('DEBUG: Koha password validation response status:', response.status);

    // Success statuses: 200, 201, 204
    // 400 means invalid credentials
    const isSuccess = response.status === 200 || response.status === 201 || response.status === 204;

    if (!isSuccess) {
      const text = await response.text();
      console.log('DEBUG: Koha validation error response:', text);
    }

    return isSuccess;
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
    return { success: true, data: result.data[0] };
  }

  return { success: false, data: null, error: 'Patron not found' };
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
 * Get all patron categories
 */
async function getPatronCategories() {
  return kohaRequest('/patron_categories');
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
  const holdData = {
    patron_id: patronId,
    biblio_id: biblioId,
    pickup_library_id: pickupLibraryId,
    notes,
  };
  console.log('DEBUG: Sending hold request to Koha:', JSON.stringify(holdData, null, 2));

  const result = await kohaRequest('/holds', {
    method: 'POST',
    body: JSON.stringify(holdData),
  });

  console.log('DEBUG: Koha hold response:', JSON.stringify(result, null, 2));
  return result;
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
  getPatronCategories,
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
