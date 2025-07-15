import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { HeadBucketCommand } from '@aws-sdk/client-s3';
import { s3Client } from '../config/s3';

export const handleTestS3 = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const bucketName = process.env.USER_IMAGE_BUCKET_NAME;
    const command = new HeadBucketCommand({ Bucket: bucketName });
    await s3Client.send(command);

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: 'S3 bucket access successful',
        bucketName
      })
    };
  } catch (error) {
    console.error('S3 Test Error:', error);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: 'Error testing S3 connection',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}; 