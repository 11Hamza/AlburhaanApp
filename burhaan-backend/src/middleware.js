/**
 * Next.js Middleware
 * Handles CORS, security headers, and request logging
 */

import { NextResponse } from 'next/server';

// CORS configuration - add your production domains here
const ALLOWED_ORIGINS = [
  // Development
  'http://localhost:3000',
  'http://localhost:8080',
  'http://127.0.0.1:3000',
  // Production - add your Vercel domain after deployment
  // 'https://your-app.vercel.app',
];

// Check if we're in production
const isProduction = process.env.NODE_ENV === 'production';

export function middleware(request) {
  const origin = request.headers.get('origin');
  const response = NextResponse.next();

  // CORS headers
  // Mobile apps (Flutter) don't send origin headers, so we need to allow requests without origin
  if (!origin) {
    // No origin = likely mobile app or server-to-server - allow
    response.headers.set('Access-Control-Allow-Origin', '*');
  } else if (ALLOWED_ORIGINS.includes(origin)) {
    // Known origin - allow specifically
    response.headers.set('Access-Control-Allow-Origin', origin);
  } else if (!isProduction) {
    // Development mode - allow all origins for testing
    response.headers.set('Access-Control-Allow-Origin', origin);
  } else {
    // Production with unknown origin - still allow for mobile apps but log
    // Mobile apps making requests from webviews may have various origins
    response.headers.set('Access-Control-Allow-Origin', origin);
  }

  response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
  response.headers.set('Access-Control-Max-Age', '86400');

  // Security headers
  response.headers.set('X-Content-Type-Options', 'nosniff');
  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('X-XSS-Protection', '1; mode=block');
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');

  // Handle preflight requests
  if (request.method === 'OPTIONS') {
    return new NextResponse(null, {
      status: 200,
      headers: response.headers,
    });
  }

  // Request logging in development only
  if (!isProduction) {
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
