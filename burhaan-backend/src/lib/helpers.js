/**
 * Helper Utilities
 * Common helper functions used across the application
 */

import QRCode from 'qrcode';
import bwipjs from 'bwip-js';

/**
 * Generate QR Code as base64 data URL
 */
export async function generateQRCode(data, options = {}) {
  const defaultOptions = {
    width: 300,
    margin: 2,
    color: {
      dark: '#000000',
      light: '#ffffff',
    },
    ...options,
  };

  try {
    const qrDataUrl = await QRCode.toDataURL(data, defaultOptions);
    return { success: true, data: qrDataUrl };
  } catch (error) {
    console.error('QR Code generation error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Generate Barcode as base64 PNG
 */
export async function generateBarcode(data, options = {}) {
  const defaultOptions = {
    bcid: 'code128', // Barcode type
    text: data,
    scale: 3,
    height: 10,
    includetext: true,
    textxalign: 'center',
    ...options,
  };

  try {
    const png = await bwipjs.toBuffer(defaultOptions);
    const base64 = `data:image/png;base64,${png.toString('base64')}`;
    return { success: true, data: base64 };
  } catch (error) {
    console.error('Barcode generation error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Format patron data for response (remove sensitive fields)
 */
export function formatPatronResponse(patron) {
  if (!patron) return null;

  return {
    patronId: patron.patron_id,
    cardNumber: patron.cardnumber,
    firstName: patron.firstname,
    surname: patron.surname,
    fullName: `${patron.firstname} ${patron.surname}`.trim(),
    email: patron.email,
    phone: patron.phone,
    mobile: patron.mobile,
    address: patron.address,
    city: patron.city,
    state: patron.state,
    postalCode: patron.postal_code,
    country: patron.country,
    dateOfBirth: patron.date_of_birth,
    dateEnrolled: patron.date_enrolled,
    dateExpiry: patron.date_expiry,
    libraryId: patron.library_id,
    categoryId: patron.category_id,
    // Exclude sensitive fields like password, etc.
  };
}

/**
 * Format book/biblio data for response
 */
export function formatBookResponse(book) {
  if (!book) return null;

  // Detect URL type from the generic url field
  let ebookUrl = book.ebook_url || null;
  let youtubeUrl = book.youtube_url || null;
  let pdfUrl = book.pdf_url || null;

  // Check if generic url field contains specific media types
  if (book.url) {
    const url = book.url.toLowerCase();
    if (url.includes('youtube.com') || url.includes('youtu.be')) {
      youtubeUrl = youtubeUrl || book.url;
    } else if (url.includes('.pdf')) {
      pdfUrl = pdfUrl || book.url;
    } else {
      ebookUrl = ebookUrl || book.url;
    }
  }

  return {
    biblioId: book.biblio_id,
    title: book.title,
    author: book.author,
    isbn: book.isbn,
    publicationYear: book.publication_year || book.copyright_date?.toString() || null,
    publisher: book.publisher,
    language: book.language,
    subjects: book.subjects || [],
    callNumber: book.call_number || book.cn_class,
    shelfNumber: book.shelf_number,
    physicalDescription: book.physical_description || book.pages,
    series: book.series || book.series_title,
    notes: book.notes,
    // Generate image URL
    imageUrl: `https://library.al-burhaan.org/cgi-bin/koha/opac-image.pl?thumbnail=1&biblionumber=${book.biblio_id}&filetype=image`,
    ebookUrl,
    youtubeUrl,
    pdfUrl,
  };
}

/**
 * Format checkout/loan data for response
 */
export function formatCheckoutResponse(checkout, bookDetails = null) {
  if (!checkout) return null;

  const dueDate = new Date(checkout.due_date);
  const now = new Date();
  const isOverdue = dueDate < now;
  const daysUntilDue = Math.ceil((dueDate - now) / (1000 * 60 * 60 * 24));

  return {
    checkoutId: checkout.checkout_id,
    patronId: checkout.patron_id,
    itemId: checkout.item_id,
    biblioId: bookDetails?.biblio_id || null,
    dueDate: checkout.due_date,
    issueDate: checkout.issue_date,
    renewals: checkout.renewals || 0,
    isOverdue,
    daysUntilDue,
    // Book details if available
    book: bookDetails ? formatBookResponse(bookDetails) : null,
  };
}

/**
 * Format hold data for response
 */
export function formatHoldResponse(hold) {
  if (!hold) return null;

  return {
    holdId: hold.hold_id,
    patronId: hold.patron_id,
    biblioId: hold.biblio_id,
    itemId: hold.item_id,
    holdDate: hold.hold_date,
    expirationDate: hold.expiration_date,
    pickupLibraryId: hold.pickup_library_id,
    status: hold.status,
    priority: hold.priority,
    notes: hold.notes,
  };
}

/**
 * Format library/branch data for response
 */
export function formatLibraryResponse(library) {
  if (!library) return null;

  return {
    libraryId: library.library_id,
    name: library.name,
    address1: library.address1,
    address2: library.address2,
    address3: library.address3,
    city: library.city,
    state: library.state,
    postalCode: library.postal_code,
    country: library.country,
    phone: library.phone,
    fax: library.fax,
    email: library.email,
    url: library.url,
    notes: library.notes,
    isActive: library.is_active,
  };
}

/**
 * Parse pagination parameters from request
 */
export function getPaginationParams(searchParams) {
  const page = parseInt(searchParams.get('page') || '1', 10);
  const perPage = parseInt(searchParams.get('per_page') || '10', 10);

  return {
    page: Math.max(1, page),
    perPage: Math.min(100, Math.max(1, perPage)), // Limit to 100 max
  };
}

/**
 * Create paginated response
 */
export function paginatedResponse(data, page, perPage, total = null) {
  return {
    success: true,
    data,
    pagination: {
      page,
      perPage,
      total,
      totalPages: total ? Math.ceil(total / perPage) : null,
      hasMore: total ? page * perPage < total : data.length === perPage,
    },
  };
}

/**
 * Validate required fields
 */
export function validateRequired(body, fields) {
  const missing = fields.filter(field => !body[field]);

  if (missing.length > 0) {
    return {
      valid: false,
      error: `Missing required fields: ${missing.join(', ')}`,
    };
  }

  return { valid: true };
}

/**
 * Sleep utility for rate limiting
 */
export function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
