/**
 * Next.js Instrumentation
 * Runs once when the server starts - used for cache warming
 */

export async function register() {
  // Only run on server (not edge runtime)
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    const { initializeCacheWarming } = await import('./lib/cache-warmer.js');

    // Warm caches on server start
    // Use setTimeout to not block server startup
    setTimeout(async () => {
      try {
        await initializeCacheWarming();
      } catch (error) {
        console.error('Failed to initialize cache warming:', error);
      }
    }, 1000); // Small delay to let server fully initialize
  }
}
