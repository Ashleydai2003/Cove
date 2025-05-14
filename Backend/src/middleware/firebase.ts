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

  const secretId = 'firebaseSDK';  // Using the name from AWS
  if (!secretId) {
    throw new Error('Firebase secret name is not set');
  }

  try {
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

    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: credentials.project_id,
        clientEmail: credentials.client_email,
        privateKey: credentials.private_key.replace(/\\n/g, '\n'),
      }),
    });

    firebaseInitialized = true;
  } catch (error) {
    console.error('Error retrieving Firebase credentials:', error);
    throw error;
  }
};
