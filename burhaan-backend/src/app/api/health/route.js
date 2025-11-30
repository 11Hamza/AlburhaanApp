/**
 * GET /api/health
 * Health check endpoint for monitoring
 */

import { kohaRequest } from '@/lib/koha';

export async function GET(request) {
  const startTime = Date.now();

  // Check Koha API connectivity
  let kohaStatus = 'unknown';
  let kohaLatency = null;

  try {
    const kohaStart = Date.now();
    const result = await kohaRequest('/libraries?_per_page=1');
    kohaLatency = Date.now() - kohaStart;
    kohaStatus = result.success ? 'healthy' : 'unhealthy';
  } catch (error) {
    kohaStatus = 'error';
  }

  const totalLatency = Date.now() - startTime;

  return Response.json({
    status: kohaStatus === 'healthy' ? 'healthy' : 'degraded',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    services: {
      koha: {
        status: kohaStatus,
        latency: kohaLatency ? `${kohaLatency}ms` : null,
      },
    },
    latency: `${totalLatency}ms`,
  });
}
