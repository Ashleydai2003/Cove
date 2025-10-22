# CI/CD Setup for Batch Matcher

## Quick Start

### 1. Initial Deployment (One-Time Setup)

Run the deployment script once to create all infrastructure:

```bash
./scripts/deploy-matcher.sh
```

This creates:
- ✅ Lambda function
- ✅ IAM role with Secrets Manager permissions
- ✅ Security groups
- ✅ Dead Letter Queue
- ✅ EventBridge schedule
- ✅ CloudWatch alarms

### 2. Enable Automated Deployments

The GitHub Actions workflow is already set up at `.github/workflows/deploy-batch-matcher.yml`.

It will **automatically deploy** when you push changes to:
- `Backend/src/workers/**` (matcher code)
- `Backend/prisma/schema.prisma` (database schema)
- `Backend/package.json` or `Backend/package-lock.json` (dependencies)

### 3. Required GitHub Secrets

Make sure these secrets are configured in your GitHub repository:

| Secret | Description | Already Set? |
|--------|-------------|--------------|
| `AWS_ROLE_ARN` | GitHub Actions OIDC role ARN | ✅ (from existing setup) |

**Note:** The matcher deployment uses the same AWS OIDC role as your main backend deployment.

## How It Works

### Automated Workflow

```
1. Developer pushes code changes
   ↓
2. GitHub Actions detects changes to matcher files
   ↓
3. Workflow runs:
   - Installs dependencies
   - Builds matcher Lambda package
   - Authenticates to AWS via OIDC
   - Updates Lambda function code
   - Tests invocation
   - Shows recent logs
   ↓
4. Deployment complete! ✅
```

### What Gets Deployed

The workflow **only updates the Lambda function code**. It does NOT:
- ❌ Modify IAM roles or permissions
- ❌ Change security groups
- ❌ Update EventBridge schedules
- ❌ Modify CloudWatch alarms

These infrastructure changes must be done via:
- Re-running `./scripts/deploy-matcher.sh` (for ad-hoc changes)
- Updating Terraform files in `Infra/` (for permanent changes)

## Deployment Triggers

### Automatic Triggers

The workflow runs automatically on `push` to `main` or `develop` when any of these files change:

```yaml
paths:
  - 'Backend/src/workers/**'          # Matcher code
  - 'Backend/src/prisma/**'           # Prisma client
  - 'Backend/package.json'            # Dependencies
  - 'Backend/package-lock.json'       # Dependency versions
  - 'Backend/prisma/schema.prisma'    # Database schema
  - '.github/workflows/deploy-batch-matcher.yml'  # Workflow itself
```

### Manual Trigger

You can also manually trigger a deployment from GitHub:

1. Go to **Actions** tab
2. Select **Deploy Batch Matcher** workflow
3. Click **Run workflow**
4. Select branch and click **Run workflow**

## Monitoring Deployments

### GitHub Actions

View deployment status in the **Actions** tab of your repository.

Each deployment shows:
- ✅ Build status
- ✅ Deployment status
- ✅ Test invocation results
- ✅ Recent Lambda logs

### AWS CloudWatch

Monitor the deployed Lambda:

```bash
# View recent logs
aws logs tail /aws/lambda/cove-batch-matcher --follow

# Check Lambda function info
aws lambda get-function --function-name cove-batch-matcher

# View metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=cove-batch-matcher \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum
```

## Troubleshooting

### Deployment Failed: "Lambda function not found"

**Cause:** You haven't run the initial setup script.

**Fix:**
```bash
./scripts/deploy-matcher.sh
```

### Deployment Failed: "Access Denied"

**Cause:** GitHub Actions doesn't have permission to update Lambda.

**Fix:** Verify the IAM role policy includes:
```json
{
  "Effect": "Allow",
  "Action": [
    "lambda:UpdateFunctionCode",
    "lambda:GetFunction",
    "lambda:InvokeFunction"
  ],
  "Resource": "arn:aws:lambda:us-west-1:*:function:cove-batch-matcher"
}
```

### Test Invocation Failed

**Cause:** Lambda function has errors or can't connect to database.

**Fix:**
1. Check CloudWatch Logs for errors
2. Verify Secrets Manager permissions
3. Verify VPC endpoint security group
4. Test locally: `npm run matcher:run`

## Cost Implications

CI/CD deployments are **essentially free**:

| Resource | Cost |
|----------|------|
| GitHub Actions | Free (2000 minutes/month included) |
| Lambda code updates | Free |
| Test invocations | ~$0.000001 per deployment |
| CloudWatch Logs | ~$0.01/month (minimal increase) |

**Total additional cost: ~$0.01/month** 💰

## Security

### OIDC Authentication

The workflow uses **OpenID Connect (OIDC)** to authenticate to AWS:

- ✅ No long-lived AWS credentials
- ✅ Temporary credentials valid only for the workflow run
- ✅ Scoped to specific repository and branches
- ✅ Automatically rotated

### Secrets Management

- ✅ Database password NOT in GitHub Secrets
- ✅ Database password retrieved from AWS Secrets Manager at runtime
- ✅ Only `AWS_ROLE_ARN` stored in GitHub Secrets
- ✅ No sensitive data in workflow logs

## Example Workflow Run

Here's what a successful deployment looks like:

```
✓ Checkout code
✓ Setup Node.js 18
✓ Install dependencies (25s)
✓ Build matcher Lambda package (12s)
✓ Configure AWS credentials
✓ Deploy Lambda function
  ✅ Lambda exists, updating code...
  ✅ Lambda code updated successfully!
✓ Test Lambda invocation
  🧪 Testing Lambda function...
  {"statusCode":200,"body":"{\"message\":\"Batch matching completed successfully!\"}"}
  ✅ Lambda test invocation successful!
✓ View recent logs
  📋 Fetching recent Lambda logs...
  2025-01-15T10:30:00 🚀 Batch matcher Lambda triggered
  2025-01-15T10:30:01 📍 Using production database configuration...
  2025-01-15T10:30:02 🔑 Retrieving database password from Secrets Manager...
  2025-01-15T10:30:03 ✅ Successfully retrieved database password
  2025-01-15T10:30:04 🔒 Attempting to acquire advisory lock...
  2025-01-15T10:30:05 ✅ Advisory lock acquired successfully
  2025-01-15T10:30:06 ✨ Batch matching completed successfully!
✓ Post-deployment summary

Total time: 1m 15s
```

## Next Steps

### After Initial Setup

1. **Test the workflow**:
   - Make a small change to `Backend/src/workers/batchMatcher.ts`
   - Commit and push to `develop` or `main`
   - Watch the workflow run in GitHub Actions

2. **Set up notifications** (optional):
   - Configure Slack/Discord webhook for deployment notifications
   - Add to `.github/workflows/deploy-batch-matcher.yml`

3. **Add to main backend workflow** (optional):
   - If you have a main backend deployment workflow, you can add the matcher deployment as a job

### Infrastructure Changes

If you need to modify infrastructure (IAM, security groups, EventBridge schedule):

**Option A: Script (Quick)**
```bash
./scripts/deploy-matcher.sh
```

**Option B: Terraform (Permanent)**
```bash
cd Infra/
terraform plan
terraform apply
```

## Summary

✅ **One-time setup**: Run `./scripts/deploy-matcher.sh` to create infrastructure  
✅ **Automated deployments**: Push code changes, GitHub Actions deploys automatically  
✅ **Zero additional cost**: Uses existing AWS OIDC role  
✅ **Secure**: No credentials stored in GitHub, uses Secrets Manager  
✅ **Monitored**: Test invocation and logs shown in workflow  

Your matcher Lambda is now part of your CI/CD pipeline! 🎉

