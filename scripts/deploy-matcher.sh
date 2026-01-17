#!/bin/bash
#
# deploy-matcher.sh
#
# Easy one-command deployment for batch matcher Lambda
# Run from project root: ./scripts/deploy-matcher.sh
#

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════╗"
echo "║  Cove Batch Matcher Deployment v1.0   ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

# Check if we're in the right directory
if [ ! -d "Backend" ] || [ ! -d "scripts" ]; then
    echo -e "${RED}❌ Error: Must run from project root${NC}"
    echo "Usage: ./scripts/deploy-matcher.sh"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not found. Please install it first.${NC}"
    echo "Install: https://aws.amazon.com/cli/"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured${NC}"
    echo "Run: aws configure"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region || echo "us-west-1")

echo -e "${GREEN}✓ AWS Account: $ACCOUNT_ID${NC}"
echo -e "${GREEN}✓ Region: $REGION${NC}"
echo ""

# ==========================================
# STEP 1: Build Lambda Package
# ==========================================
echo -e "${YELLOW}📦 Step 1/7: Building Lambda package...${NC}"
cd Backend

npm run build:matcher 2>&1 | grep -v "^npm WARN"

if [ ! -f "dist/matcher.zip" ]; then
    echo -e "${RED}❌ Build failed - dist/matcher.zip not found${NC}"
    exit 1
fi

SIZE=$(du -h dist/matcher.zip | cut -f1)
echo -e "${GREEN}✓ Built matcher.zip ($SIZE)${NC}"
echo ""

cd ..

# ==========================================
# STEP 2: Gather AWS Resource IDs
# ==========================================
echo -e "${YELLOW}🔍 Step 2/7: Gathering AWS resource IDs...${NC}"

# Get VPC ID
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=main_vpc" \
    --query 'Vpcs[0].VpcId' \
    --output text 2>/dev/null || echo "")

if [ "$VPC_ID" == "None" ] || [ -z "$VPC_ID" ]; then
    echo -e "${RED}❌ VPC 'main_vpc' not found${NC}"
    echo "Please check your VPC name in AWS Console"
    exit 1
fi
echo -e "${GREEN}✓ VPC: $VPC_ID${NC}"

# Get Private Subnets
SUBNET_1=$(aws ec2 describe-subnets \
    --filters "Name=tag:Name,Values=private_subnet_1" \
    --query 'Subnets[0].SubnetId' \
    --output text 2>/dev/null || echo "")

SUBNET_2=$(aws ec2 describe-subnets \
    --filters "Name=tag:Name,Values=private_subnet_2" \
    --query 'Subnets[0].SubnetId' \
    --output text 2>/dev/null || echo "")

if [ "$SUBNET_1" == "None" ] || [ -z "$SUBNET_1" ] || [ "$SUBNET_2" == "None" ] || [ -z "$SUBNET_2" ]; then
    echo -e "${RED}❌ Private subnets not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Subnets: $SUBNET_1, $SUBNET_2${NC}"

# Get RDS Security Group
RDS_SG_ID=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=rds_sg" "Name=vpc-id,Values=$VPC_ID" \
    --query 'SecurityGroups[0].GroupId' \
    --output text 2>/dev/null || echo "")

if [ "$RDS_SG_ID" == "None" ] || [ -z "$RDS_SG_ID" ]; then
    echo -e "${RED}❌ RDS security group 'rds_sg' not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ RDS SG: $RDS_SG_ID${NC}"

# Get RDS Endpoint
RDS_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier my-postgres-db \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text 2>/dev/null || echo "")

if [ "$RDS_ENDPOINT" == "None" ] || [ -z "$RDS_ENDPOINT" ]; then
    echo -e "${RED}❌ RDS instance 'my-postgres-db' not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ RDS Endpoint: $RDS_ENDPOINT${NC}"

# Get RDS Secret ARN
RDS_SECRET_ARN=$(aws rds describe-db-instances \
    --db-instance-identifier my-postgres-db \
    --query 'DBInstances[0].MasterUserSecret.SecretArn' \
    --output text 2>/dev/null || echo "")

if [ "$RDS_SECRET_ARN" == "None" ] || [ -z "$RDS_SECRET_ARN" ]; then
    echo -e "${RED}❌ RDS Secret ARN not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ RDS Secret ARN: $RDS_SECRET_ARN${NC}"

# Get database username
DB_USER=$(aws rds describe-db-instances \
    --db-instance-identifier my-postgres-db \
    --query 'DBInstances[0].MasterUsername' \
    --output text 2>/dev/null || echo "")

if [ "$DB_USER" == "None" ] || [ -z "$DB_USER" ]; then
    echo -e "${RED}❌ Database username not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ DB Username: $DB_USER${NC}"
echo ""

# ==========================================
# STEP 3: Create IAM Role
# ==========================================
echo -e "${YELLOW}👤 Step 3/7: Creating IAM role...${NC}"

ROLE_NAME="cove-batch-matcher-lambda-role"

# Check if role exists
if aws iam get-role --role-name $ROLE_NAME &> /dev/null; then
    echo -e "${BLUE}ℹ  Role already exists, skipping...${NC}"
    ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)
else
    # Create role
    aws iam create-role \
        --role-name $ROLE_NAME \
        --assume-role-policy-document '{
            "Version": "2012-10-17",
            "Statement": [{
                "Effect": "Allow",
                "Principal": {"Service": "lambda.amazonaws.com"},
                "Action": "sts:AssumeRole"
            }]
        }' \
        --tags Key=Project,Value=CoveApp Key=Environment,Value=production \
        > /dev/null

    ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)
    
    # Attach policies
    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole

    echo -e "${GREEN}✓ IAM role created${NC}"
    
    # Wait for role to propagate
    echo "  Waiting for role to propagate..."
    sleep 10
fi
echo ""

# ==========================================
# STEP 4: Create Dead Letter Queue
# ==========================================
echo -e "${YELLOW}📬 Step 4/7: Creating Dead Letter Queue...${NC}"

DLQ_NAME="cove-batch-matcher-dlq"

# Check if queue exists
DLQ_URL=$(aws sqs get-queue-url --queue-name $DLQ_NAME --query 'QueueUrl' --output text 2>/dev/null || echo "")

if [ -z "$DLQ_URL" ]; then
    # Create queue
    DLQ_URL=$(aws sqs create-queue \
        --queue-name $DLQ_NAME \
        --attributes '{
            "MessageRetentionPeriod": "1209600",
            "SqsManagedSseEnabled": "true"
        }' \
        --tags Project=CoveApp,Environment=production \
        --query 'QueueUrl' \
        --output text)
    
    echo -e "${GREEN}✓ DLQ created${NC}"
else
    echo -e "${BLUE}ℹ  DLQ already exists${NC}"
fi

DLQ_ARN=$(aws sqs get-queue-attributes \
    --queue-url $DLQ_URL \
    --attribute-names QueueArn \
    --query 'Attributes.QueueArn' \
    --output text)

# Add DLQ permission to role
aws iam put-role-policy \
    --role-name $ROLE_NAME \
    --policy-name DLQAccess \
    --policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": "sqs:SendMessage",
            "Resource": "'$DLQ_ARN'"
        }]
    }' 2>/dev/null || true

# Add X-Ray permission
aws iam put-role-policy \
    --role-name $ROLE_NAME \
    --policy-name XRayAccess \
    --policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": [
                "xray:PutTraceSegments",
                "xray:PutTelemetryRecords"
            ],
            "Resource": "*"
        }]
    }' 2>/dev/null || true

# Add Secrets Manager permission for RDS credentials
aws iam put-role-policy \
    --role-name $ROLE_NAME \
    --policy-name SecretsManagerAccess \
    --policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "'$RDS_SECRET_ARN'"
        }]
    }' 2>/dev/null || true

echo ""

# ==========================================
# STEP 5: Create Security Group
# ==========================================
echo -e "${YELLOW}🔒 Step 5/7: Setting up security group...${NC}"

SG_NAME="cove-lambda-matcher-sg"

# Check if security group exists
MATCHER_SG_ID=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=$SG_NAME" "Name=vpc-id,Values=$VPC_ID" \
    --query 'SecurityGroups[0].GroupId' \
    --output text 2>/dev/null || echo "")

if [ "$MATCHER_SG_ID" == "None" ] || [ -z "$MATCHER_SG_ID" ]; then
    # Create security group
    MATCHER_SG_ID=$(aws ec2 create-security-group \
        --group-name $SG_NAME \
        --description "Security group for batch matcher Lambda" \
        --vpc-id $VPC_ID \
        --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value='$SG_NAME'},{Key=Project,Value=CoveApp}]' \
        --query 'GroupId' \
        --output text)
    
    # Remove default egress rule
    aws ec2 revoke-security-group-egress \
        --group-id $MATCHER_SG_ID \
        --ip-permissions '[{"IpProtocol": "-1", "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]' \
        2>/dev/null || true
    
    # Add PostgreSQL egress to RDS
    aws ec2 authorize-security-group-egress \
        --group-id $MATCHER_SG_ID \
        --ip-permissions '[{
            "IpProtocol": "tcp",
            "FromPort": 5432,
            "ToPort": 5432,
            "UserIdGroupPairs": [{"GroupId": "'$RDS_SG_ID'"}]
        }]'
    
    # Add HTTPS egress
    aws ec2 authorize-security-group-egress \
        --group-id $MATCHER_SG_ID \
        --ip-permissions '[{
            "IpProtocol": "tcp",
            "FromPort": 443,
            "ToPort": 443,
            "IpRanges": [{"CidrIp": "0.0.0.0/0"}]
        }]'
    
    # Update RDS security group to allow matcher Lambda
    aws ec2 authorize-security-group-ingress \
        --group-id $RDS_SG_ID \
        --ip-permissions '[{
            "IpProtocol": "tcp",
            "FromPort": 5432,
            "ToPort": 5432,
            "UserIdGroupPairs": [{"GroupId": "'$MATCHER_SG_ID'", "Description": "Batch matcher Lambda"}]
        }]' 2>/dev/null || echo "  (RDS ingress rule may already exist)"
    
    # Update VPC Endpoint security group to allow matcher Lambda access to Secrets Manager
    VPCE_SG_ID=$(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=vpce-sg" "Name=vpc-id,Values=$VPC_ID" \
        --query 'SecurityGroups[0].GroupId' \
        --output text 2>/dev/null || echo "")
    
    if [ "$VPCE_SG_ID" != "None" ] && [ -n "$VPCE_SG_ID" ]; then
        aws ec2 authorize-security-group-ingress \
            --group-id $VPCE_SG_ID \
            --ip-permissions '[{
                "IpProtocol": "tcp",
                "FromPort": 443,
                "ToPort": 443,
                "UserIdGroupPairs": [{"GroupId": "'$MATCHER_SG_ID'", "Description": "Batch matcher Lambda - Secrets Manager access"}]
            }]' 2>/dev/null || echo "  (VPC endpoint ingress rule may already exist)"
    fi
    
    echo -e "${GREEN}✓ Security group created: $MATCHER_SG_ID${NC}"
else
    echo -e "${BLUE}ℹ  Security group already exists: $MATCHER_SG_ID${NC}"
fi
echo ""

# ==========================================
# STEP 6: Create/Update Lambda Function
# ==========================================
echo -e "${YELLOW}⚡ Step 6/7: Deploying Lambda function...${NC}"

LAMBDA_NAME="cove-batch-matcher"

# Check if Lambda exists
if aws lambda get-function --function-name $LAMBDA_NAME &> /dev/null; then
    echo -e "${BLUE}ℹ  Lambda exists, updating code...${NC}"
    
    aws lambda update-function-code \
        --function-name $LAMBDA_NAME \
        --zip-file fileb://Backend/dist/matcher.zip \
        > /dev/null
    
    # Wait for update
    aws lambda wait function-updated --function-name $LAMBDA_NAME
    
    # Update configuration (AWS_REGION is automatically set by Lambda, don't include it)
    aws lambda update-function-configuration \
        --function-name $LAMBDA_NAME \
        --environment "Variables={NODE_ENV=production,RDS_MASTER_SECRET_ARN=$RDS_SECRET_ARN,DB_USER=$DB_USER,DB_HOST=$RDS_ENDPOINT,DB_NAME=covedb}" \
        > /dev/null
    
    echo -e "${GREEN}✓ Lambda updated${NC}"
else
    echo -e "${BLUE}ℹ  Creating new Lambda function...${NC}"
    
    # AWS_REGION is automatically set by Lambda runtime, don't include it
    aws lambda create-function \
        --function-name $LAMBDA_NAME \
        --runtime nodejs18.x \
        --role $ROLE_ARN \
        --handler matcherLambda.handler \
        --zip-file fileb://Backend/dist/matcher.zip \
        --timeout 300 \
        --memory-size 1024 \
        --environment "Variables={NODE_ENV=production,RDS_MASTER_SECRET_ARN=$RDS_SECRET_ARN,DB_USER=$DB_USER,DB_HOST=$RDS_ENDPOINT,DB_NAME=covedb}" \
        --vpc-config "SubnetIds=$SUBNET_1,$SUBNET_2,SecurityGroupIds=$MATCHER_SG_ID" \
        --dead-letter-config "TargetArn=$DLQ_ARN" \
        --tracing-config "Mode=Active" \
        --tags "Project=CoveApp,Environment=production,ManagedBy=Script" \
        > /dev/null
    
    # Set reserved concurrency separately (AWS CLI quirk)
    aws lambda put-function-concurrency \
        --function-name $LAMBDA_NAME \
        --reserved-concurrent-executions 1 \
        > /dev/null
    
    echo -e "${GREEN}✓ Lambda created${NC}"
fi

LAMBDA_ARN=$(aws lambda get-function --function-name $LAMBDA_NAME --query 'Configuration.FunctionArn' --output text)
echo ""

# ==========================================
# STEP 7: Create EventBridge Schedule
# ==========================================
echo -e "${YELLOW}⏰ Step 7/7: Setting up EventBridge schedule...${NC}"

RULE_NAME="cove-batch-matcher-schedule"

# Check if rule exists
if aws events describe-rule --name $RULE_NAME &> /dev/null; then
    echo -e "${BLUE}ℹ  EventBridge rule exists${NC}"
else
    # Create rule
    aws events put-rule \
        --name $RULE_NAME \
        --description "Trigger batch matcher Lambda every 3 hours" \
        --schedule-expression "rate(3 hours)" \
        --state ENABLED \
        > /dev/null
    
    RULE_ARN=$(aws events describe-rule --name $RULE_NAME --query 'Arn' --output text)
    
    # Add Lambda as target
    aws events put-targets \
        --rule $RULE_NAME \
        --targets '[{
            "Id": "1",
            "Arn": "'$LAMBDA_ARN'",
            "Input": "{\"trigger\":\"eventbridge\"}"
        }]' \
        > /dev/null
    
    # Grant EventBridge permission to invoke Lambda
    aws lambda add-permission \
        --function-name $LAMBDA_NAME \
        --statement-id AllowEventBridgeInvoke \
        --action lambda:InvokeFunction \
        --principal events.amazonaws.com \
        --source-arn $RULE_ARN \
        2>/dev/null || true
    
    echo -e "${GREEN}✓ EventBridge schedule created (every 3 hours)${NC}"
fi
echo ""

# ==========================================
# Success!
# ==========================================
echo -e "${GREEN}"
echo "╔════════════════════════════════════════╗"
echo "║     ✓ Deployment Successful! 🎉       ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}📊 Deployment Summary:${NC}"
echo "  • Lambda: $LAMBDA_NAME"
echo "  • Schedule: Every 3 hours"
echo "  • Timeout: 5 minutes"
echo "  • Memory: 1024 MB"
echo "  • Concurrency: 1 (no overlaps)"
echo ""

echo -e "${YELLOW}🧪 Test the matcher:${NC}"
echo "  aws lambda invoke \\"
echo "    --function-name $LAMBDA_NAME \\"
echo "    --payload '{\"trigger\":\"manual\"}' \\"
echo "    response.json && cat response.json"
echo ""

echo -e "${YELLOW}📋 View logs:${NC}"
echo "  aws logs tail /aws/lambda/$LAMBDA_NAME --follow"
echo ""

echo -e "${YELLOW}📈 Monitoring:${NC}"
echo "  • CloudWatch Logs: /aws/lambda/$LAMBDA_NAME"
echo "  • Dead Letter Queue: $DLQ_NAME"
echo "  • EventBridge Rule: $RULE_NAME"
echo ""

echo -e "${YELLOW}🔄 Update later:${NC}"
echo "  Just run this script again!"
echo ""

echo -e "${GREEN}Done! The matcher will run automatically every 3 hours. 🚀${NC}"

