/**
 * Backend/src/prisma/client.ts
 * ------------------------------------------------------
 * CENTRAL SINGLETON FOR PRISMA CLIENT
 * ------------------------------------------------------
 *  Why do we need this file?
 *  ----------------------------------
 *  In a traditional long-running Node server you can safely call
 *     `new PrismaClient()` once during boot and reuse the internal
 *  connection pool.
 *
 *  In **serverless / lambda** environments every cold-start executes
 *  your module code again. If each cold-start creates a *brand-new*
 *  PrismaClient, you end up opening one physical Postgres connection
 *  **per container**. Under load the DB quickly hits
 *  "remaining connection slots are reserved…" and your functions fail.
 *
 *  The pattern below ensures **exactly one** PrismaClient instance per
 *  execution environment:
 *    • For development w/ hot-reload we reuse a global instance stored
 *      on `globalThis` to avoid the infamous "PrismaClientAlreadyInUse".
 *    • For production we still get one instance per container (which is
 *      what you want) because AWS Lambda freezes + reuses containers.
 *
 *  Usage: simply import `prisma` anywhere in the backend
 *      import { prisma } from '../prisma/client';
 *      const user = await prisma.user.findUnique({ where: { id } });
 */

import { PrismaClient } from '@prisma/client';

// We extend the Node global type so TypeScript knows about the cached client
// (The cast to `unknown` avoids polluting global types for other modules.)
const globalForPrisma = globalThis as unknown as {
  prisma?: PrismaClient;
};

// Reuse the cached instance if it exists, otherwise create a new one.
export const prisma =
  globalForPrisma.prisma ||
  new PrismaClient({
    log: ['error'], // keep logs concise – adjust as needed (e.g. 'query')
  });

// Cache the client only in *non-production* to avoid leaking across worker
// threads when using clustering / edge runtimes that recreate the global
// object. In a Lambda environment NODE_ENV is usually 'production'.
if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma;
}

// No default export – encourage explicit named import `{ prisma }` to
// distinguish from other utilities.

/**
 * Graceful shutdown / connection cleanup
 * -------------------------------------
 *  In long-running environments (Express dev server, unit tests, etc.) we
 *  want to close the connection pool when the process exits. In AWS Lambda
 *  this isn’t required – the container freeze will drop the socket – but
 *  it doesn’t hurt either because the handler below runs only once per
 *  execution environment.
 */

process.once('SIGTERM', async () => {
  console.log('[prisma] SIGTERM received – disconnecting PrismaClient');
  await prisma.$disconnect();
});

process.once('beforeExit', async () => {
  console.log('[prisma] beforeExit – disconnecting PrismaClient');
  await prisma.$disconnect();
});