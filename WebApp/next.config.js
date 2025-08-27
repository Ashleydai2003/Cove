/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    typedRoutes: true,
  },
  images: {
    domains: [
      // S3 bucket domains for Cove
      'cove-cove-images.s3.us-west-1.amazonaws.com',
      'cove-event-images.s3.us-west-1.amazonaws.com',
      'cove-user-images.s3.us-west-1.amazonaws.com',
      // Generic S3 domains
      's3.amazonaws.com',
      's3.us-west-1.amazonaws.com',
    ],
    formats: ['image/webp', 'image/avif'],
  },
  async headers() {
    return [
      {
        source: '/events/:path*',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, s-maxage=60, stale-while-revalidate=300',
          },
        ],
      },
    ];
  },
  env: {
    BACKEND_API_URL: process.env.BACKEND_API_URL,
  },
};

module.exports = nextConfig; 