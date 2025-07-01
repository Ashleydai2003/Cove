# CI/CD Setup Guide

This guide walks you through setting up the complete CI/CD pipeline for the Cove app, including backend deployment via AWS Lambda and iOS deployment via TestFlight/App Store.

> **🎯 Quick Start**: If you just want to get the backend pipeline working, focus on the AWS secrets in Step 4. The iOS pipeline is optional and can be added later when you're ready for automated app distribution.

## 🏗️ Architecture Overview

### Backend Pipeline
- **Triggers**: Push to `main`/`develop` branches, PRs on Backend files
- **Testing**: PostgreSQL service container for database tests
- **Smart Migrations**: Only runs migrations when `schema.prisma` changes are detected
- **Migration Process**: EC2 instance with SSM, matches your manual workflow exactly
- **Deployment**: AWS Lambda function updates
- **Environments**: Production (`main`) and Staging (`develop`)
- **Cost Optimization**: EC2 instance only starts when schema changes detected

### iOS Pipeline (Optional)
- **Triggers**: Push to `main`/`develop` branches, PRs on iOS files  
- **Testing**: Xcode unit tests on iOS simulator
- **Distribution**: TestFlight (`develop`) and App Store (`main`)
- **Environments**: Staging and Production builds
- **Code Signing**: Automated certificate and provisioning profile management

## 🔐 Required GitHub Secrets

### AWS/Backend Secrets (Required)
These secrets are needed for the backend deployment pipeline to work.

| Secret Name | Description | How to Get | Example Value |
|-------------|-------------|------------|---------------|
| `AWS_ROLE_ARN` | GitHub Actions OIDC role ARN | Already created in your setup | `arn:aws:iam::019721216575:role/GitHubActionsRole` |
| `AWS_REGION` | AWS region | Your existing region | `us-west-1` |
| `EC2_INSTANCE_ID` | Migration EC2 instance ID | Your existing EC2 instance | `i-0979980f973e94cb5` |
| `RDS_SECRET_ARN` | RDS credentials secret ARN | From AWS Secrets Manager console | `arn:aws:secretsmanager:us-west-1:019721216575:secret:rds!db-...` |

### iOS Secrets (Optional - Only needed for iOS deployment)
These secrets are only required if you want automated iOS app deployment. You can skip these and still use the backend pipeline.

| Secret Name | Description | How to Get | When Needed |
|-------------|-------------|------------|-------------|
| `IOS_CERTIFICATE_P12` | Base64 encoded .p12 certificate | Export from Keychain Access | iOS builds |
| `IOS_CERTIFICATE_PASSWORD` | Password for .p12 certificate | Set when exporting certificate | iOS builds |
| `IOS_TEAM_ID` | Apple Developer Team ID | Apple Developer Account settings | iOS builds |
| `IOS_PROVISIONING_PROFILE_STAGING` | Base64 encoded staging profile | Apple Developer Portal | TestFlight uploads |
| `IOS_PROVISIONING_PROFILE_PRODUCTION` | Base64 encoded production profile | Apple Developer Portal | App Store uploads |
| `IOS_PROVISIONING_PROFILE_NAME_STAGING` | Staging profile name | From provisioning profile | TestFlight uploads |
| `IOS_PROVISIONING_PROFILE_NAME_PRODUCTION` | Production profile name | From provisioning profile | App Store uploads |
| `APP_STORE_CONNECT_API_KEY` | Base64 encoded App Store Connect API key | App Store Connect | App uploads |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect Issuer ID | App Store Connect | App uploads |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect Key ID | App Store Connect | App uploads |

## 📋 Setup Steps

### Step 1: Verify AWS Infrastructure
Ensure your existing infrastructure is properly configured:

```bash
# Check EC2 instance status
aws ec2 describe-instances --instance-ids i-0979980f973e94cb5

# Verify SSM connectivity
aws ssm describe-instance-information --filters "Key=InstanceIds,Values=i-0979980f973e94cb5"

# Test Lambda function exists
aws lambda get-function --function-name hello-lambda
```

### Step 2: Set Up iOS Certificates

#### Create Distribution Certificate
1. Go to Apple Developer Portal → Certificates
2. Create new "iOS Distribution" certificate
3. Download and install in Keychain Access
4. Export as .p12 with password
5. Convert to base64: `base64 -i certificate.p12 | pbcopy`

#### Create Provisioning Profiles
1. Go to Apple Developer Portal → Profiles
2. Create "App Store" profiles for staging and production
3. Download .mobileprovision files
4. Convert to base64: `base64 -i profile.mobileprovision | pbcopy`

#### Create App Store Connect API Key
1. Go to App Store Connect → Users and Access → Keys
2. Create new API key with "Developer" role
3. Download .p8 file
4. Convert to base64: `base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy`
5. Note the Key ID and Issuer ID

### Step 3: Configure GitHub Environments

#### Create Production Environment
1. Go to repo Settings → Environments
2. Create "production" environment
3. Add protection rules:
   - Required reviewers: Add team members
   - Deployment branches: Limit to `main` branch

### Step 4: Add GitHub Secrets
Go to repo Settings → Secrets and Variables → Actions:

```bash
# AWS Secrets (already configured based on your setup)
AWS_ROLE_ARN=arn:aws:iam::019721216575:role/GitHubActionsRole
AWS_REGION=us-west-1
EC2_INSTANCE_ID=i-0979980f973e94cb5
RDS_SECRET_ARN=arn:aws:secretsmanager:us-west-1:019721216575:secret:rds!db-7c509add-7d20-4a07-9dda-ba0f85e5689e

# iOS Secrets (need to be added)
IOS_CERTIFICATE_P12=<base64-encoded-p12>
IOS_CERTIFICATE_PASSWORD=<password>
IOS_TEAM_ID=<team-id>
IOS_PROVISIONING_PROFILE_STAGING=<base64-encoded-profile>
IOS_PROVISIONING_PROFILE_PRODUCTION=<base64-encoded-profile>
IOS_PROVISIONING_PROFILE_NAME_STAGING=<profile-name>
IOS_PROVISIONING_PROFILE_NAME_PRODUCTION=<profile-name>
APP_STORE_CONNECT_API_KEY=<base64-encoded-p8>
APP_STORE_CONNECT_ISSUER_ID=<issuer-id>
APP_STORE_CONNECT_KEY_ID=<key-id>
```

### Step 5: Update Trust Policy for OIDC Role

Update your GitHub Actions IAM role trust policy to include the correct repository:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::019721216575:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:StanfordCS194/spr25-team-23:ref:refs/heads/main",
            "repo:StanfordCS194/spr25-team-23:ref:refs/heads/develop"
          ]
        }
      }
    }
  ]
}
```

## 🚀 Deployment Workflow

### Backend Deployment
1. **Push to `develop`**: Deploys to staging environment
2. **Push to `main`**: Deploys to production environment
3. **Smart Migration Process**:
   - Run tests with PostgreSQL container
   - Build Lambda package with esbuild
   - **Check for schema changes**: Only proceed with migrations if `schema.prisma` was modified
   - **If schema changed**: Start EC2 instance, run your exact migration workflow via SSM
   - **Migration steps**: `source /etc/profile` → `cd ~/cove` → `git pull` → `npm run prisma:dev` → `npm run prisma:migrate`
   - Deploy Lambda function (always runs)
   - Run smoke tests
   - Stop EC2 instance (only if it was started)

### iOS Deployment
1. **Push to `develop`**: Builds and uploads to TestFlight
2. **Push to `main`**: Builds and uploads to App Store (requires approval)
3. **Process**:
   - Run unit tests on iOS simulator
   - Install certificates and provisioning profiles
   - Build and archive app
   - Export IPA with proper signing
   - Upload to TestFlight/App Store
   - Create GitHub release (production only)

## 🔧 Customization Options

### Backend Customization
- **Lambda Function Name**: Update `hello-lambda` in `backend-deploy.yml`
- **API URL**: Update `https://api.coveapp.co` in smoke tests
- **Node Version**: Update `NODE_VERSION` environment variable
- **Test Database**: Modify PostgreSQL service configuration
- **Migration Naming**: Auto-generated as `{github-username}-{timestamp}` (e.g., `ashleydai2017-20241215-143022`)
- **EC2 Path**: Update `~/cove` path if your repository is in a different location

### iOS Customization
- **Xcode Version**: Update `XCODE_VERSION` environment variable
- **Scheme Name**: Update `IOS_SCHEME` if different
- **Build Number**: Auto-incremented for production builds
- **Export Method**: Currently set to `app-store`, can change to `ad-hoc` for testing

## 🐛 Troubleshooting

### Common Backend Issues
1. **SSM Connection Failed**: Verify EC2 instance has SSM agent and proper IAM role
2. **Migration Timeout**: Increase timeout in SSM command or optimize migrations
3. **Lambda Deployment Failed**: Check function name and permissions
4. **Build Failed**: Verify all dependencies in package.json
5. **Migration Not Running**: Check if `schema.prisma` was actually modified in the commit
6. **"cove directory not found"**: Verify the repository is cloned to `~/cove` on EC2 instance
7. **Migration Name Collision**: Auto-generated names include timestamp to avoid conflicts

### Common iOS Issues
1. **Code Signing Failed**: Verify certificates and provisioning profiles are valid
2. **Archive Failed**: Check scheme configuration and dependencies
3. **Upload Failed**: Verify App Store Connect API credentials
4. **Test Failed**: Ensure simulator is available and scheme is testable

### Monitoring and Logs
- **GitHub Actions**: Check workflow logs in Actions tab
- **AWS CloudWatch**: Monitor Lambda function logs
- **EC2 SSM**: Check command execution history in Systems Manager
- **App Store Connect**: Monitor build processing status

## 📊 Performance Optimizations

### Backend
- **Caching**: npm dependencies cached between runs
- **Parallel Jobs**: Tests and builds run in parallel
- **Cost Optimization**: EC2 instance auto-stopped after migrations
- **Artifact Management**: Build artifacts cleaned up after 7 days

### iOS
- **Caching**: Swift Package Manager dependencies cached
- **Conditional Builds**: Staging and production builds only on respective branches
- **Incremental Builds**: Build number auto-incremented for production
- **Parallel Testing**: Unit tests run on dedicated job

## 🔒 Security Best Practices

1. **Secrets Management**: All sensitive data stored in GitHub Secrets
2. **OIDC Authentication**: No long-lived AWS credentials
3. **Environment Protection**: Production deployments require approval
4. **Temporary Keychains**: iOS certificates stored in temporary keychains
5. **Least Privilege**: IAM roles have minimal required permissions
6. **Audit Trail**: All deployments logged and traceable

## 📈 Monitoring and Alerts

Consider setting up additional monitoring:
- **AWS CloudWatch Alerts**: Lambda errors, EC2 instance costs
- **GitHub Notifications**: Deployment status to Slack/Discord
- **App Store Connect**: Build processing notifications
- **Performance Monitoring**: API response times, error rates

## 🎯 Next Steps

1. **Add Tests**: Implement comprehensive test suites for both backend and iOS
2. **Database Seeding**: Add test data seeding for staging environments
3. **Feature Flags**: Implement feature toggles for gradual rollouts
4. **Rollback Strategy**: Add automated rollback capabilities
5. **Monitoring**: Set up comprehensive application monitoring
6. **Documentation**: Keep this guide updated as infrastructure evolves 