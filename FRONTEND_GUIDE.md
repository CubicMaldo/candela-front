# Candela API — Frontend Integration Guide

Everything here is derived from the actual server implementation. Do not guess behavior — read this document.

---

## 1. Authentication Flow

### Registering

Send `POST /api/auth/register` with email, username, password, and birth_date. On `201` you get `{ token, user }` in a single response — store the token immediately. Default `privacy_mode` is `"FRIENDS"`.

**Age restriction:** Server rejects users under 18 with `422`. Show a specific message.

### Logging in

`POST /api/auth/login` returns the same `{ token, user }` shape.

### Token storage

Store in secure storage (Keychain on iOS, Keystore on Android). Never plain SharedPreferences or unencrypted AsyncStorage.

### Token lifetime and expiry

Tokens expire after **1 hour**. Read the `exp` claim to schedule proactive re-login:

```js
const payload = JSON.parse(atob(token.split('.')[1]));
const expiresAt = new Date(payload.exp * 1000);
```

On any `401`: clear the token and redirect to login. Do **not** retry automatically — there is no refresh endpoint.

**Special case:** `401` with `error: "account no longer active"` means the account was deleted. Clear all local state and show a specific message.

### JWT claims useful client-side

| Claim | Use |
|---|---|
| `sub` | User UUID — needed for API calls that take `:user_id` |
| `is_protected` | Disable the PUBLIC privacy option in settings UI if `true` |
| `account_status` | Gate access; show warning if not `ACTIVE` |
| `exp` | Schedule proactive re-login |

---

## 2. Own Profile

### Loading the profile screen

Call `GET /api/me` on app start and after any action that modifies points, friends, or challenges. This is the single source of truth for the authenticated user's data.

The response includes everything needed for a profile screen: all user fields plus `check_in_count`, `friends_count`, and `completed_challenges_count`. No second request needed.

`password_hash`, `guardian_token`, and `guardian_contact` are never in the response.

### Showing check-in history

`GET /api/me/check-ins` — cursor-based, returns `check_ins[]` + `next_cursor`. Load the next page by passing `before=<next_cursor>`. `next_cursor` is `null` when there are no more pages.

`photo_url` will be `null` if the 24-hour photo TTL has expired. The event itself is always returned — never hide the check-in, just hide the photo.

### Showing challenge history

`GET /api/me/challenges` — use the `status` filter:
- `active` → PENDING and ACCEPTED (the ones requiring action)
- `completed` → finished challenges
- `failed` → expired or rejected

Each item includes a `role` field: `"creator"` (you sent it) or `"target"` (you received it).

The server runs lazy expiration before returning results — you never need to compute expiry client-side.

---

## 3. Check-in Flow

The check-in requires **two API calls** and a **direct upload to object storage**. This is never a single-request flow.

### Step-by-step

**1.** Request OS location permission.

**2.** Call `POST /api/places/:place_id/checkin/initiate` with `{ lat, lon }`.
- `422` → user is too far. Show distance indicator. Stop.
- `409` → already checked in today. Show "see you tomorrow". Stop.

**3.** On success, open the in-app camera immediately. **Do not allow gallery selection** — the product requires real physical presence.

**4.** Start a **90-second countdown** the moment the camera opens. The nonce expires in 90 seconds. If it expires, discard the photo and restart from step 2.

**5.** When the photo is taken, `PUT` it directly to `upload_url`:
```
PUT <upload_url>
Content-Type: image/jpeg
Body: <photo bytes>
```
This goes to MinIO/S3, not to the API server.

**Local dev note:** `upload_url` contains the Docker-internal hostname `minio`. Replace it with `localhost` before use:
```js
const url = response.upload_url.replace('http://minio:9000', 'http://localhost:9000');
```

**6.** Call `POST /api/places/:place_id/checkin/confirm` with `{ checkin_nonce, photo_key }`.
- `422` → nonce expired or wrong. Restart from step 2.
- `201` → success. Show `points_awarded` and celebrate `is_first_of_day` if true.

**7.** `photo_view_url` in the response is valid for **24 hours**.

### Points breakdown

| Condition | Points |
|---|---|
| Base | +10 |
| First check-in of the day | +5 |
| Photo | +5 |
| **Max** | **20** |

If the check-in completes an accepted challenge, the server silently awards bonus points to both users (+8 creator, +10 target). This does not change `points_awarded` in the confirm response — the user will see their updated total the next time they call `GET /api/me`.

---

## 4. Friends System

### Sending a friend request

`POST /api/users/:user_id/friend-request`

Show the button only when viewing a profile that is not already a friend and not yourself. If the response is `409`, update the UI to show "request pending".

### Incoming / outgoing requests

Call `GET /api/friend-requests/incoming` and `GET /api/friend-requests/outgoing` to populate a "Friends" or "Requests" screen. Both return `{ requests[], total }`.

### Accepting / rejecting

`POST /api/friend-requests/:user_id/accept` → `200`. Refresh the friends list and rankings.
`POST /api/friend-requests/:user_id/reject` → `204`. Remove from incoming list.

**Important:** Only the **recipient** can accept or reject. The server returns `403` if the sender tries. If you receive a `403`, the UI state is wrong — reload from the server.

### Cancelling a request you sent

`DELETE /api/friend-requests/:user_id` → `204`. Only the original sender can cancel.

### Removing a friend

`DELETE /api/users/:user_id/friend` → `204`. After success, invalidate locally cached rankings for both users.

### Friends list

`GET /api/me/friends` → `{ friends[], total }`. Alphabetical order. Use for the friends tab.

### 404 on friend-related calls

A `404` on any user-targeting endpoint (`friend-request`, `block`) means a block relationship exists in one direction. **Never** try to distinguish block from "not found" — show "user not found" regardless.

---

## 5. Privacy Modes

Users have three settings. The frontend must respect them in both the settings UI and profile rendering.

| Mode | Global ranking | Strangers see | Friends see |
|---|---|---|---|
| `PUBLIC` | Yes | Full profile | Full profile |
| `FRIENDS` | No | Username + badge only | Full profile |
| `PRIVATE` | No | `404` | Username + badge only |

### Detecting partial vs full profile

`GET /api/users/:username` returns two possible shapes. Detect client-side:

```js
if ('points_total' in response) {
  // Full profile
} else {
  // Partial profile — only username and badge_level
}
```

### Settings UI rule

If the JWT claim `is_protected = true`, **disable the PUBLIC option** before the user taps it. The server also blocks it with `422`, but prevent it in the UI to avoid a round-trip.

---

## 6. Challenges

### Creating a challenge

`POST /api/challenges` — requires friendship. The `deadline_hours` field must be exactly `24`, `48`, or `72` — show a picker, not a free-text input.

Error mapping:
- `404` → blocked user (don't say why, just "user not found")
- `409` → already challenged this friend at this place. Show "challenge already active"
- `422 "you can only challenge accepted friends"` → you need to be friends first

### Challenge inbox

`GET /api/challenges/incoming` — shows PENDING challenges the user has received.

Only the **target** can accept or reject. Check the `target_user_id` in the challenge against the JWT `sub` claim before showing the accept/reject buttons.

After accepting: poll or refresh `GET /api/me/challenges?status=active` to show the countdown.

### Challenge lifecycle in the UI

The `deadline_at` field tells you when the challenge expires. Show a countdown timer on ACCEPTED challenges. When the deadline passes, call `GET /api/me/challenges` — the server will mark it FAILED and return the updated state.

On `COMPLETED`: both users received bonus points. Show a celebration screen with `points_creator` and `points_target` from the completed challenge.

### Completing a challenge via check-in

The user does not need to do anything special. If a check-in at the right place completes an ACCEPTED challenge, the server handles it silently. After the check-in succeeds, call `GET /api/me/challenges?status=completed` to show the result.

---

## 7. Social Feed

### Feed structure

`GET /api/feed` returns a mixed array of two event types: `"checkin"` and `"challenge_completed"`. Always check the `type` field first.

```js
for (const event of response.events) {
  if (event.type === 'checkin') {
    // render: user.username checked in at place.name
    // show photo_url if not null
  } else if (event.type === 'challenge_completed') {
    // render: creator.username completed a challenge by target.username at place.name
  }
}
```

### Pagination

`GET /api/feed?limit=20` for the first page. If `next_cursor` is not null, load more with `GET /api/feed?before=<next_cursor>`. `next_cursor` is null when there are no more events.

Prepend new events on pull-to-refresh (fetch without `before`).

### Privacy behavior

A friend who switches to `PRIVATE` disappears from the feed immediately on the next request. There is no stale cache. Do not store feed events locally beyond what is currently displayed.

### Photo expiry in the feed

`photo_url` inside a `checkin` event can be `null` if the photo has expired. Always render gracefully — show a "photo expired" placeholder instead of a broken image.

---

## 8. Rankings

### Global ranking

`GET /api/rankings/global` — cached on server for 1 hour. The list shows only PUBLIC, non-protected, active users.

`user_rank` in the response always reflects the requesting user's position, even if they are outside the top 50. Pin this at the bottom of the screen so the user always knows where they stand. `null` if the user is not eligible (not PUBLIC, protected, or inactive).

### Friend ranking

`GET /api/rankings/friends` — cached per user for 5 minutes. Shows all accepted friends plus the authenticated user in the pool.

After a check-in, the friend ranking may take up to 5 minutes to reflect new points. Show the new points immediately in the UI using local state, and let the ranking resync naturally.

---

## 9. Error Handling

Map status codes to user-facing behavior:

| Status | Behavior |
|---|---|
| `400` | Show `response.error` directly — it is usually a readable field name message |
| `401` | Clear token, redirect to login. Special case: `"account no longer active"` → account deletion message |
| `403` | Show "action not allowed" — usually means you are not the correct participant |
| `404` | Context-dependent. For users → "user not found" (never reveal blocks). For challenges/requests → "not found" |
| `409` | Show `response.error` — always a specific conflict message |
| `422` | Show `response.error` — always a specific business rule violation |
| `429` | "Too many attempts. Please wait and try again." Do not retry automatically |
| `500` | "Something went wrong. Please try again later." Log the error, do not show the server message |

**Network errors (no response):** "Check your internet connection." For the check-in photo upload (which goes to MinIO directly), if the PUT fails, do not call confirm — restart from initiate.

---

## 10. Environment Configuration

| Variable | Local dev | Used for |
|---|---|---|
| `API_BASE_URL` | `http://localhost:8080` | All `/api/...` calls |
| Storage host (dev only) | `http://localhost:9000` | Replace `minio` in `upload_url` |

In production, `upload_url` from the check-in initiate response will contain the correct public storage hostname. No substitution needed.

MinIO dev console (for debugging): `http://localhost:9001` — credentials: `minioadmin` / `minioadmin`.
