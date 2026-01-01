/**
 * POST /api/auth/register
 * Register a new patron account
 *
 * Creates a new patron in Koha and optionally links an SSO account
 */

import { kohaRequest, getPatronCategories, getLibraries } from '@/lib/koha';
import { generateToken, errorResponse, successResponse, getTokenExpiry } from '@/lib/auth';
import { validateRequired } from '@/lib/helpers';
import { prisma } from '@/lib/db';

export async function POST(request) {
  try {
    const body = await request.json();

    // Validate required fields
    const validation = validateRequired(body, ['firstName', 'surname', 'email']);
    if (!validation.valid) {
      return errorResponse(validation.error, 400);
    }

    const {
      firstName,
      surname,
      email,
      phone,
      dateOfBirth,
      address,
      city,
      state,
      postalCode,
      country,
      libraryId,
      categoryId,
      // SSO fields (optional)
      ssoProvider,
      ssoProviderAccountId,
    } = body;

    // Check if email already exists in Koha
    const emailQuery = JSON.stringify({ email });
    const existingResult = await kohaRequest(`/patrons?q=${encodeURIComponent(emailQuery)}`);

    if (existingResult.success && existingResult.data && existingResult.data.length > 0) {
      return errorResponse('An account with this email already exists', 409, 'EMAIL_EXISTS');
    }

    // Validate category and library IDs are provided
    if (!categoryId) {
      return errorResponse('Patron category is required', 400, 'MISSING_CATEGORY');
    }
    if (!libraryId) {
      return errorResponse('Library is required', 400, 'MISSING_LIBRARY');
    }

    // Build patron object for Koha
    const patronData = {
      firstname: firstName,
      surname: surname,
      email: email,
      category_id: categoryId,
      library_id: libraryId,
    };

    // Add optional fields if provided
    if (phone) patronData.phone = phone;
    if (dateOfBirth) patronData.date_of_birth = dateOfBirth;
    if (address) patronData.address = address;
    if (city) patronData.city = city;
    if (state) patronData.state = state;
    if (postalCode) patronData.postal_code = postalCode;
    if (country) patronData.country = country;

    // Create patron in Koha
    const createResult = await kohaRequest('/patrons', {
      method: 'POST',
      body: JSON.stringify(patronData),
    });

    if (!createResult.success) {
      console.error('Koha patron creation failed:', createResult.error);

      // Handle specific Koha errors
      if (createResult.status === 409) {
        return errorResponse('A patron with these details already exists', 409, 'DUPLICATE_PATRON');
      }

      return errorResponse(createResult.error || 'Failed to create account', createResult.status || 500);
    }

    const patron = createResult.data;

    // If SSO provider info provided, create SSO link
    if (ssoProvider && ssoProviderAccountId) {
      try {
        await prisma.ssoAccount.create({
          data: {
            provider: ssoProvider,
            providerAccountId: ssoProviderAccountId,
            email: email,
            patronId: patron.patron_id,
            firstName: firstName,
            lastName: surname,
          },
        });
      } catch (ssoError) {
        console.warn('Failed to create SSO link:', ssoError.message);
        // Continue even if SSO link fails
      }
    }

    // Generate JWT token for immediate login
    const token = generateToken(patron);
    const expiresAt = getTokenExpiry();

    // Store session
    try {
      await prisma.session.create({
        data: {
          patronId: patron.patron_id,
          token,
          expiresAt,
        },
      });
    } catch (dbError) {
      console.warn('Session storage failed:', dbError.message);
    }

    return successResponse({
      token,
      expiresAt: expiresAt.toISOString(),
      user: {
        patronId: patron.patron_id,
        cardNumber: patron.cardnumber,
        firstName: patron.firstname,
        surname: patron.surname,
        email: patron.email,
        libraryId: patron.library_id,
        categoryId: patron.category_id,
      },
    }, 'Registration successful');

  } catch (error) {
    console.error('Registration error:', error);
    return errorResponse('Internal server error', 500);
  }
}

/**
 * GET /api/auth/register
 * Get registration requirements (categories, libraries, etc.)
 */
export async function GET(request) {
  try {
    // Fetch available libraries and patron categories from Koha
    const [librariesResult, categoriesResult] = await Promise.all([
      getLibraries(),
      getPatronCategories(),
    ]);

    const libraries = librariesResult.success ? librariesResult.data : [];
    const rawCategories = categoriesResult.success ? categoriesResult.data : [];

    console.log('Fetched libraries:', libraries.length);
    console.log('Fetched categories:', rawCategories.length, rawCategories);

    // Map categories to expected format
    const categories = rawCategories.map(cat => ({
      id: cat.category_id,
      name: cat.description || cat.category_id,
      description: cat.description,
    }));

    return successResponse({
      libraries: libraries.map(lib => ({
        id: lib.library_id,
        name: lib.name,
        address: lib.address1,
        city: lib.city,
      })),
      categories,
      requiredFields: ['firstName', 'surname', 'email'],
      optionalFields: ['phone', 'dateOfBirth', 'address', 'city', 'state', 'postalCode', 'country'],
    });

  } catch (error) {
    console.error('Registration info error:', error);
    return errorResponse('Internal server error', 500);
  }
}
