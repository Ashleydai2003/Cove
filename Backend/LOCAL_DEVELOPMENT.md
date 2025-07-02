# Local Development Guide

## 🚀 Getting Started with Local Database

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- Node.js and npm installed
- Git repository cloned

### 1. Initial Setup

```bash
# Navigate to Backend directory
cd Backend

# Install dependencies (includes dotenv-cli for environment management)
npm install
```

## 🗄️ Local Database Setup

### 1. Start Local PostgreSQL Database

```bash
# Start PostgreSQL and pgAdmin in Docker containers
npm run db:start
```

This command:
- ✅ Starts PostgreSQL on `localhost:5432`
- ✅ Starts pgAdmin on `localhost:5050` (optional GUI)
- ✅ Creates database `team23_dev`
- ✅ Uses credentials: `postgres/postgres`

### 2. Verify Database is Running

```bash
# Check if containers are running
docker ps

# You should see:
# - team23-postgres (PostgreSQL)
# - team23-pgadmin (pgAdmin - optional)
```

### 3. Access Database GUI (Optional)

Visit [http://localhost:5050](http://localhost:5050) for pgAdmin:
- **Email**: `admin@admin.com`
- **Password**: `admin`

## 🔄 Migration Workflow

### Step 1: Reset Local Database (First Time Only)

```bash
# Reset database to clean state (removes any existing drift)
npm run prisma:reset
# Type 'y' when prompted to confirm
```

### Step 2: Make Schema Changes

Edit `prisma/schema.prisma` with your changes:
```prisma
model User {
  id    String @id @default(cuid())
  email String @unique
  name  String?
  // Add your new fields here
}
```

### Step 3: Create and Apply Migration

```bash
# Generate and apply migration to local database
npm run prisma:migrate:dev
# Enter a descriptive migration name when prompted
```

This command:
- ✅ Compares schema with local database
- ✅ Creates migration files in `prisma/migrations/`
- ✅ Applies migration to local database
- ✅ Regenerates Prisma Client

### Step 4: Test Your Changes

```bash
# Open Prisma Studio to view/edit data
npm run prisma:studio
# Opens at http://localhost:5555
```

### Step 5: Commit Changes

```bash
# Add migration files and schema changes
git add prisma/migrations/ prisma/schema.prisma

# Commit with descriptive message
git commit -m "Add user email field migration"

# Push to trigger production deployment
git push origin your-branch
```

## 📋 Available Commands

| Command | Purpose |
|---------|---------|
| `npm run db:start` | Start local PostgreSQL & pgAdmin |
| `npm run db:stop` | Stop local database containers |
| `npm run prisma:migrate:dev` | Create & apply migrations locally |
| `npm run prisma:reset` | Reset local database (clears all data) |
| `npm run prisma:studio` | Open database GUI |
| `npm run prisma:generate` | Generate Prisma Client only |

## 🔧 Database Configuration

### Local Development Environment
- **File**: `env.development`
- **Database URL**: `postgresql://postgres:postgres@localhost:5432/team23_dev`
- **Environment**: `NODE_ENV=development`

### Production Environment
- **Managed by**: AWS Secrets Manager (EC2 only)
- **Database**: Private RDS instance
- **Deployment**: Automatic via GitHub Actions

## 🚨 Troubleshooting

### Database Connection Issues

```bash
# Check if Docker is running
docker ps

# Restart database if needed
npm run db:stop
npm run db:start
```

### Migration Drift Errors

```bash
# Reset local database to clean state
npm run prisma:reset

# Then create your migration normally
npm run prisma:migrate:dev
```

### Port Conflicts

If port 5432 is already in use:
1. Stop other PostgreSQL instances
2. Or modify `docker-compose.yml` to use different port

### Clear Docker Data

```bash
# Remove all containers and volumes (nuclear option)
docker-compose down -v
docker system prune -a
```

## 🎯 Best Practices

### ✅ Do's
- Always run `npm run db:start` before working with database
- Test migrations locally before pushing
- Use descriptive migration names
- Commit migration files with schema changes
- Stop database when done: `npm run db:stop`

### ❌ Don'ts
- Don't run production commands locally
- Don't modify migration files after creation
- Don't skip testing migrations locally
- Don't push schema changes without migrations

## 🔄 Complete Development Workflow

```bash
# 1. Start development session
npm run db:start

# 2. Make schema changes in prisma/schema.prisma

# 3. Create migration
npm run prisma:migrate:dev
# Enter migration name: "add_user_profile_fields"

# 4. Test changes
npm run prisma:studio

# 5. Commit and push
git add prisma/
git commit -m "Add user profile fields"
git push origin feature-branch

# 6. End development session
npm run db:stop
```

## 🚀 Production Deployment

Production deployments happen automatically:

1. **Push schema changes** to `main`, `develop`, or `ci/test-deploy`
2. **GitHub Actions detects** changes to `Backend/prisma/schema.prisma`
3. **CI/CD pipeline**:
   - Starts EC2 instance
   - Runs `npm run prisma:migrate:deploy`
   - Stops EC2 instance
4. **Production database** gets updated with your migrations

## 📚 Additional Resources

- [Prisma Migrate Documentation](https://www.prisma.io/docs/concepts/components/prisma-migrate)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

**Need Help?** Check the troubleshooting section or ask the team! 