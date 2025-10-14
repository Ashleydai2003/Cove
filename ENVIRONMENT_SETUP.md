# Environment Variables Setup Guide

## 🔐 Security Notice
**NEVER commit actual environment files to Git!** Environment files contain sensitive credentials and should always be kept local and secure.

## Backend Environment Setup

### Development
1. Copy the example file:
   ```bash
   cd Backend
   cp env.development.example env.development
   ```

2. Fill in your actual credentials in `env.development`:
   - Database credentials
   - AWS credentials
   - Firebase credentials
   - Sinch credentials (optional, for SMS)

### Production
1. Copy the example file:
   ```bash
   cd Backend
   cp env.production.example env.production
   ```

2. Fill in your production credentials in `env.production`

### Alternative: Using .env files
The backend also supports standard `.env` files. The `dotenv` package will load from:
- `env.development` (development)
- `env.production` (production)
- `dotenv` (custom env file)

## Required Environment Variables

### Database
- `DATABASE_URL`: PostgreSQL connection string

### AWS
- `AWS_ACCESS_KEY_ID`: AWS access key
- `AWS_SECRET_ACCESS_KEY`: AWS secret key
- `AWS_REGION`: AWS region (e.g., us-east-1)
- `S3_BUCKET_NAME`: S3 bucket for file uploads

### Firebase
- `FIREBASE_PROJECT_ID`: Firebase project ID
- `FIREBASE_CLIENT_EMAIL`: Firebase service account email
- `FIREBASE_PRIVATE_KEY`: Firebase service account private key

### Sinch (Optional - for SMS)
- `SINCH_SERVICE_PLAN_ID`: Sinch Service Plan ID
- `SINCH_API_TOKEN`: Sinch API Token
- `SINCH_PHONE_NUMBER`: Sinch phone number for SMS
- `SINCH_REGION`: Region (us or eu)
- `SINCH_WEBHOOK_SECRET`: Webhook secret for signature verification (REQUIRED for production)

### API Configuration
- `API_BASE_URL`: Base URL for the API
- `NODE_ENV`: Environment (development/production)
- `PORT`: Server port (default: 3001)

## WebApp Environment Setup

The WebApp uses standard Next.js environment variables. Create a `.env.local` file in the `WebApp` directory:

```bash
cd WebApp
cp .env.example .env.local  # If example exists
```

## Important Files

### ✅ Safe to Commit (Templates)
- `env.development.example`
- `env.production.example`
- `.env.example`
- This guide (ENVIRONMENT_SETUP.md)

### ❌ NEVER Commit (Actual Credentials)
- `env.development`
- `env.production`
- `dotenv`
- `.env`
- `.env.local`
- Any file with actual credentials

## Troubleshooting

### If you accidentally committed credentials:
1. Change all exposed credentials immediately
2. Remove files from Git history (contact your team lead)
3. Update `.gitignore` to prevent future commits

### If environment variables aren't loading:
1. Verify file naming matches exactly (case-sensitive)
2. Check that the file is in the correct directory
3. Restart the development server
4. Check for syntax errors in the env file

## Security Best Practices

1. **Never share** environment files via chat, email, or public channels
2. **Rotate credentials** regularly
3. **Use different credentials** for development, staging, and production
4. **Store production credentials** in a secure secret manager (AWS Secrets Manager, etc.)
5. **Review** `.gitignore` regularly to ensure env files are excluded

## Getting Credentials

See the following guides for obtaining credentials:
- Database: `Backend/EC2-SETUP.md`
- AWS: Contact team lead or AWS console
- Firebase: `Backend/FIREBASE-FCM-SETUP.md`
- Sinch: See `setup-sinch-secrets-access.sh` and Backend SMS setup docs
