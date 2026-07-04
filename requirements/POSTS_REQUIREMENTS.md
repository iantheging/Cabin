# Posts & Comments — Feature Requirements

**Target file:** `index.html` (single self-contained file — inline CSS + JS, Supabase REST backend)
**Goal:** Add a lightweight family "board" where members post updates about the cottage and leave comments. Chronological feed (newest post on top), comments collapsed by default, fully usable on mobile.

This spec assumes the app architecture described in `../CLAUDE.md` and follows the mobile patterns in `MOBILE_REQUIREMENTS.md` (same directory). Read both first.

---

## 1. Constraints — DO NOT change these

1. Keep everything in the single `index.html` file. No build step, no frameworks, no external JS/CSS.
2. Reuse the existing data layer: all DB access goes through `sbFetch()` and the `db` object. Add new `db.*` methods; do not introduce a second fetch path.
3. Reuse existing state/render flow: data loads into module-level arrays in `loadAll()`, and `renderAll()` re-renders. Add `allPosts` / `allComments` arrays and a `renderPosts()` that `renderAll()` calls.
4. Preserve all existing element IDs (the JS is `getElementById`-driven). New IDs are fine; follow the existing naming (`tab-posts`, `tab-posts-btn`, `postsList`, etc.).
5. Reuse existing CSS `:root` custom properties (`--lake`, `--lighthouse`, `--forest`, …) and the existing button/card/`.form-group` classes. Do not hardcode new hex values where a variable exists.
6. Match the existing terse, dependency-free style. Fewest lines that read like the surrounding code.

---

## 2. Data model (Supabase)

### 2.1 Tables to create

Two new tables, following the exact conventions of the existing `bookings` / `requests` tables in `SETUP.sql` (bigint identity PK, `username` as plain-text author, `timestamptz` timestamps, RLS disabled, full CRUD granted to `anon`).

| Table | Column | Type | Notes |
|-------|--------|------|-------|
| **posts** | `id` | `bigint` identity PK | generated always as identity |
| | `username` | `text not null` | author (matches the app's plain-text user model) |
| | `body` | `text not null` | post content |
| | `created_at` | `timestamptz default now()` | feed sort key (newest first) |
| | `updated_at` | `timestamptz default now()` | set on edit; drives the "edited" indicator |
| **comments** | `id` | `bigint` identity PK | generated always as identity |
| | `post_id` | `bigint` FK → `posts.id` | **`ON DELETE CASCADE`** |
| | `username` | `text not null` | author |
| | `body` | `text not null` | comment content |
| | `created_at` | `timestamptz default now()` | thread sort key (oldest first) |
| | `updated_at` | `timestamptz default now()` | set on edit; drives the "edited" indicator |

### 2.2 SQL

This is the single source of truth for the change. **Also paste it into `SETUP.sql`** so a from-scratch provision includes these tables (`SETUP.sql` is the schema source of truth), and apply it to the live project via the MCP server per §2.3.

```sql
-- POSTS
create table if not exists posts (
  id          bigint primary key generated always as identity,
  username    text not null,
  body        text not null,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- COMMENTS
create table if not exists comments (
  id          bigint primary key generated always as identity,
  post_id     bigint references posts(id) on delete cascade,
  username    text not null,
  body        text not null,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- Match the app's open-access model (see SETUP.sql notes on RLS)
alter table posts    disable row level security;
alter table comments disable row level security;
grant select, insert, update, delete on posts    to anon;
grant select, insert, update, delete on comments to anon;
grant usage, select on all sequences in schema public to anon;

-- Indexes for the feed sort and per-post comment lookups
create index if not exists posts_created_idx on posts (created_at desc);
create index if not exists comments_post_idx on comments (post_id, created_at);
```

Notes:
- `comments.post_id` is a FK to `posts.id` with **`ON DELETE CASCADE`** — deleting a post removes its comments automatically (same pattern as `requests.booking_id`). Still delete comments explicitly in JS too if that matches the existing defensive style, but the cascade is the safety net.
- `updated_at` is **set by the client on edit** (the PATCH sends `updated_at: new Date().toISOString()`), matching the app's no-trigger style. The UI shows an "· edited" marker when `updated_at` is meaningfully later than `created_at` (e.g. > ~2s). A DB `moddatetime` trigger is an optional alternative but is out of scope.
- No title field — a post is just a body (keep it simple). A `title` may be added later; out of scope for v1.
- No votes/points/likes table — sorting is purely chronological per the product decision.

### 2.3 Creating the tables via the Supabase MCP server

Create the tables against the live project using the Supabase MCP tools, in this order (this mirrors the MCP server's own guidance — inspect first, migrate for DDL, verify after):

1. **Inspect first.** Call `list_tables` (schema `public`) to confirm `posts`/`comments` don't already exist and to sanity-check the current structure. Optionally `list_migrations` (note: it's currently empty because the existing schema was created by pasting `SETUP.sql` into the SQL Editor, not through migrations — that's expected).
2. **Create via `apply_migration`, not `execute_sql`.** DDL must go through `apply_migration` so it's recorded as a versioned migration. Use a descriptive name such as `create_posts_and_comments`, and pass the **entire** SQL block from §2.2 (tables + RLS/grants + indexes) as one migration so anon access and indexes land atomically with the tables.
3. **The migration goes straight to the remote/production project** (there is no local Supabase stack in this repo). Treat it as production: review the SQL before applying. The SQL is idempotent (`create table if not exists`, `create index if not exists`), so re-running is safe.
4. **Verify.** After applying, call `list_tables` (verbose) and confirm: both tables exist, the `post_id` FK shows `ON DELETE CASCADE`, and columns/types match §2.1. Then run `get_advisors` (type `security`).
5. **Expect — and accept — the RLS advisor warning.** `get_advisors` will report that RLS is disabled on `posts` and `comments`. **This is intentional and consistent with the rest of the app** (see `CLAUDE.md` → Known issues; the app relies on the anon role having full CRUD, and enabling RLS without policies would break it). Document in the PR/commit that the warning is acknowledged, not a regression. Do **not** enable RLS as part of this feature.
6. **Keep `SETUP.sql` in sync.** Add the same SQL to `SETUP.sql` in the same change so fresh provisions stay correct.

> Reminder: the MCP `execute_sql` tool is fine for ad-hoc reads/inspection, but use `apply_migration` for the actual `create table` / `grant` DDL so the change is tracked.

---

## 3. `db` helper additions

Add to the `db` object, mirroring the existing method style:

```js
getPosts:     ()     => sbFetch('posts?select=*&order=created_at.desc'),
addPost:      (d)    => sbFetch('posts', {method:'POST', body:d}),
updatePost:   (id,d) => sbFetch(`posts?id=eq.${id}`, {method:'PATCH', body:d, prefer:'return=minimal'}),
deletePost:   (id)   => sbFetch(`posts?id=eq.${id}`, {method:'DELETE', prefer:'return=minimal'}),
getComments:  ()     => sbFetch('comments?select=*&order=created_at.asc'),
addComment:   (d)    => sbFetch('comments', {method:'POST', body:d}),
updateComment:(id,d) => sbFetch(`comments?id=eq.${id}`, {method:'PATCH', body:d, prefer:'return=minimal'}),
deleteComment:(id)   => sbFetch(`comments?id=eq.${id}`, {method:'DELETE', prefer:'return=minimal'}),
```

- Posts are fetched **newest-first** (`created_at.desc`).
- Comments are fetched **oldest-first** (`created_at.asc`) so each thread reads top-to-bottom naturally; the feed slices the last N for the collapsed preview (see §6).
- **Edits** are a `PATCH` sending `{body, updated_at: new Date().toISOString()}` (see §8.1), mirroring `updateBooking()`.
- Extend `loadAll()` to fetch posts + comments in the existing `Promise.all`, and call `renderPosts()` from `renderAll()`.

---

## 4. Navigation — new "Posts" tab

Add a fifth tab following the existing `showTab()` pattern and tab markup (icon span + label span, as the other tabs now use).

- New button `id="tab-posts-btn"` and panel `id="tab-posts"`; register `'posts'` in the `showTab()` array.
- Label: **Posts**. Icon: 💬 (or 📣).
- Suggested order: Calendar · Stays · **Posts** · Requests · Admin. (Order is flexible; keep Admin last since it's admin-only.)
- **Mobile bottom nav now has up to 5 items** (4 for non-admins, since Admin stays hidden). Verify the bottom nav still fits at 360px — five items at ~20% width each is fine, but confirm labels don't wrap and icons stay centered. Adjust `.tab-btn` font/padding only if needed.
- `renderPosts()` runs on load and when the Posts tab is shown (add to `showTab()` like the calendar/admin cases).

---

## 5. Feed layout (the Posts tab)

Top-to-bottom:

1. **Card title** — e.g. "💬 Cottage Board" using the existing `.card-title` style.
2. **Composer** (inline, always visible at top):
   - A `<textarea id="newPostBody">` with placeholder like "Share an update with the family…" and a **Post** button (`.btn-green`, reusing the booking form's style).
   - Validate non-empty (trim); show an inline error using the existing `.msg.error` pattern (`id="postErr"`). Enforce a soft max length (~2000 chars) and show remaining count only if that's trivial; otherwise just cap.
   - On submit: `db.addPost({username: currentUser.username, body})`, then clear the field and `loadAll()`.
3. **Feed** — `<div id="postsList">` rendered by `renderPosts()`, newest post first.

### Post card
Each post reuses card styling consistent with `.booking-item` / `.notif-item`:
- Header row: author name (color dot via `getColor(username)` for visual consistency with the calendar/bookings) + relative timestamp using the existing `timeAgo()` helper, with a subtle "· edited" marker when the post was edited (§8.1).
- Body text (preserve line breaks; escape user content — see §9 security).
- Footer row: a comment count / toggle and, for the author or an admin (`canModify`, §8), **Edit** and **Delete** buttons (`.btn-sm.btn-edit` / `.btn-sm.btn-del`). Delete mirrors `deleteBooking()` with a `confirm()` guard; Edit triggers the in-place editor (§8.1).

---

## 6. Comments — collapsed by default

Within each post:

- Comments for the post = `allComments.filter(c => c.post_id === post.id)` (already oldest-first from the query).
- **Collapsed state (default):** show only the **latest 3** comments (the last 3 of the ascending list), rendered in chronological order. If the post has **≤ 3** comments, show them all with no toggle.
- If there are more than 3, show a toggle **"View all N comments"** above the preview. Tapping it expands to the full thread (oldest→newest); the toggle becomes **"Show fewer"**.
- Track expanded posts in a module-level `Set` (e.g. `expandedPosts`) so a re-render (after adding a comment) preserves what the user opened. Do NOT auto-collapse a thread the user just expanded.
- Each comment row: color dot + author + `timeAgo()` (+ "· edited" if applicable) + body, in a compact indented style (lighter background than the post, e.g. `--sky`). Author or admin sees small **Edit** and **Delete** affordances (see §8).

### Add a comment
- Under each post, a single-line `<input>` (or small textarea) + a compact **Send** button, or submit on Enter.
- On submit: `db.addComment({post_id, username: currentUser.username, body})`, then `loadAll()`. Keep the newly-commented post's thread expanded (add its id to `expandedPosts` before reload if it was expanded, or expand on comment).
- Validate non-empty (trim).

---

## 7. Sorting rules (summary)

- **Posts:** newest `created_at` first (top of feed). No points/votes.
- **Comments:** chronological (oldest→newest) within a post. Collapsed preview shows the most recent 3.

---

## 8. Permissions — edit & delete

Reuse the app's existing simple model (a `currentUser` with `is_admin`). Define one helper, e.g. `canModify(item)` → `item.username === currentUser.username || currentUser.is_admin`, and use it to decide whether to render the Edit/Delete affordances for both posts and comments.

- **Create:** any signed-in user can create posts and comments.
- **Edit a post/comment:** its author **or** any admin (`canModify`). See §8.1 for the edit interaction.
- **Delete a post:** its author or any admin. Deleting a post also removes its comments (FK cascade; delete related comments explicitly too if matching the existing defensive pattern in `deleteBooking`). Guard with `confirm()`.
- **Delete a comment:** its author or any admin. Guard with `confirm()`.
- The Edit/Delete controls **must not render at all** for users who can't use them (don't just disable) — matches how the app hides the Remove button on other people's bookings.
- No per-post privacy — everything is visible to all family members, consistent with the rest of the app.

### 8.1 Editing interaction (in-place)

Editing happens **inline**, not in a modal (cleaner on mobile and avoids new modal markup):

- Tapping **Edit** on a post or comment replaces its body text with a `<textarea>` prefilled with the current body, plus **Save** and **Cancel** buttons (reuse `.btn-save` / `.btn-cancel` or `.btn-sm` styles).
- **Save:** validate non-empty (trim); if unchanged, just exit edit mode. Otherwise
  `db.updatePost(id, {body, updated_at: new Date().toISOString()})`
  (or `db.updateComment`), then `loadAll()`. Preserve expanded/edit state sensibly (exit edit mode for that item; keep the thread expanded).
- **Cancel:** discard changes, restore the original body, no request.
- Track the currently-editing item in module-level state (e.g. `editingPostId` / `editingCommentId`); only one item is in edit mode at a time.
- The textarea must be **≥16px font** (use the `.form-group`/existing textarea selectors so the anti-zoom rule applies — see §10).
- After an edit, show a subtle **"· edited"** marker next to the timestamp when `updated_at` is meaningfully later than `created_at` (guard against the tiny default-value delta; treat a gap of more than ~2 seconds as edited).

---

## 9. Content safety & display

- **Escape all user-generated text** (post bodies, comment bodies, usernames) before inserting into `innerHTML`. The rest of the app largely trusts admin-entered usernames, but post/comment bodies are free-form family input and must not be able to inject markup. Add a tiny `escapeHtml()` helper (or set `textContent`) and use it wherever post/comment content is rendered. This is a hard requirement, not optional.
- Preserve line breaks in bodies (e.g. `white-space: pre-wrap` on the body element) so multi-line posts read correctly — without allowing raw HTML.
- Trim leading/trailing whitespace on submit; reject empty/whitespace-only content.

---

## 10. Mobile requirements

Follow `MOBILE_REQUIREMENTS.md`. Specifically for this feature at ≤600px:

- Composer textarea and comment inputs must be **≥16px font** (use the `.form-group` selectors so the existing anti-zoom rule applies — do not introduce a bare `input` selector that loses on specificity).
- Post/comment action buttons: **≥40px** tap targets; the "View all comments" toggle is a comfortable tap target (not tiny text).
- Feed is single-column, full-width cards; no horizontal overflow at 360px. Long unbroken strings (URLs) must wrap (`overflow-wrap:anywhere` on bodies).
- Bottom nav with the new 5th item stays usable (see §4).
- Composer should not be hidden behind the fixed bottom nav; the tab panel already has bottom padding for the nav — verify.

---

## 11. States

- **Empty feed:** friendly empty state via the existing `.empty-state` pattern (e.g. "🏡 No posts yet — say hello!").
- **Empty comments:** no "0 comments" clutter; just show the add-comment input.
- **Errors:** reuse `.msg.error` / `showEl()` for composer and comment failures.
- **Loading:** matches the rest of the app (data appears after `loadAll()`; no dedicated spinner needed).

---

## 12. Acceptance checklist

Test at 360/390/414px and one desktop width:

1. [ ] A signed-in user can create a post; it appears at the **top** of the feed immediately after reload.
2. [ ] Posts are ordered newest-first.
3. [ ] A user can comment on any post; comment appears in the thread.
4. [ ] Threads with >3 comments show only the latest 3 plus a "View all N comments" toggle; expanding shows the full thread oldest→newest; collapsing returns to 3.
5. [ ] Expanded threads stay expanded across a re-render (e.g. after adding a comment).
6. [ ] Author can edit their own post/comment; a non-author non-admin sees no Edit control; an admin can edit anything. Edited items show "· edited".
7. [ ] Editing is in-place (textarea + Save/Cancel); Cancel discards; Save persists and updates the timestamp/`updated_at`.
8. [ ] Author can delete their own post/comment; a non-author non-admin sees no Delete control; an admin can delete anything.
9. [ ] Deleting a post removes its comments.
10. [ ] Post/comment bodies with `<`, `>`, `&`, or HTML render as literal text (no injection); line breaks are preserved.
11. [ ] No iOS zoom when focusing the composer, comment, or edit fields (≥16px).
12. [ ] No horizontal scroll at 360px; long URLs wrap; bottom nav (5 items) usable.
13. [ ] Existing features (calendar, stays, requests, admin) still work and their tabs still switch correctly with the new tab added.
14. [ ] Tables were created via `apply_migration` (not `execute_sql`), `SETUP.sql` was updated to match, and the RLS advisor warning was reviewed and accepted (§2.3).

## 13. Priorities

- **P0:** schema created via MCP (§2.3) + `db` methods + `loadAll`/`renderAll` wiring; Posts tab; create post; feed newest-first; add comment; collapsed comments (latest 3 + expand); HTML escaping (§9).
- **P1:** edit and delete for posts/comments with author/admin permissions (§8, §8.1); "· edited" marker; empty/error states; mobile 16px + tap targets + no overflow; preserve expanded state across re-render.
- **P2:** character counter; optional post title; swipe/pull-to-refresh.

## 14. Out of scope (v1)

- Voting / points / likes (product decision: chronological only).
- Notifications or unread badges for new posts/comments (the Requests badge stays specific to date-change requests).
- Images, file attachments, or rich text / markdown.
- @mentions, reactions, threaded (nested) replies — comments are a flat list per post.
- Edit **history / versioning** (editing itself IS in scope — see §8.1 — but we don't keep prior versions), pinning, or moderation beyond edit/delete.
- Any change to the plaintext-password / RLS-disabled security model (tracked separately in `CLAUDE.md`).
