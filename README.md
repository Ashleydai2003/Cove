# Cove

Cove is a social platform for organizing events within alumni communities (coves). The platform enables users to create and join coves, organize events with RSVP management, share posts, message friends, and discover content through a ranked feed.

## Tech Stack

### Backend
- **Runtime**: Node.js 18 (AWS Lambda for REST API, EC2 Docker for WebSocket)
- **Framework**: Express (local dev), Lambda handler (production)
- **Database**: PostgreSQL (AWS RDS) with Prisma ORM
- **Storage**: AWS S3 with presigned URLs for secure image uploads
- **Real-time**: Socket.IO WebSocket server (separate EC2 deployment)
- **Authentication**: Firebase Authentication (phone number + OTP)
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Infrastructure**: Terraform for IaC, GitHub Actions for CI/CD

### Clients
- **iOS**: Swift/SwiftUI, Firebase SDK, WebSocket client
- **Web**: Next.js 14 (App Router), React, TypeScript, Tailwind CSS

### Infrastructure & DevOps
- **Cloud**: AWS (Lambda, RDS, S3, EC2, API Gateway, Secrets Manager, VPC)
- **IaC**: Terraform
- **CI/CD**: GitHub Actions with OIDC authentication
- **Database Migrations**: Prisma with automated detection and on-demand EC2 execution
- **Local Development**: Docker Compose (PostgreSQL, MinIO, pgAdmin), Firebase Emulator

## Architecture

### System Overview

**Backend Architecture**
- **REST API**: Serverless Lambda functions behind API Gateway for scalable, cost-effective request handling
- **WebSocket Server**: Separate EC2-hosted Socket.IO server for persistent real-time connections
- **Database**: PostgreSQL in private VPC subnet with Prisma for type-safe database access
- **Image Storage**: S3 buckets with presigned URLs enabling secure client-side uploads without exposing credentials
- **Authentication**: Firebase Auth with backend token validation for zero-trust security model

**Client Applications**
- **iOS**: Native SwiftUI app with real-time messaging, push notifications, and offline support
- **Web**: Next.js with server-side rendering for SEO and social sharing (Open Graph metadata)

**Deployment Strategy**
- **Smart Migrations**: CI/CD detects schema changes and executes migrations on-demand via EC2 (cost-optimized)
- **Environment Isolation**: Separate Firebase projects and AWS resources for dev/staging/production
- **Automated Testing**: PostgreSQL service containers in CI for database integration tests

### Backend Architecture

**Code Organization**
```
Backend/
├── src/
│   ├── index.ts              # Lambda handler with path-based routing
│   ├── local-server.ts       # Express server for local development
│   ├── socket-server.ts      # WebSocket server (EC2 deployment)
│   ├── routes/               # Domain-organized route handlers
│   ├── middleware/           # Firebase auth, request validation
│   ├── services/             # Business logic (feed ranking, etc.)
│   ├── ranking/              # Feed ranking algorithm (ML-ready architecture)
│   ├── config/               # Database and S3 client initialization
│   ├── utils/                # CORS, error handling
│   └── scripts/              # Migration and setup utilities
├── prisma/
│   ├── schema.prisma         # Single source of truth for database schema
│   └── migrations/           # Version-controlled migration history
└── dist/                     # Compiled Lambda bundle (esbuild)
```

**Key Design Patterns**

**Privacy-Aware API Responses**
- Endpoints return limited or enriched data based on user relationship
- Event details (location, guest list) only visible to hosts and approved attendees
- Profile data varies by viewer (self vs. friend vs. public)
- Reduces data exposure while maintaining functionality

**Cursor-Based Pagination**
- Stable ordering across requests using cursor IDs
- Prevents duplicate/missing items during pagination
- Consistent ranking for feed endpoints

**Presigned URL Pattern**
- Clients receive time-limited S3 upload URLs (1-hour expiry)
- No backend proxy needed for image uploads
- Reduces Lambda costs and improves upload performance

**Server-Side Feed Ranking**
- Unified ranking algorithm across iOS, web, and future platforms
- Exponential decay for freshness, time-sensitivity weighting for events
- Architecture supports future ML model integration
- Consistent user experience regardless of client

**Smart Migration Detection**
- CI/CD pipeline detects `schema.prisma` changes
- Only triggers migration runner when schema actually modified
- EC2 instance started on-demand, stopped after completion (cost optimization)

### Database Schema

**Core Models**
- `User`: Authentication and basic profile
- `UserProfile`: Extended profile (interests, location, education, work, etc.)
- `Cove`: Community groups with location and description
- `CoveMember`: Many-to-many with roles (MEMBER, ADMIN)
- `Event`: Events within coves with RSVP system
- `EventRSVP`: Approval workflow (PENDING → GOING)
- `Post` / `PostLike`: Social posts with engagement tracking
- `Thread` / `Message` / `MessageRead`: Direct messaging with read receipts
- `Friendship` / `FriendRequest`: Friend system
- `Invite`: Phone number-based cove invitations

**Design Decisions**
- Composite unique constraints prevent duplicate relationships
- Cascade deletes maintain referential integrity
- Indexed foreign keys for query performance
- Timestamps on all models for audit trails

### iOS Application

**Architecture**
```
CoveApp/
├── App/                      # App lifecycle and core services
│   ├── CoveApp.swift         # SwiftUI app entry point
│   ├── FirebaseSetup.swift   # Firebase initialization
│   └── NetworkManager.swift  # Centralized API client
├── Views/
│   ├── Main/                 # Primary app screens (feed, events, messages)
│   ├── Onboarding/           # User onboarding flow
│   └── Shared/               # Reusable SwiftUI components
└── Utilities/                # Location, notifications, WebSocket, image handling
```

**Key Features**
- SwiftUI declarative UI with reactive state management
- WebSocket manager for real-time messaging
- FCM push notification integration
- S3 image upload with client-side compression
- Location services for geocoding and proximity features

### Web Application

**Architecture**
```
WebApp/
├── app/                      # Next.js App Router
│   ├── api/                  # API route handlers (proxy to backend)
│   ├── events/[eventId]/     # Dynamic event pages with SSR
│   └── coves/[coveId]/       # Dynamic cove pages
├── components/               # React components (server and client)
├── lib/                      # Utilities (auth, API client, Firebase)
└── types/                    # TypeScript type definitions
```

**Key Features**
- Server-side rendering for SEO and performance
- Open Graph metadata for social sharing
- Responsive design with Tailwind CSS
- Firebase authentication integration
- API proxy routes for CORS handling

### Infrastructure

**AWS Resources** (Terraform-managed)
- **VPC**: Isolated network with public/private subnets
- **RDS**: PostgreSQL in private subnet (no public access)
- **Lambda**: Serverless REST API handler
- **API Gateway**: REST API endpoint with CORS
- **EC2**: WebSocket server (Docker) and on-demand migration runner
- **S3**: Separate buckets for user images, cove covers, event covers
- **Secrets Manager**: Database credentials and API keys
- **VPC Endpoints**: Private connectivity to S3 and Secrets Manager (no internet gateway needed)

**Deployment Pipeline**
- **Backend API**: Automated Lambda deployment on push to `main`/`develop`
- **WebSocket Server**: Manual Docker deployment to EC2 (see `Backend/deploy-socket.sh`)
- **Migrations**: EC2-based runner triggered only when `schema.prisma` changes
- **iOS**: TestFlight (staging) and App Store (production) via GitHub Actions
- **Web**: Vercel deployment (configured separately)

**Cost Optimization**
- EC2 instances only run when needed (migrations, WebSocket server)
- Lambda pay-per-request model for API
- VPC endpoints reduce data transfer costs
- Smart migration detection avoids unnecessary EC2 usage

### Development Workflow

**Local Setup**
- Docker Compose: PostgreSQL, MinIO (S3-compatible), pgAdmin
- Firebase Auth emulator for local authentication
- Hot-reload Express server on port 3001
- Prisma Studio for database inspection

**Key Commands**
- `npm run dev:full`: Start all local services
- `npm run prisma:migrate:dev`: Create and apply migrations locally
- `npm run prisma:studio`: Open database GUI
- `npm run build`: Build Lambda bundle for deployment

**Environment Management**
- `env.development`: Local development configuration
- `env.production`: Production configuration (AWS secrets from Secrets Manager)
- Separate Firebase projects for dev and prod

## Implementation Details

### Authentication & Authorization

- **Firebase Authentication**: Phone number-based auth with OTP verification
- **Token Validation**: ID tokens validated on backend using Firebase Admin SDK
- **Role-Based Access**: Cove admins, event hosts, and members have different permissions
- **Privacy Controls**: Event details (location, guest list) only visible to hosts and approved attendees

### Real-time Features

- **WebSocket Server**: Separate Socket.IO server deployed on EC2 as Docker container
- **Message Delivery**: Real-time message broadcasting to thread participants
- **Read Receipts**: Track message read status per user
- **Push Notifications**: FCM integration for offline notifications
- **SSL/TLS**: Production WebSocket server uses WSS with Let's Encrypt certificates

### Feed Algorithm

Server-side ranking algorithm for unified feed experience:
- **Freshness**: Exponential decay based on creation time
- **Time Sensitivity**: Events weighted by proximity to event date
- **Cursor Pagination**: Stable ordering across requests
- **ML-Ready**: Architecture designed for future engagement-based ranking and personalization

### Image Management

- **Upload Flow**: Base64 → S3 via presigned URL (1-hour expiry)
- **Storage**: Separate buckets for user images, cove covers, event covers
- **Delivery**: S3 public URLs for image delivery
- **Optimization**: Client-side compression before upload

### RSVP System

Approval-based workflow:
1. User RSVPs → Status: `PENDING`
2. Host reviews pending requests via dedicated endpoint
3. Host approves → Status: `GOING` (full event access granted)
4. Host declines → RSVP deleted

Hosts have full access regardless of their own RSVP status. Hosts auto-approve themselves when RSVPing to their own events.

## Documentation

- [Local Development Guide](./LOCAL_DEVELOPMENT.md): Setup and daily workflow
- [CI/CD Setup](./CI-CD-SETUP.md): Deployment pipeline configuration
- [Migration Workflow](./MIGRATION_WORKFLOW.md): Database migration process
- [Linting Guide](./LINTING.md): Code style requirements
- [Backend API Documentation](./Backend/API.md): Complete API reference
