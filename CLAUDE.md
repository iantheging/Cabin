# CLAUDE.md

Guidance for working in this repo. Read before making changes.

## What this is

A shared booking calendar for the **Bond Family Cottage** (located in Mackinaw City, MI). Family members reserve dates, see everyone's stays on a calendar, flag conflicts, and negotiate date changes. Admins manage members and resolve conflicts.

## Architecture — the one thing to internalize

**The entire app is a single self-contained file: `index.html`.** Inline `<style>` and inline `<script>`, no build step, no frameworks, no bundler, no external JS/CSS. The only external requests are Google Fonts (Cormorant Garamond + Nunito) and the Supabase REST API.

- **Frontend:** vanilla HTML/CSS/JS in `index.html`.
- **Backend:** [Supabase](https://supabase.com) accessed directly over its PostgREST REST API (no supabase-js library). All calls go through the `sbFetch()` helper and the `db` object (`db.getBookings()`, `db.addBooking()`, etc.).
- **Hosting:** Netlify.
- **State:** three screens (`#setupScreen`, `#loginScreen`, `#appScreen`) toggled via `style.display`; four tabs (Calendar / Stays / Requests / Admin) toggled by `showTab()`. Data is loaded into module-level arrays (`allBookings`, `allRequests`, `allUsers`, `currentUser`) by `loadAll()`, then `renderAll()` re-renders everything.

### The JS is element-ID-driven
Rendering reads and writes DOM nodes by `getElementById`. **Do not rename or remove element IDs** — the JS depends on them. Adding new wrapper elements is fine.

## Database

Three tables, defined in `SETUP.sql` (the source of truth for schema): `users`, `bookings`, `requests`. Run `SETUP.sql` in the Supabase SQL Editor to provision a fresh project. `requests.booking_id` is a FK to `bookings.id` with `ON DELETE CASCADE`.

- Supabase project ref: `teydibwzsisxcczruabq`.
- **Connection is baked in:** `DEFAULT_SB_URL` / `DEFAULT_SB_KEY` constants near the top of the `<script>` hold the project URL and anon public key, so no per-device setup is needed. A value saved in `localStorage` (via the setup screen / "Reconnect to Supabase") overrides the defaults. The anon key is a public client-side key by design.
- To query the DB directly without the MCP server, connect a Postgres client (e.g. VS Code SQLTools) using the Session-pooler connection string from Supabase → Settings → Database. That needs the **database password** (not the anon key), which is not stored in this repo.

## Deploy

**Netlify auto-deploys on push to GitHub.** Pushing to the default branch (`main`) triggers a Netlify build/deploy automatically — there is no manual drag-and-drop step in the normal workflow. So: commit + push = live. Because the app is one static file, "build" is just publishing `index.html`. All users get the update on their next load.

> Note: `DEPLOYMENT_GUIDE.md` still describes the older manual drag-and-drop flow and the pre-baked-in setup step; it's partly out of date relative to the current git-based deploy and baked-in credentials.

## Conventions

- **Keep it simple and unfussy.** Match the existing terse, dependency-free style. No frameworks or build tooling. Prefer the fewest lines that read like the surrounding code.
- **Mobile matters.** The app was redesigned mobile-first (see `requirements/MOBILE_REQUIREMENTS.md`). Phones use a fixed bottom nav, calendar cells use colored **bars** (not text chips) plus a tap-to-reveal **day detail panel** (`showDayDetail()`), modals become bottom sheets, and all inputs are ≥16px to avoid iOS zoom. Preserve these when editing; test at ~360px width.
- **CSS lives in `:root` custom properties** (`--lake`, `--lighthouse`, etc.) — reuse them; don't hardcode new hex values where a variable exists.
- Date helpers: `fmt()` (Date→YYYY-MM-DD), `nice()` (short display), `niceFull()` (weekday + date), `nights()`, `getConflictIds()`.

## Known issues / constraints (do not "fix" without being asked)

- **Passwords are stored and compared in plaintext** in the `users` table. This is a known limitation of the simple family-app model, not a bug to silently change.
- **Row Level Security is disabled** on all tables and the anon role has full CRUD. Anyone with the anon key (which ships in the page) can read/write every row. Intentional per `SETUP.sql`; hardening would require enabling RLS *and* adding policies together (enabling alone locks out the app).
- **`fmt()` timezone quirk:** it uses `toISOString()`, which can shift a date across midnight in non-UTC timezones. Pre-existing; leave unless explicitly tasked.

## Repo files

- `index.html` — the entire app.
- `SETUP.sql` — database schema + seed admin (`Admin` / `cottage2024`).
- `DEPLOYMENT_GUIDE.md` — end-user deploy walkthrough (partly outdated, see Deploy note).
- `README.md` — project overview.
- `requirements/` — feature/spec docs:
  - `MOBILE_REQUIREMENTS.md` — spec that drove the mobile redesign (implemented).
  - `POSTS_REQUIREMENTS.md` — spec for the posts & comments board (not yet built).
- `.agents/skills/` — installed Supabase agent skills (guidance/reference).
