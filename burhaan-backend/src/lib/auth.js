/**
 * Authentication Utilities
 * Handles JWT token generation, validation, and session management
 */

const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-jwt-key';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

/**
 * Generate JWT token for a patron
 */
function generateToken(patron) {
  const payload = {
    patronId: patron.patron_id,
    cardNumber: patron.cardnumber,
    firstName: patron.firstname,
    surname: patron.surname,
    email: patron.email,
    libraryId: patron.library_id,
    categoryId: patron.category_id,
    isGuest: patron.isGuest || false,
  };

  return jwt.sign(payload, JWT_SECRET, {
    expiresIn: JWT_EXPIRES_IN,
  });
}

/**
 * Verify and decode JWT token
 */
function verifyToken(token) {
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    return { valid: true, decoded, error: null };
  } catch (error) {
    return { valid: false, decoded: null, error: error.message };
  }
}

/**
 * Extract token from Authorization header
 */
function extractToken(authHeader) {
  if (!authHeader) return null;

  if (authHeader.startsWith('Bearer ')) {
    return authHeader.substring(7);
  }

  return null;
}

/**
 * Middleware helper to get current user from request
 */
function getCurrentUser(request) {
  const authHeader = request.headers.get('authorization');
  const token = extractToken(authHeader);

  if (!token) {
    return { authenticated: false, user: null, error: 'No token provided' };
  }

  const { valid, decoded, error } = verifyToken(token);

  if (!valid) {
    return { authenticated: false, user: null, error };
  }

  return { authenticated: true, user: decoded, error: null };
}

/**
 * Calculate token expiry date
 */
function getTokenExpiry() {
  const match = JWT_EXPIRES_IN.match(/^(\d+)([dhms])$/);
  if (!match) {
    // Default to 7 days
    return new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
  }

  const [, value, unit] = match;
  const num = parseInt(value, 10);

  const multipliers = {
    s: 1000,
    m: 60 * 1000,
    h: 60 * 60 * 1000,
    d: 24 * 60 * 60 * 1000,
  };

  return new Date(Date.now() + num * multipliers[unit]);
}

/**
 * Create standardized API response
 */
function apiResponse(data, status = 200) {
  return Response.json(data, { status });
}

/**
 * Create error response
 */
function errorResponse(message, status = 400, code = null) {
  return Response.json({
    success: false,
    error: message,
    code,
  }, { status });
}

/**
 * Create success response
 */
function successResponse(data, message = null) {
  return Response.json({
    success: true,
    message,
    data,
  }, { status: 200 });
}

/**
 * Require authentication middleware helper
 */
function requireAuth(request) {
  const { authenticated, user, error } = getCurrentUser(request);

  if (!authenticated) {
    return {
      authorized: false,
      response: errorResponse(error || 'Unauthorized', 401, 'UNAUTHORIZED'),
    };
  }

  return { authorized: true, user };
}

module.exports = {
  generateToken,
  verifyToken,
  extractToken,
  getCurrentUser,
  getTokenExpiry,
  apiResponse,
  errorResponse,
  successResponse,
  requireAuth,
};
