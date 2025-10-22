# Batch Matcher Deployment

## Quick Start (Easiest Way)

### One-Command Deployment:

```bash
./scripts/deploy-matcher.sh
```

That's it! The script will:
- ✅ Build the Lambda package
- ✅ Create IAM roles and permissions
- ✅ Set up security groups
- ✅ Create Dead Letter Queue
- ✅ Deploy Lambda function
- ✅ Configure EventBridge (every 3 hours)
- ✅ Set up monitoring and alarms

### What You'll Need:

1. **AWS CLI** configured (`aws configure`)
2. **Existing infrastructure** (VPC, RDS, Secrets Manager from Terraform)
3. **5 minutes** ⏱️

**Note:** No password prompt! The script automatically retrieves RDS credentials from AWS Secrets Manager.

### After Deployment:

**Test it:**
```bash
aws lambda invoke \
  --function-name cove-batch-matcher \
  --payload '{"trigger":"manual"}' \
  response.json && cat response.json
```

**View logs:**
```bash
aws logs tail /aws/lambda/cove-batch-matcher --follow
```

**Update later:**
```bash
# Make code changes, then just run the script again
./scripts/deploy-matcher.sh
```

---

## Manual Deployment (If You Prefer)

See [MANUAL_DEPLOYMENT_GUIDE.md](./MANUAL_DEPLOYMENT_GUIDE.md) for step-by-step AWS CLI commands.

---

## How It Works

```
EventBridge (every 3 hours)
    ↓
Lambda Function
    ↓
PostgreSQL Advisory Lock (prevents concurrent runs)
    ↓
Find Users in Pool (tiers 0→1→2)
    ↓
Calculate Compatibility Scores
    ↓
Create Matches (greedy pairing)
    ↓
Update Database
    ↓
Release Lock
    ↓
iOS App Polls → Users See Matches! 🎉
```

---

## Architecture

### Security:
- 🔒 Lambda in **private subnets** (no public IP)
- 🔒 **Zero hardcoded credentials** - passwords from Secrets Manager
- 🔒 VPC endpoints for **private AWS service access**
- 🔒 Security groups limit access to **RDS and VPC endpoints only**
- 🔒 **Advisory locks** prevent concurrent runs
- 🔒 IAM **least-privilege permissions**

### Reliability:
- ⚡ **Reserved concurrency: 1** (only one instance runs)
- ⚡ **Dead Letter Queue** captures failures
- ⚡ **CloudWatch alarms** for monitoring
- ⚡ **X-Ray tracing** for debugging

### Cost:
- 💰 ~**$0.60/month** total
- 💰 Lambda: $0.10 (well within free tier)
- 💰 CloudWatch: $0.50

---

## Security Deep Dive

### How Credentials Are Managed

**Problem:** Lambda functions in VPC can't access the internet to retrieve secrets.

**Solution:** VPC Endpoints for private AWS service access.

```
┌──────────────────────────────────────────────────────────────┐
│  Lambda Initialization (Cold Start)                          │
│  ────────────────────────────────────────────────────────── │
│  1. Read environment variables:                              │
│     - RDS_MASTER_SECRET_ARN = "arn:aws:secretsmanager:..."  │
│     - DB_USER = "mydbuser"                                   │
│     - DB_HOST = "my-postgres-db.xxx.rds.amazonaws.com"      │
│     - DB_NAME = "covedb"                                     │
│                                                               │
│  2. Call AWS Secrets Manager SDK:                            │
│     const secretsManager = new SecretsManagerClient();       │
│     const secret = await secretsManager.send(                │
│       new GetSecretValueCommand({                            │
│         SecretId: process.env.RDS_MASTER_SECRET_ARN          │
│       })                                                      │
│     );                                                        │
│                                                               │
│  3. Parse password from secret:                              │
│     const { password } = JSON.parse(secret.SecretString);    │
│                                                               │
│  4. Construct DATABASE_URL dynamically:                      │
│     const databaseUrl = `postgresql://${DB_USER}:${password} │
│       @${DB_HOST}:5432/${DB_NAME}?schema=public&sslmode=...` │
│                                                               │
│  5. Initialize Prisma with dynamic URL:                      │
│     process.env.DATABASE_URL = databaseUrl;                  │
│     const prisma = new PrismaClient();                       │
└──────────────────────────────────────────────────────────────┘
```

### Network Security

**All traffic stays within your VPC:**

```
┌─────────────────────────────────────────────────────────────┐
│  VPC (10.0.0.0/16)                                           │
│                                                               │
│  ┌─────────────────┐                  ┌──────────────────┐  │
│  │ Private Subnet  │                  │ Private Subnet   │  │
│  │ 10.0.1.0/24     │                  │ 10.0.2.0/24      │  │
│  │                 │                  │                  │  │
│  │  ┌───────────┐  │                  │  ┌────────────┐ │  │
│  │  │  Lambda   │──┼──────────────────┼─→│    RDS     │ │  │
│  │  │  Matcher  │  │   PostgreSQL     │  │ PostgreSQL │ │  │
│  │  └─────┬─────┘  │   (port 5432)    │  └────────────┘ │  │
│  │        │        │                  │                  │  │
│  └────────┼────────┘                  └──────────────────┘  │
│           │                                                  │
│           │ HTTPS (port 443)                                │
│           ↓                                                  │
│  ┌─────────────────────────────────┐                        │
│  │  VPC Endpoint (Interface)       │                        │
│  │  secretsmanager.us-west-1.      │                        │
│  │  amazonaws.com                  │                        │
│  │  (Private IP in VPC)            │                        │
│  └─────────────────────────────────┘                        │
│           │                                                  │
└───────────┼──────────────────────────────────────────────────┘
            │
            │ (AWS Private Network - never touches internet)
            ↓
   ┌────────────────────┐
   │  AWS Secrets       │
   │  Manager           │
   │  (Managed Service) │
   └────────────────────┘
```

### IAM Permissions (Least Privilege)

The Lambda role has **ONLY** these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:us-west-1:ACCOUNT:secret:rds!db-XXXXX"
    },
    {
      "Effect": "Allow",
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:us-west-1:ACCOUNT:cove-batch-matcher-dlq"
    },
    {
      "Effect": "Allow",
      "Action": ["xray:PutTraceSegments", "xray:PutTelemetryRecords"],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["logs:CreateLogStream", "logs:PutLogEvents"],
      "Resource": "arn:aws:logs:us-west-1:ACCOUNT:log-group:/aws/lambda/cove-batch-matcher:*"
    }
  ]
}
```

**What the Lambda CAN'T do:**
- ❌ Access other secrets
- ❌ Modify IAM roles
- ❌ Access S3 buckets
- ❌ Call other Lambda functions
- ❌ Access the internet

### Security Groups

**Lambda Security Group** (`cove-lambda-matcher-sg`):
```
Inbound:  NONE (Lambda initiates all connections)
Outbound:
  - Port 5432 → RDS Security Group (database access)
  - Port 443  → VPC Endpoint Security Group (Secrets Manager)
```

**VPC Endpoint Security Group** (`vpce-sg`):
```
Inbound:
  - Port 443 ← Lambda Matcher SG (allow Secrets Manager API calls)
  - Port 443 ← Main Lambda SG (for API Lambda)
  - Port 443 ← Migration SG (for EC2 migrations)
Outbound:
  - All (to AWS services)
```

**RDS Security Group** (`rds-sg`):
```
Inbound:
  - Port 5432 ← Lambda Matcher SG
  - Port 5432 ← Main Lambda SG
  - Port 5432 ← Migration SG
Outbound:
  - All
```

### Why This Matters

**Before (Insecure):**
- ❌ Database password in environment variables
- ❌ Password visible in AWS Console, CloudFormation, logs
- ❌ Password rotation requires Lambda redeployment
- ❌ Anyone with Lambda read access sees password

**After (Secure):**
- ✅ Password never leaves Secrets Manager
- ✅ Retrieved dynamically at runtime
- ✅ Automatic password rotation supported
- ✅ Secrets Manager audit logs track all access
- ✅ IAM controls who can read secrets

---

## Monitoring

### CloudWatch Logs:
```bash
# Stream logs in real-time
aws logs tail /aws/lambda/cove-batch-matcher --follow

# View in AWS Console
# CloudWatch → Log Groups → /aws/lambda/cove-batch-matcher
```

### Dead Letter Queue:
```bash
# Check for failures
aws sqs get-queue-attributes \
  --queue-url https://sqs.us-west-1.amazonaws.com/YOUR_ACCOUNT_ID/cove-batch-matcher-dlq \
  --attribute-names ApproximateNumberOfMessages
```

### Metrics Dashboard:
- Go to: **CloudWatch** → **Metrics** → **Lambda** → `cove-batch-matcher`
- Watch: Invocations, Duration, Errors, Throttles

---

## Common Tasks

### Change Schedule:

```bash
# Every 2 hours
aws events put-rule \
  --name cove-batch-matcher-schedule \
  --schedule-expression "rate(2 hours)"

# Every 6 hours
aws events put-rule \
  --name cove-batch-matcher-schedule \
  --schedule-expression "rate(6 hours)"

# Daily at 9 AM UTC
aws events put-rule \
  --name cove-batch-matcher-schedule \
  --schedule-expression "cron(0 9 * * ? *)"
```

### Pause Matching:

```bash
# Disable the schedule
aws events disable-rule --name cove-batch-matcher-schedule

# Re-enable
aws events enable-rule --name cove-batch-matcher-schedule
```

### Update Code:

```bash
# Just run the deployment script again
./scripts/deploy-matcher.sh
```

---

## Troubleshooting

### Lambda Timing Out?

```bash
aws lambda update-function-configuration \
  --function-name cove-batch-matcher \
  --timeout 600  # 10 minutes
```

### Out of Memory?

```bash
aws lambda update-function-configuration \
  --function-name cove-batch-matcher \
  --memory-size 2048  # 2 GB
```

### Can't Connect to Database?

1. Check security group rules
2. Verify Lambda is in correct subnets
3. Test database connection:
   ```bash
   # SSH into EC2 in same VPC, then:
   psql $DATABASE_URL
   ```

### Advisory Lock Stuck?

```sql
-- Connect to database
psql $DATABASE_URL

-- Check locks
SELECT * FROM pg_locks WHERE locktype = 'advisory';

-- Force unlock (use with caution!)
SELECT pg_advisory_unlock_all();
```

---

## Files

- **`deploy-matcher.sh`** - One-command deployment script
- **`MANUAL_DEPLOYMENT_GUIDE.md`** - Detailed step-by-step guide
- **`src/workers/batchMatcher.ts`** - Core matching algorithm
- **`src/workers/matcherLambda.ts`** - Lambda handler
- **`Infra/*.tf`** - Terraform docs (for reference only)

---

## Support

1. Check **CloudWatch Logs** first
2. Look at **DLQ** for failures
3. Review **X-Ray traces** for performance
4. Check **database** for pool entries/matches

Questions? See `MANUAL_DEPLOYMENT_GUIDE.md` for detailed docs.

---

## What Happens When You Deploy?

1. **Build**: Creates `dist/matcher.zip` with Lambda code
2. **IAM**: Creates role with least-privilege permissions
3. **Security**: Creates security group (RDS + HTTPS only)
4. **DLQ**: Creates queue for failed invocations
5. **Lambda**: Deploys function to private subnets
6. **EventBridge**: Schedules runs every 3 hours
7. **Test**: Verifies everything works

All **secure**, **monitored**, and **production-ready**! 🚀

