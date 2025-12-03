/**
 * Koha API Client
 * Handles all communication with the Koha Library Management System API
 */

const KOHA_BASE_URL = process.env.KOHA_BASE_URL || 'https://library.al-burhaan.org/api/v1';
const KOHA_USERNAME = process.env.KOHA_USERNAME;
const KOHA_PASSWORD = process.env.KOHA_PASSWORD;

/**
 * Create Basic Auth header
 */
function getBasicAuthHeader(username = KOHA_USERNAME, password = KOHA_PASSWORD) {
  const credentials = Buffer.from(`${username}:${password}`).toString('base64');
  return `Basic ${credentials}`;
}

/**
 * Make authenticated request to Koha API
 */
async function kohaRequest(endpoint, options = {}, userCredentials = null) {
  const url = `${KOHA_BASE_URL}${endpoint}`;

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
    const response = await fetch(url, {
      ...options,
      headers,
    });

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
    console.error('Koha API Error:', error);
    return {
      success: false,
      status: 500,
      error: error.message || 'Network error',
      data: null,
    };
  }
}

/**
 * Validate user credentials against Koha
 */
async function validateCredentials(cardNumber, password) {
  // Try to fetch patron info with provided credentials
  const result = await kohaRequest('/patrons', {
    method: 'GET',
  }, { username: cardNumber, password });

  return result.success;
}

/**
 * Get patron by card number
 */
async function getPatronByCardNumber(cardNumber) {
  const query = JSON.stringify({ cardnumber: cardNumber });
  const result = await kohaRequest(`/patrons?q=${encodeURIComponent(query)}`);

  if (result.success && result.data && result.data.length > 0) {
    return { success: true, data: result.data[0] };
  }

  return { success: false, error: 'Patron not found', data: null };
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
 */
async function getBooks({ page = 1, perPage = 10, query = null, filters = {} } = {}) {
  let url = `/biblios?_page=${page}&_per_page=${perPage}`;

  // Build query object for filtering
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

  if (filters.subject) {
    queryObj.subject = { '-like': `%${filters.subject}%` };
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
