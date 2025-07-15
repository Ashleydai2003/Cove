import { S3Client } from '@aws-sdk/client-s3';

// Create S3 client with MinIO support for local development
export const s3Client = new S3Client({
  region: process.env.AWS_REGION || 'us-west-1',
  credentials: process.env.AWS_ENDPOINT_URL ? {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || 'minioadmin',
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || 'minioadmin',
  } : undefined,
  endpoint: process.env.AWS_ENDPOINT_URL || undefined,
  forcePathStyle: !!process.env.AWS_ENDPOINT_URL, // Required for MinIO
});

// Helper function to get bucket URL for presigned URLs
export const getBucketUrl = (bucketName: string): string => {
  if (process.env.AWS_ENDPOINT_URL) {
    // Local MinIO URL
    return `${process.env.AWS_ENDPOINT_URL}/${bucketName}`;
  } else {
    // Production S3 URL
    return `https://${bucketName}.s3.${process.env.AWS_REGION}.amazonaws.com`;
  }
}; 