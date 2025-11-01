import { S3Client, CreateBucketCommand, HeadBucketCommand } from '@aws-sdk/client-s3';
import { s3Client } from '../config/s3';

const buckets = [
  process.env.USER_IMAGE_BUCKET_NAME || 'cove-user-images-dev',
  process.env.COVE_IMAGE_BUCKET_NAME || 'cove-cove-images-dev',
  process.env.EVENT_IMAGE_BUCKET_NAME || 'cove-event-images-dev',
  process.env.VENDOR_COVER_IMAGE_BUCKET_NAME || 'vendor-cover-images-dev',
  process.env.VENDOR_USER_IMAGE_BUCKET_NAME || 'vendor-user-images-dev',
];

async function createBucketIfNotExists(bucketName: string) {
  try {
    // Check if bucket exists
    await s3Client.send(new HeadBucketCommand({ Bucket: bucketName }));
    console.log(`✅ Bucket "${bucketName}" already exists`);
  } catch (error: any) {
    if (error.name === 'NotFound') {
      // Bucket doesn't exist, create it
      try {
        await s3Client.send(new CreateBucketCommand({ Bucket: bucketName }));
        console.log(`✅ Created bucket "${bucketName}"`);
      } catch (createError: any) {
        console.error(`❌ Failed to create bucket "${bucketName}":`, createError.message);
      }
    } else {
      console.error(`❌ Error checking bucket "${bucketName}":`, error.message);
    }
  }
}

async function setupMinIOBuckets() {
  console.log('🚀 Setting up MinIO buckets for local development...');
  
  // Wait for MinIO to be ready
  let retries = 30;
  while (retries > 0) {
    try {
      await s3Client.send(new HeadBucketCommand({ Bucket: 'test-connection' }));
      break;
    } catch (error) {
      retries--;
      if (retries === 0) {
        console.log('⚠️  MinIO is not ready yet, but continuing with bucket creation...');
      } else {
        console.log(`⏳ Waiting for MinIO to be ready... (${retries} retries left)`);
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }
  }

  // Create all buckets
  for (const bucket of buckets) {
    await createBucketIfNotExists(bucket);
  }
  
  console.log('✅ MinIO bucket setup complete!');
  console.log('🌐 MinIO Console: http://localhost:9001');
  console.log('🔑 Login: minioadmin / minioadmin');
}

// Run the setup
setupMinIOBuckets().catch(console.error); 