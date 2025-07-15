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

**Need help?** Ask your team or check the troubleshooting section above! 