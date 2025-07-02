# Migration Workflow

## 🏗️ Local Development Setup

### 1. Start Local Database
```bash
npm run db:start  # Starts PostgreSQL in Docker
```

### 2. Create Migrations Locally
```bash
npm run prisma:migrate:dev
```
- This connects to your local PostgreSQL database
- Creates migration files in `prisma/migrations/`
- Applies migrations to local DB
- Prompts for migration name

### 3. View Database (Optional)
```bash
npm run prisma:studio  # Opens Prisma Studio
```

### 4. Stop Database When Done
```bash
npm run db:stop
```

## 🚀 Production Deployment

Production migrations are handled automatically by GitHub Actions:

1. **Push schema changes** to `main`, `develop`, or `ci/test-deploy`
2. **CI/CD detects changes** to `Backend/prisma/schema.prisma`
3. **Migrations deploy automatically** using `prisma migrate deploy`

## 📋 Development Workflow

1. **Make schema changes** in `prisma/schema.prisma`
2. **Run locally**: `npm run prisma:migrate:dev`
3. **Test your changes** with the local database
4. **Commit migration files** and schema changes
5. **Push to GitHub** - production deployment happens automatically

## 🔄 Key Commands

| Command | Purpose |
|---------|---------|
| `npm run db:start` | Start local PostgreSQL |
| `npm run prisma:migrate:dev` | Create & apply migrations locally |
| `npm run prisma:studio` | Open database GUI |
| `npm run prisma:generate` | Generate Prisma client |
| `npm run db:stop` | Stop local database |

## 🗄️ Database URLs

- **Local**: `postgresql://postgres:postgres@localhost:5432/team23_dev`
- **Production**: Retrieved from AWS Secrets Manager (EC2 only)

## ⚠️ Important Notes

- **Local development** uses Docker PostgreSQL (no AWS secrets needed)
- **Production deployment** runs on EC2 with access to private RDS
- **Migration files** should be committed to Git
- **Never run `migrate dev` in production** (CI/CD uses `migrate deploy`) 