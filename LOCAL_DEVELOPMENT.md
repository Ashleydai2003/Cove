# 🚀 Cove Local Development Guide

## Quick Start

1. **Install prerequisites:**
   - [Docker Desktop](https://www.docker.com/products/docker-desktop) (running)
   - Node.js & npm
   - Git

2. **Clone & install dependencies:**
   ```bash
   git clone <repo-url>
   cd spr25-team-23/Backend
   npm install
   ```

3. **Start all backend services (DB, MinIO, Firebase emulator, API server):**
   ```bash
   npm run dev:full
   ```
   - This starts PostgreSQL, pgAdmin, MinIO (S3-compatible), Firebase Auth emulator, and the API server.

4. **Run the iOS app in Xcode (Debug/Simulator):**
   - The app will connect to your local backend automatically.

5. **Stop all services when done:**
   ```bash
   npm run dev:stop
   ```

---

## Common Commands

| Command                  | Purpose                                      |
|-------------------------|----------------------------------------------|
| `npm run dev:full`      | Start DB, MinIO, emulator, API server        |
| `npm run dev:stop`      | Stop API server, DB, emulator                |
| `npm run dev`           | Start API server only                        |
| `npm run dev:stop:server` | Stop only the API server                   |
| `npm run db:start`      | Start DB, pgAdmin, MinIO                     |
| `npm run db:stop`       | Stop DB, pgAdmin, MinIO                      |
| `npm run minio:setup`   | Create MinIO buckets                         |
| `npm run emulators:start` | Start Firebase Auth emulator               |
| `npm run emulators:stop`  | Stop Firebase Auth emulator                |
| `npm run prisma:studio` | Open Prisma Studio (DB GUI)                  |
| `npm run prisma:reset`  | Reset local DB (deletes all data!)           |

---

## Local Environment Overview

- **Database:** PostgreSQL (localhost:5432, user/pass: postgres)
- **DB GUI:** pgAdmin ([http://localhost:5050](http://localhost:5050), admin/admin)
- **S3 Storage:** MinIO ([http://localhost:9001](http://localhost:9001), minioadmin/minioadmin)
- **API Server:** Express ([http://localhost:3001](http://localhost:3001))
- **Firebase Auth:** Emulator ([http://localhost:4000](http://localhost:4000))

---

## Typical Dev Workflow

1. **Start everything:**
   ```bash
   npm run dev:full
   ```
2. **Develop:**
   - Make backend changes (API, DB, S3, Auth)
   - Make iOS changes (run in Xcode Simulator)
   - Test image uploads, auth, etc.
   - Use MinIO Console to view uploaded images
   - Use Prisma Studio to view/edit DB
3. **Reset DB (if needed):**
   ```bash
   npm run prisma:reset
   # Type 'y' to confirm
   ```
4. **Stop everything:**
   ```bash
   npm run dev:stop
   ```

---

## Environment Files

- **env.development:** For local dev/emulator. Should match your iOS dev plist project ID.
- **env.production:** For production. Should match your iOS prod plist project ID.

**Never use prod credentials for local dev!**

---

## Troubleshooting

- **DB connection issues:**
  - Is Docker running? `docker ps`
  - Restart DB: `npm run db:stop && npm run db:start`
- **Port conflicts:**
  - Stop other services using 5432, 3001, 9000, 9001, 9099, 4000
- **Auth 401 errors:**
  - Make sure both backend and iOS use the same Firebase project ID (dev for dev, prod for prod)
  - Check `FIREBASE_AUTH_EMULATOR_HOST` and `FIREBASE_PROJECT_ID` in `env.development`
  - iOS: Confirm `Auth.auth().useEmulator(withHost: "localhost", port: 9099)` is called in Debug
- **Unique constraint errors:**
  - Reset DB: `npm run prisma:reset`
- **MinIO not working:**
  - Check MinIO Console: [http://localhost:9001](http://localhost:9001)
  - Buckets missing? Run: `npm run minio:setup`
- **Emulator not working:**
  - Start: `npm run emulators:start`
  - Stop: `npm run emulators:stop`

---

## Best Practices

- Use `npm run dev:full` and `npm run dev:stop` for daily work
- Use separate Firebase projects for dev and prod
- Never commit `.env` files or credentials
- Use MinIO for local S3, never real AWS S3 in dev
- Use Prisma Studio for DB inspection
- Clean up test data regularly

---

## 🛠️ Super Admin Local Guide (Advanced)

> **Warning:** These operations are for advanced users. Always make sure you’re working in your local/dev environment—never production!

### 1. Direct Database Access
- **Prisma Studio (Recommended):**
  - Run: `npm run prisma:studio`
  - Opens [http://localhost:5555](http://localhost:5555) in your browser.
  - Edit, add, or delete any data in your local DB.
- **pgAdmin:**
  - Visit [http://localhost:5050](http://localhost:5050)
  - Login: admin/admin
  - Full SQL access to your local PostgreSQL database.
- **psql CLI:**
  - Run: `docker exec -it team23-postgres psql -U postgres team23_dev`
  - You can run raw SQL queries directly.

### 2. MinIO (S3) Management
- **Web Console:**
  - Visit [http://localhost:9001](http://localhost:9001)
  - Login: minioadmin/minioadmin
  - Browse, upload, download, or delete files/buckets.
- **mc CLI (MinIO Client):**
  - [Install mc](https://docs.min.io/docs/minio-client-quickstart-guide.html)
  - Configure: `mc alias set local http://localhost:9000 minioadmin minioadmin`
  - List buckets: `mc ls local`
  - Remove a bucket: `mc rb --force local/cove-user-images-dev`
  - Upload/download files: `mc cp ...`

### 3. Manual Data Seeding or Cleanup
- **Reset DB:** `npm run prisma:reset` (wipes all data)
- **Seed Data:** Add scripts in `Backend/src/scripts/` and run with `ts-node`.
- **Delete MinIO Buckets:** Use MinIO Console or `mc` CLI as above.

### 4. Debugging & Logs
- **API Logs:**
  - All backend logs print to your terminal running `npm run dev`.
- **Docker Logs:**
  - `docker logs team23-postgres`
  - `docker logs team23-minio`

### 5. Caution!
- **Never run these commands against production!**
- **Always double-check which environment you’re connected to.**
- **If in doubt, ask your team before making destructive changes.**