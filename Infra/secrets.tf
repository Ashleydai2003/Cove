# Infra/secrets.tf
# This file sets up the secrets manager and defines secrets for db credentials

# Key components:
# - Eventually firebase creds

# Using RDS's built-in Secrets Manager integration to manage the database password
# The password is stored securely and accessed by the Lambda function