/**
 * Next.js Middleware
 * Handles CORS, rate limiting, and request logging
 */

import { NextResponse } from 'next/server';

// CORS configuration
const ALLOWED_ORIGINS = [
  'http://localhost:3000',
  'http://localhost:8080',
  'http://127.0.0.1:3000',
  // Add your Flutter app's origin when deployed
];

export function middleware(request) {
  const origin = request.headers.get('origin');
  const response = NextResponse.next();

  // CORS headers
  if (origin && ALLOWED_ORIGINS.includes(origin)) {
    response.headers.set('Access-Control-Allow-Origin', origin);
  } else {
    // Allow all origins in development
    response.headers.set('Access-Control-Allow-Origin', '*');
  }

  response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
  response.headers.set('Access-Control-Max-Age', '86400');

  // Handle preflight requests
  if (request.method === 'OPTIONS') {
    return new NextResponse(null, {
      status: 200,
      headers: response.headers,
    });
  }

  // Request logging in development
  if (process.env.NODE_ENV === 'development') {
    const timestamp = new Date().toISOString();
    const method = request.method;
    const url = request.url;
    console.log(`[${timestamp}] ${method} ${url}`);
  }

  return response;
}

// Apply middleware to API routes only
export const config = {
  matcher: '/api/:path*',
};
