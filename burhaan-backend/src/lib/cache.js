/**
 * Simple In-Memory Cache
 * For production, consider Redis for multi-instance deployments
 */

class Cache {
  constructor() {
    this.store = new Map();
    this.defaultTTL = 5 * 60 * 1000; // 5 minutes default
  }

  /**
   * Generate cache key from params
   */
  key(prefix, params = {}) {
    const sorted = Object.keys(params).sort().map(k => `${k}=${params[k]}`).join('&');
    return `${prefix}:${sorted}`;
  }

  /**
   * Get item from cache
   */
  get(key) {
    const item = this.store.get(key);
    if (!item) return null;

    if (Date.now() > item.expiry) {
      this.store.delete(key);
      return null;
    }

    return item.data;
  }

  /**
   * Set item in cache
   */
  set(key, data, ttl = this.defaultTTL) {
    this.store.set(key, {
      data,
      expiry: Date.now() + ttl,
    });
  }

  /**
   * Delete item from cache
   */
  delete(key) {
    this.store.delete(key);
  }

  /**
   * Clear all items with prefix
   */
  clearPrefix(prefix) {
    for (const key of this.store.keys()) {
      if (key.startsWith(prefix)) {
        this.store.delete(key);
      }
    }
  }

  /**
   * Clear entire cache
   */
  clear() {
    this.store.clear();
  }

  /**
   * Get cache stats
   */
  stats() {
    let valid = 0;
    let expired = 0;
    const now = Date.now();

    for (const item of this.store.values()) {
      if (now > item.expiry) {
        expired++;
      } else {
        valid++;
      }
    }

    return { valid, expired, total: this.store.size };
  }
}

// Singleton instance
const cache = new Cache();

// Cache TTL constants (in milliseconds)
export const CACHE_TTL = {
  BOOKS_LIST: 12 * 60 * 60 * 1000,   // 12 hours for book listings
  BOOK_DETAIL: 24 * 60 * 60 * 1000,  // 24 hours for individual books (rarely change)
  BOOK_COUNT: 24 * 60 * 60 * 1000,   // 24 hours for total count
  LIBRARIES: 24 * 60 * 60 * 1000,    // 24 hours for libraries (almost never change)
  CATEGORIES: 24 * 60 * 60 * 1000,   // 24 hours for categories
  AVAILABILITY: 5 * 60 * 1000,       // 5 minutes for availability (needs to be fresh)
};

export default cache;
