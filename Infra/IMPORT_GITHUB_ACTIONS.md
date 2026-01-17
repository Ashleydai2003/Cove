# Importing Existing GitHub Actions IAM Resources into Terraform

This guide explains how to import the manually created GitHub Actions IAM resources into Terraform state.

## Why Import?

The GitHub Actions OIDC provider, IAM role, and policy were created manually via AWS Console or CLI. To manage them with Terraform going forward, we need to import them into Terraform state.

## Prerequisites

- Terraform initialized in `Infra/` directory
- AWS credentials configured
- Existing resources in AWS:
  - OIDC Provider: `token.actions.githubusercontent.com`
  - IAM Role: `GithubActionsRole`
  - IAM Policy: `GithubActionsPolicy`

## Import Commands

Run these commands from the `Infra/` directory:

### 1. Import OIDC Provider

```bash
# Get the OIDC provider ARN
OIDC_ARN=$(aws iam list-open-id-connect-providers \
  --query 'OpenIDConnectProviderList[?contains(Arn, `token.actions.githubusercontent.com`)].Arn' \
  --output text)

echo "OIDC Provider ARN: $OIDC_ARN"

# Import into Terraform
terraform import aws_iam_openid_connect_provider.github_actions "$OIDC_ARN"
```

### 2. Import IAM Role

```bash
terraform import aws_iam_role.github_actions GithubActionsRole
```

### 3. Import IAM Policy

```bash
# Get the policy ARN
POLICY_ARN=$(aws iam list-policies \
  --scope Local \
  --query 'Policies[?PolicyName==`GithubActionsPolicy`].Arn' \
  --output text)

echo "Policy ARN: $POLICY_ARN"

# Import into Terraform
terraform import aws_iam_policy.github_actions "$POLICY_ARN"
```

### 4. Import Policy Attachment

```bash
terraform import aws_iam_role_policy_attachment.github_actions GithubActionsRole/arn:aws:iam::019721216575:policy/GithubActionsPolicy
```

## Verify Import

After importing, verify the state:

```bash
# Check if resources are in state
terraform state list | grep github_actions

# Should show:
# aws_iam_openid_connect_provider.github_actions
# aws_iam_role.github_actions
# aws_iam_policy.github_actions
# aws_iam_role_policy_attachment.github_actions

# Check for any drift
terraform plan
```

## Expected Output

After successful import, `terraform plan` should show:

```
No changes. Your infrastructure matches the configuration.
```

Or minimal changes like:
- Tag additions
- Description updates
- Formatting differences

## Handling Drift

If `terraform plan` shows changes, review them:

### Safe to Apply
- Adding tags
- Updating descriptions
- Formatting JSON policies

### Review Carefully
- Permission changes
- Trust policy modifications
- Resource replacements

## Update Workflow

After importing:

1. **Run `terraform plan`** to see any drift
2. **Review changes** carefully
3. **Apply if safe**: `terraform apply`
4. **Update CI-CD-SETUP.md** to mention Terraform management

## Rollback

If import causes issues, remove from state:

```bash
terraform state rm aws_iam_openid_connect_provider.github_actions
terraform state rm aws_iam_role.github_actions
terraform state rm aws_iam_policy.github_actions
terraform state rm aws_iam_role_policy_attachment.github_actions
```

Then manage manually again.

## Future Changes

After import, all changes should go through Terraform:

```bash
# Modify Infra/github_actions.tf
vim Infra/github_actions.tf

# Plan changes
terraform plan

# Apply changes
terraform apply
```

## Important Notes

1. **OIDC Provider Thumbprints**: The thumbprints in the Terraform config are GitHub's current ones. They may need updating if GitHub rotates certificates.

2. **Repository Path**: The trust policy is scoped to `StanfordCS194/spr25-team-23`. Update if repository changes.

3. **Branch Restrictions**: Currently allows `main` and `develop` branches. Add more branches as needed.

4. **EC2 Instance ID**: The policy references the migration EC2 instance. This is dynamically fetched from `aws_instance.migration_instance.id`.

5. **Lambda ARNs**: The policy references both `hello-lambda` and `cove-batch-matcher` dynamically.

## Documentation

After successful import, update:
- `CI-CD-SETUP.md` - Note Terraform management
- `README.md` - Add Terraform import to setup steps
- This file - Mark as completed

## Status

- [ ] OIDC Provider imported
- [ ] IAM Role imported
- [ ] IAM Policy imported
- [ ] Policy Attachment imported
- [ ] `terraform plan` shows no changes or only safe changes
- [ ] Documentation updated

