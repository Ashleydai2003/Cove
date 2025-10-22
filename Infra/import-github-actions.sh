#!/bin/bash

#
# import-github-actions.sh
#
# Imports existing GitHub Actions IAM resources into Terraform state
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  GitHub Actions Terraform Import      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if we're in the Infra directory
if [ ! -f "github_actions.tf" ]; then
    echo -e "${RED}❌ Error: Must run from Infra/ directory${NC}"
    echo "  cd Infra/"
    echo "  ./import-github-actions.sh"
    exit 1
fi

# Check if Terraform is initialized
if [ ! -d ".terraform" ]; then
    echo -e "${YELLOW}⚠️  Terraform not initialized. Running terraform init...${NC}"
    terraform init
fi

echo -e "${YELLOW}📋 Step 1/5: Getting resource information...${NC}"
echo ""

# Get OIDC Provider ARN
echo "  🔍 Finding OIDC Provider..."
OIDC_ARN=$(aws iam list-open-id-connect-providers \
  --query 'OpenIDConnectProviderList[?contains(Arn, `token.actions.githubusercontent.com`)].Arn' \
  --output text 2>/dev/null || echo "")

if [ -z "$OIDC_ARN" ]; then
    echo -e "${RED}  ❌ OIDC Provider not found${NC}"
    echo "     Create it in AWS Console or skip if not using OIDC"
    SKIP_OIDC=true
else
    echo -e "${GREEN}  ✓ OIDC Provider: $OIDC_ARN${NC}"
    SKIP_OIDC=false
fi

# Get Policy ARN
echo "  🔍 Finding IAM Policy..."
POLICY_ARN=$(aws iam list-policies \
  --scope Local \
  --query 'Policies[?PolicyName==`GithubActionsPolicy`].Arn' \
  --output text 2>/dev/null || echo "")

if [ -z "$POLICY_ARN" ]; then
    echo -e "${RED}  ❌ GithubActionsPolicy not found${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ Policy: $POLICY_ARN${NC}"

# Check if role exists
echo "  🔍 Checking IAM Role..."
if aws iam get-role --role-name GithubActionsRole &> /dev/null; then
    echo -e "${GREEN}  ✓ Role: GithubActionsRole${NC}"
else
    echo -e "${RED}  ❌ GithubActionsRole not found${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}📥 Step 2/5: Importing OIDC Provider...${NC}"
if [ "$SKIP_OIDC" = true ]; then
    echo -e "${BLUE}  ℹ  Skipping OIDC provider (not found)${NC}"
else
    if terraform state show aws_iam_openid_connect_provider.github_actions &> /dev/null; then
        echo -e "${BLUE}  ℹ  Already imported, skipping...${NC}"
    else
        terraform import aws_iam_openid_connect_provider.github_actions "$OIDC_ARN"
        echo -e "${GREEN}  ✓ OIDC Provider imported${NC}"
    fi
fi

echo ""
echo -e "${YELLOW}📥 Step 3/5: Importing IAM Role...${NC}"
if terraform state show aws_iam_role.github_actions &> /dev/null; then
    echo -e "${BLUE}  ℹ  Already imported, skipping...${NC}"
else
    terraform import aws_iam_role.github_actions GithubActionsRole
    echo -e "${GREEN}  ✓ IAM Role imported${NC}"
fi

echo ""
echo -e "${YELLOW}📥 Step 4/5: Importing IAM Policy...${NC}"
if terraform state show aws_iam_policy.github_actions &> /dev/null; then
    echo -e "${BLUE}  ℹ  Already imported, skipping...${NC}"
else
    terraform import aws_iam_policy.github_actions "$POLICY_ARN"
    echo -e "${GREEN}  ✓ IAM Policy imported${NC}"
fi

echo ""
echo -e "${YELLOW}📥 Step 5/5: Importing Policy Attachment...${NC}"
if terraform state show aws_iam_role_policy_attachment.github_actions &> /dev/null; then
    echo -e "${BLUE}  ℹ  Already imported, skipping...${NC}"
else
    terraform import aws_iam_role_policy_attachment.github_actions "GithubActionsRole/$POLICY_ARN"
    echo -e "${GREEN}  ✓ Policy Attachment imported${NC}"
fi

echo ""
echo -e "${YELLOW}🔍 Checking for drift...${NC}"
echo ""

# Run terraform plan to check for differences
terraform plan -detailed-exitcode > /dev/null 2>&1
PLAN_EXIT=$?

if [ $PLAN_EXIT -eq 0 ]; then
    echo -e "${GREEN}✓ No drift detected! Infrastructure matches Terraform config.${NC}"
elif [ $PLAN_EXIT -eq 2 ]; then
    echo -e "${YELLOW}⚠️  Drift detected. Run 'terraform plan' to see differences.${NC}"
    echo ""
    echo "Common safe changes:"
    echo "  - Adding tags"
    echo "  - Updating descriptions"
    echo "  - JSON formatting"
    echo ""
    echo "Review carefully before applying!"
else
    echo -e "${RED}❌ Terraform plan failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     ✓ Import Complete! 🎉             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📋 Next Steps:${NC}"
echo "  1. Review changes: ${YELLOW}terraform plan${NC}"
echo "  2. Apply if safe:  ${YELLOW}terraform apply${NC}"
echo "  3. Update docs:    Mark IMPORT_GITHUB_ACTIONS.md as complete"
echo ""

echo -e "${BLUE}📊 Imported Resources:${NC}"
terraform state list | grep github_actions | sed 's/^/  - /'
echo ""

