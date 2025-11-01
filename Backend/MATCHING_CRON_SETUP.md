# Batch Matcher Cron Job Setup

## Overview
The batch matcher runs every 3 hours to create matches between users with active intentions.

## Local Development

### Manual Run:
```bash
cd Backend
npm run matcher:run
```

### Test Run:
```bash
./scripts/run-batch-matcher.sh
```

---

## Production Setup (AWS)

### Option 1: AWS Lambda + EventBridge (Recommended)

#### 1. Create Lambda Function
```bash
# Build the worker
cd Backend
esbuild src/workers/batchMatcher.ts --bundle --platform=node --target=node18 --outfile=dist/batchMatcher.js --format=cjs

# Upload to Lambda
aws lambda create-function \
  --function-name cove-batch-matcher \
  --runtime nodejs18.x \
  --handler batchMatcher.runBatchMatcher \
  --zip-file fileb://dist/batchMatcher.zip \
  --role arn:aws:iam::YOUR_ACCOUNT:role/lambda-execution-role \
  --timeout 300 \
  --memory-size 512 \
  --environment Variables="{DATABASE_URL=$DATABASE_URL}"
```

#### 2. Create EventBridge Rule
```bash
# Create rule to trigger every 3 hours
aws events put-rule \
  --name cove-batch-matcher-schedule \
  --schedule-expression "rate(3 hours)" \
  --state ENABLED

# Add Lambda as target
aws events put-targets \
  --rule cove-batch-matcher-schedule \
  --targets "Id"="1","Arn"="arn:aws:lambda:REGION:ACCOUNT:function:cove-batch-matcher"
```

#### 3. Grant EventBridge Permission
```bash
aws lambda add-permission \
  --function-name cove-batch-matcher \
  --statement-id AllowEventBridgeInvoke \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:REGION:ACCOUNT:rule/cove-batch-matcher-schedule
```

---

### Option 2: EC2 Cron Job

#### 1. SSH into EC2 Instance
```bash
ssh -i your-key.pem ec2-user@your-instance.amazonaws.com
```

#### 2. Install Node.js and Dependencies
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 18
nvm use 18

cd /home/ec2-user/cove/Backend
npm install
```

#### 3. Create Cron Job
```bash
# Edit crontab
crontab -e

# Add this line (runs every 3 hours at :00)
0 */3 * * * cd /home/ec2-user/cove/Backend && /home/ec2-user/.nvm/versions/node/v18.*/bin/node /home/ec2-user/.nvm/versions/node/v18.*/bin/ts-node src/workers/batchMatcher.ts >> /var/log/batch-matcher.log 2>&1

# Or use the script
0 */3 * * * /home/ec2-user/cove/Backend/scripts/run-batch-matcher.sh >> /var/log/batch-matcher.log 2>&1
```

#### 4. Set Environment Variables
```bash
# Add to ~/.bashrc or create /etc/environment
export DATABASE_URL="postgresql://..."
export NODE_ENV="production"
```

---

### Option 3: Docker + Cron

#### 1. Create Dockerfile for Worker
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npx prisma generate

CMD ["node", "dist/batchMatcher.js"]
```

#### 2. Build and Run
```bash
docker build -t cove-batch-matcher -f Dockerfile.matcher .

# Add to docker-compose.yml
services:
  batch-matcher:
    image: cove-batch-matcher
    environment:
      DATABASE_URL: ${DATABASE_URL}
    restart: unless-stopped
    command: >
      sh -c "while true; do
        node dist/batchMatcher.js;
        sleep 10800;  # 3 hours
      done"
```

---

## Monitoring

### Check Logs (Lambda):
```bash
aws logs tail /aws/lambda/cove-batch-matcher --follow
```

### Check Logs (EC2):
```bash
tail -f /var/log/batch-matcher.log
```

### Check Logs (Docker):
```bash
docker logs -f cove-batch-matcher
```

---

## Metrics to Monitor

1. **Match Rate**: Number of matches created per batch
2. **Pool Size**: Active intentions by tier (0, 1, 2)
3. **Execution Time**: Should be < 5 minutes for 1000 users
4. **Error Rate**: Failed matching attempts
5. **Tier Distribution**: % of matches created at each tier

### Query Metrics:
```sql
-- Matches created in last 24h by tier
SELECT 
  tierUsed,
  COUNT(*) as match_count,
  AVG(score) as avg_score
FROM "Match"
WHERE "createdAt" > NOW() - INTERVAL '24 hours'
GROUP BY tierUsed;

-- Current pool distribution
SELECT 
  tier,
  COUNT(*) as user_count
FROM "PoolEntry"
GROUP BY tier;

-- Match acceptance rate
SELECT 
  COUNT(CASE WHEN status = 'accepted' THEN 1 END) * 100.0 / COUNT(*) as acceptance_rate
FROM "Match"
WHERE "createdAt" > NOW() - INTERVAL '7 days';
```

---

## Troubleshooting

### Worker Failing:
1. Check database connection
2. Verify Prisma client is generated
3. Check for schema mismatches
4. Review error logs

### No Matches Created:
1. Check if there are active pool entries
2. Verify hard filters aren't too strict
3. Check compatibility score thresholds
3. Review tier relaxation logic

### Performance Issues:
1. Add indexes on frequently queried fields
2. Limit candidate search to 200 per user
3. Use vector similarity indexes (ivfflat)
4. Consider batch size limits

---

## Cost Estimates

### AWS Lambda:
- **Invocations**: 8/day × 30 days = 240/month
- **Duration**: ~2 min avg × 240 = 480 min/month
- **Memory**: 512 MB
- **Cost**: ~$0.20/month (well within free tier)

### EC2 t2.micro:
- **Instance**: $8.50/month (on-demand)
- **Included in existing infrastructure**
- **Cost**: $0 additional

### Recommended: AWS Lambda + EventBridge
- Most cost-effective
- Scales automatically
- No server management
- Built-in logging

