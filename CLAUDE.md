# Candela Front — Developer & Design Context

## Project documents (read before any task)
- `../CANDELA_ESPECIFICACIONES_FUNCIONALES.md` — product spec, voice & tone,
  visual identity system (section 3), screen architecture (section 6)
- `../CANDELA_MVP_1.0.md` — MVP scope, frontend changes section 8
- `../CANDELA_API_CHANGELOG.md` — full API contract, all endpoint responses

## Design system — non-negotiable
Primary color:     Candela Amber  #E8580A  (never the old red)
Light background:  Candela Sand   #FAF6F0
Dark background:   Candela Night  #1A1410
Success accent:    Candela Sage   #5C8B6E
Text secondary:    #6B5E58
Border/inactive:   #C4B8B2

Typography: Plus Jakarta Sans exclusively (via google_fonts)
  Title screens:   700 weight, 24–28px
  Place/event names: 600 weight, 18–20px
  Body:            400 weight, 15–16px
  Metadata:        400 weight, 12–13px
  Button labels:   600 weight, 14–15px

Border radius: 12px cards, 8px medium elements, 20px pills/primary buttons
Card padding: 16px internal minimum. Card gap: 12px. Screen margins: 16px.
Icons: thin stroke (1.5px), filled only for active nav tab.
Check-in button: flame icon, Candela Amber, always floating above nav bar.

## Architecture rules
- No business logic in widgets. Widgets render state, do not compute it.
- JWT stored exclusively in flutter_secure_storage. Never plain storage.
- 401 from API always clears token and redirects to login.
- API base URL configured as a single constant, not hardcoded per screen.
- All Dart code, model fields, and method names in English.
- All UI strings shown to users in Spanish (Candela voice).

## Screen structure (4 tabs + floating check-in button)
Tab 1 — Map (default home screen)
Tab 2 — Feed (city scroll)
Tab 3 — Plans (replaces Challenges)
Tab 4 — Profile (own profile)
Floating — Check-in button (flame, always visible above nav)

## Key behavioral rules
- Feed shows ONLY check-in photos from active events (last 4h).
  No plan_completed events in the feed.
- Photos are ephemeral by default. photo_is_permanent is opt-in.
- Points are private. Never show another user's point total unless
  they have ranking_opt_in = true.
- Badge levels: "Nuevo en la vuelta", "Callejero", "Parroquiano",
  "Teso", "Leyenda"
- Dark mode activates automatically by OS setting, manually forceable.
  Dark mode is the premium Candela experience — amber on near-black.