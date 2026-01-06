/** @type {import('next').NextConfig} */
const nextConfig = {
  // Enable instrumentation for cache warming on startup
  experimental: {
    instrumentationHook: true,
  },
};

export default nextConfig;
