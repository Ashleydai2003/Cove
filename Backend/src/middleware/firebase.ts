// firebase.ts
import * as admin from 'firebase-admin';
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

const secretsManager = new SecretsManagerClient({
  region: 'us-west-1',
});

let firebaseInitialized = false;

export const initializeFirebase = async () => {
  if (admin.apps.length > 0 || firebaseInitialized) {
    return;
  }

  // Use emulator if configured
  if (process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    // Only projectId is required for emulator
    admin.initializeApp({
      projectId: process.env.FIREBASE_PROJECT_ID,
    });
    firebaseInitialized = true;
    console.log('[firebase] Initialized Firebase Admin for emulator');
    return;
  }

  // Otherwise, use AWS Secrets Manager (production)
  const secretId = 'firebaseSDK';
  if (!secretId) {
    throw new Error('Firebase secret name is not set');
  }

  try {
    console.log('[firebase] Attempting to retrieve Firebase credentials from Secrets Manager...');
    const response = await secretsManager.send(
      new GetSecretValueCommand({
        SecretId: secretId,
        VersionStage: 'AWSCURRENT',
      })
    );

    if (!response.SecretString) {
      throw new Error('Failed to retrieve Firebase credentials from Secrets Manager');
    }

    const credentials = JSON.parse(response.SecretString);
    console.log('[firebase] Successfully retrieved Firebase credentials from Secrets Manager');

    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: credentials.project_id,
        clientEmail: credentials.client_email,
        privateKey: credentials.private_key.replace(/\\n/g, '\n'),
      }),
    });

    firebaseInitialized = true;
    console.log('[firebase] Initialized Firebase Admin with Secrets Manager credentials');
  } catch (error) {
    console.error('Error retrieving Firebase credentials:', error);
    throw error;
  }
};
