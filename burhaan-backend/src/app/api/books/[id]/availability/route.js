/**
 * GET /api/books/[id]/availability
 * Get availability information for a book (items at each branch)
 */

import { getBookItems, getLibraries } from '@/lib/koha';
import { errorResponse, successResponse } from '@/lib/auth';

export async function GET(request, { params }) {
  try {
    const { id } = await params;
    const biblioId = parseInt(id, 10);

    if (isNaN(biblioId)) {
      return errorResponse('Invalid book ID', 400);
    }

    // Fetch items for this book
    const itemsResult = await getBookItems(biblioId);

    if (!itemsResult.success) {
      if (itemsResult.status === 404) {
        return errorResponse('Book not found', 404);
      }
      return errorResponse(itemsResult.error || 'Failed to fetch availability', itemsResult.status || 500);
    }

    // Fetch libraries for branch names
    const librariesResult = await getLibraries();
    const librariesMap = {};

    if (librariesResult.success && Array.isArray(librariesResult.data)) {
      librariesResult.data.forEach(lib => {
        librariesMap[lib.library_id] = lib.name;
      });
    }

    // Process items and group by library
    const items = Array.isArray(itemsResult.data) ? itemsResult.data : [];
    const availabilityByBranch = {};
    let totalCopies = 0;
    let availableCopies = 0;

    items.forEach(item => {
      const branchId = item.holding_library_id || item.home_library_id;
      const branchName = librariesMap[branchId] || branchId;

      if (!availabilityByBranch[branchId]) {
        availabilityByBranch[branchId] = {
          libraryId: branchId,
          libraryName: branchName,
          total: 0,
          available: 0,
          checkedOut: 0,
          onHold: 0,
          items: [],
        };
      }

      const isAvailable = !item.checkout && !item.hold;
      const isCheckedOut = !!item.checkout;
      const isOnHold = !!item.hold;

      availabilityByBranch[branchId].total++;
      totalCopies++;

      if (isAvailable) {
        availabilityByBranch[branchId].available++;
        availableCopies++;
      }
      if (isCheckedOut) {
        availabilityByBranch[branchId].checkedOut++;
      }
      if (isOnHold) {
        availabilityByBranch[branchId].onHold++;
      }

      availabilityByBranch[branchId].items.push({
        itemId: item.item_id,
        barcode: item.barcode,
        callNumber: item.callnumber,
        location: item.location,
        status: isAvailable ? 'available' : (isCheckedOut ? 'checked_out' : 'on_hold'),
        dueDate: item.checkout?.due_date || null,
      });
    });

    return successResponse({
      biblioId,
      totalCopies,
      availableCopies,
      isAvailable: availableCopies > 0,
      branches: Object.values(availabilityByBranch),
    });

  } catch (error) {
    console.error('Availability check error:', error);
    return errorResponse('Internal server error', 500);
  }
}
