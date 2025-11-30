/**
 * GET /api/user/card
 * Get the user's digital library card with QR code and barcode
 */

import { getPatronById } from '@/lib/koha';
import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { generateQRCode, generateBarcode } from '@/lib/helpers';

export async function GET(request) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;

  if (user.isGuest) {
    return errorResponse('Guests do not have library cards', 403);
  }

  try {
    // Fetch patron details from Koha
    const patronResult = await getPatronById(user.patronId);

    if (!patronResult.success) {
      return errorResponse('Failed to fetch card details', 500);
    }

    const patron = patronResult.data;
    const cardNumber = patron.cardnumber;

    // Generate QR code containing card number
    const qrCodeResult = await generateQRCode(cardNumber, {
      width: 300,
      margin: 2,
    });

    // Generate barcode
    const barcodeResult = await generateBarcode(cardNumber, {
      bcid: 'code128',
      height: 12,
      scale: 3,
    });

    // Calculate membership status
    const now = new Date();
    const expiryDate = patron.date_expiry ? new Date(patron.date_expiry) : null;
    const isExpired = expiryDate ? expiryDate < now : false;
    const daysUntilExpiry = expiryDate
      ? Math.ceil((expiryDate - now) / (1000 * 60 * 60 * 24))
      : null;

    return successResponse({
      card: {
        cardNumber: patron.cardnumber,
        patronId: patron.patron_id,
        firstName: patron.firstname,
        surname: patron.surname,
        fullName: `${patron.firstname} ${patron.surname}`.trim(),
        categoryId: patron.category_id,
        libraryId: patron.library_id,
        dateEnrolled: patron.date_enrolled,
        dateExpiry: patron.date_expiry,
        isExpired,
        daysUntilExpiry,
        status: isExpired ? 'expired' : 'active',
      },
      qrCode: qrCodeResult.success ? qrCodeResult.data : null,
      barcode: barcodeResult.success ? barcodeResult.data : null,
    });

  } catch (error) {
    console.error('Card fetch error:', error);
    return errorResponse('Internal server error', 500);
  }
}
