# Candela API — Project Overview

## What it is

Location-based social discovery app. Users physically check in to real places, earn points, build reputation, challenge friends, and see their friends' activity in a social feed. Safety rules for minors (under 18) are enforced at registration; minor-specific features are Fase 2.

## Stack

| Layer | Technology |
|---|---|
| Language | Go 1.22 |
| HTTP Framework | Gin |
| Database | PostgreSQL 15 + PostGIS |
| Cache / Queue | Redis |
| Object Storage | MinIO (dev), S3-compatible (prod) |
| Auth | JWT (HS256, 1-hour TTL) |
| Migrations | golang-migrate |

## Repository Structure

```
nomad-api/
├── cmd/
│   ├── server/main.go          # Entry point, graceful shutdown
│   └── migrate/                # Migration runner (run as: go run ./cmd/migrate up)
├── db/migrations/              # SQL migration files (up + down)
│   ├── 000001_init             # users, point_transactions
│   ├── 000002_places           # places (PostGIS GEOGRAPHY column)
│   ├── 000003_check_ins        # check_ins
│   ├── 000004_challenges       # challenges
│   ├── 000005_social           # follows (legacy, not used)
│   ├── 000006_ranking_index    # partial index for global ranking
│   ├── 000007_friendships      # friendships table
│   └── 000008_friendships_requester  # adds requester_id to friendships
├── internal/
│   ├── config/config.go        # Env var loading → Config struct
│   ├── domain/                 # Pure Go structs, no DB tags
│   │   ├── user.go
│   │   ├── check_in.go
│   │   ├── challenge.go
│   │   ├── friendship.go
│   │   ├── ranking.go
│   │   ├── privacy.go
│   │   ├── place.go
│   │   ├── social.go
│   │   └── feed.go             # Feed/profile types (MyProfile, CheckInEvent, etc.)
│   ├── repo/                   # SQL queries only, no business logic
│   │   ├── user_repo.go
│   │   ├── place_repo.go
│   │   ├── checkin_repo.go
│   │   ├── friendship_repo.go
│   │   ├── challenge_repo.go
│   │   ├── ranking_repo.go
│   │   └── feed_repo.go        # Feed queries (friends' check-ins + challenges)
│   ├── service/                # Business logic
│   │   ├── auth_service.go
│   │   ├── checkin_service.go  # GPS validation, nonce, photo upload, challenge hook
│   │   ├── challenge_service.go
│   │   ├── friend_service.go
│   │   ├── ranking_service.go  # Redis caching (1h global, 5min friends)
│   │   ├── user_service.go     # Privacy, block, profile visibility, account deletion
│   │   └── profile_service.go  # GET /api/me, feed, check-in history, challenge history
│   ├── handler/                # HTTP layer — binds requests, calls service, returns JSON
│   │   ├── auth_handler.go
│   │   ├── checkin_handler.go
│   │   ├── challenge_handler.go
│   │   ├── friend_handler.go
│   │   ├── ranking_handler.go
│   │   ├── user_handler.go
│   │   ├── profile_handler.go  # /api/me, /api/feed, /api/me/check-ins, /api/me/challenges
│   │   └── place_handler.go
│   ├── web/
│   │   ├── router.go           # All routes wired here
│   │   └── middleware/
│   │       ├── auth.go         # JWT verify + Redis blocklist check
│   │       └── ratelimit.go    # Redis-based IP rate limiter
│   ├── infra/
│   │   ├── postgres/           # pgxpool connection
│   │   ├── redis/              # Redis client
│   │   └── storage/            # MinIO/S3 abstraction (presigned PUT/GET)
│   └── webdeps/dependencies.go # Dependency struct injected into router
├── docker-compose.yml          # postgres, redis, minio, api (Air hot-reload)
├── Makefile
├── CLAUDE.md                   # AI assistant context
└── .env.example
```

## Key Architecture Decisions

**Layered architecture:** domain → repo → service → handler. Repos only do SQL. Services own all business rules. Handlers only parse/validate HTTP and call service.

**Two-step check-in:** GPS validation + nonce (step 1) → direct photo upload to MinIO → confirm with nonce (step 2). The API server never receives the photo bytes. Nonce is single-use with 90-second TTL in Redis.

**Friendship ordering constraint:** The `friendships` table enforces `CHECK (user_id_a < user_id_b)`. All friendship operations use `orderedPair()` to transparently sort UUIDs before any DB call.

**Challenge completion hook:** `checkin_service.Confirm` calls `challengeRepo.CompleteMatchingChallenges` after saving the check-in. If any ACCEPTED challenge for the same (user, place) pair is within deadline, it completes all of them in a single DB transaction and awards bonus points.

**Lazy challenge expiration:** There is no cron job. Before returning any challenge list, the service runs `UPDATE challenges SET status='FAILED' WHERE deadline_at < NOW() AND (creator_user_id=$1 OR target_user_id=$1)`.

**JWT blocklist:** On `DELETE /api/me`, the user's JWT is stored in Redis with key `jwt:blocklist:<userID>` and TTL = remaining token life. Auth middleware checks this key on every request.

**Feed is never cached:** The social feed is personal and changes constantly. It is computed fresh on every request by UNIONing friends' check-ins and friends' completed challenges, then merging and sorting in Go.

**Rankings are cached:** Global ranking: `rankings:global` (1-hour TTL). Friend ranking: `rankings:friends:<userID>` (5-minute TTL). Cache is invalidated on privacy changes, friend additions/removals, and account deletion.

## Authentication

All protected routes require `Authorization: Bearer <token>`.

The middleware (`internal/web/middleware/auth.go`):
1. Parses and verifies the JWT signature.
2. Checks `jwt:blocklist:<userID>` in Redis — returns `401` if found.
3. Checks `account_status` claim — returns `403` for SUSPENDED/DELETED.
4. Injects `userID` (uuid.UUID), `isProtected` (bool), `accountStatus` (string), `tokenExpiry` (time.Time) into the Gin context.

## Business Rules Summary

| Rule | Where enforced |
|---|---|
| Users under 18: blocked at registration | `auth_service.go` |
| `is_protected = true` cannot set `privacy_mode = PUBLIC` | `user_service.UpdatePrivacy` |
| Places marked `apto_menores=PENDING` treated as NO | `checkin_repo.IsRestrictedForMinors` |
| Check-in GPS validated server-side via PostGIS | `checkin_repo.IsWithinGeofence` |
| Challenges only between accepted friends | `challenge_service.Create` |
| Challenge deadline: 24, 48, or 72 hours | `challenge_service.Create` (also DB CHECK) |
| Block relationships are bidirectional, always return 404 | `user_service.GetProfile` |
| Feed excludes PRIVATE friends | `feed_repo.GetFeedCheckIns/GetFeedChallenges` |
| Photo URLs expire in 24 hours (presigned GET) | MinIO presigned URL TTL |

## Running Locally

```bash
cp .env.example .env          # edit DB/Redis/MinIO credentials
make up                        # starts postgres, redis, minio, api (with Air)
make migrate-up                # applies pending migrations
make logs-api                  # follow API logs
```

API listens on `http://localhost:8080`. MinIO console at `http://localhost:9001` (credentials: minioadmin / minioadmin).

## Make Targets

| Target | Description |
|---|---|
| `make up` | Start all Docker services |
| `make down` | Stop containers (data preserved) |
| `make down-v` | Stop + delete volumes (destroys data) |
| `make migrate-up` | Apply pending migrations |
| `make migrate-down` | Revert last migration |
| `make logs-api` | Follow API container logs |
| `make shell-db` | Open psql inside the DB container |
| `make redis-cli` | Open redis-cli inside the Redis container |
