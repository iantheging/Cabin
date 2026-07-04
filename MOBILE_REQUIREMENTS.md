# Mobile Redesign Requirements — Bond Family Cottage Booking App

**Target file:** `index.html` (single-file app: inline CSS + JS, Supabase REST backend)
**Goal:** The app must be fully usable on a phone (360–430px wide) with no pinch-zooming required to read text or tap controls. Desktop layout must continue to work unchanged or improved.

---

## 1. Constraints — DO NOT change these

1. Keep everything in the single `index.html` file. No build step, no frameworks, no external CSS/JS files.
2. Do not change any Supabase logic: `sbFetch()`, the `db` object, table names, column names, or request payloads.
3. Do not change application behavior/business logic: login flow, booking creation, conflict detection, date-change requests, admin functions all work correctly today.
4. Do not remove the existing color palette (CSS custom properties in `:root`) or the fonts (Cormorant Garamond + Nunito).
5. Preserve all existing element IDs — the JS references them by ID (`getElementById`). New wrapper elements are fine; renaming/removing IDs is not.
6. Desktop (≥900px) should look substantially the same as today.

## 2. Global / foundational requirements

### 2.1 Breakpoints
Use a mobile-first approach or, minimally, these breakpoints:
- **≤600px** — phone (primary target; test at 360px, 390px, 414px)
- **601–899px** — tablet (should degrade gracefully; no dedicated design needed)
- **≥900px** — desktop (current design)

### 2.2 Minimum text sizes (phone)
No pinch-zoom should ever be needed to read text. On ≤600px screens:
- Body/content text: **≥ 0.875rem (14px)**
- Secondary/meta text (dates, timestamps, legends): **≥ 0.75rem (12px)**
- Nothing anywhere below **0.6875rem (11px)**. This currently fails in many places: `.booking-chip` (0.57rem on mobile), `.holiday-label` (0.57rem), `.notif-dot` (0.62rem), `.cal-day-name` (0.67rem), `.admin-tag`/`.role-tag` (0.66rem), `.conflict-badge` (0.68rem). All must be raised or redesigned (see calendar section for chips).

### 2.3 Prevent iOS input zoom
All `<input>`, `<select>`, `<textarea>` must have `font-size: 16px` (1rem) or larger on phones. iOS Safari auto-zooms the viewport when focusing any input with font-size < 16px. Current inputs are 0.92rem — this is a P0 fix. Apply globally, not per-input.

### 2.4 Touch targets
Every tappable control must have a hit area of **≥ 44×44px** on phones:
- `.btn-sm` (Edit / Remove / Accept / Decline / Request Change / Reset PW): currently ~24px tall. Increase padding to reach ≥40px height minimum with adequate horizontal padding, or restructure rows so buttons can be full-width/larger (see §5).
- `.cal-nav-btn` (month arrows): currently 32×32. Make ≥44×44.
- Calendar day cells: already ≥44px tall — keep them that way.
- Tab buttons: ensure ≥44px height.

### 2.5 Touch vs hover
- No information or affordance may be available *only* on hover. Specifically: calendar booking chips use `title=` tooltips to show full name + dates — invisible on touch. Replace per §4.
- Add `:active` visual feedback (e.g., slight scale/background change) to all buttons and tappable cells.
- Guard hover styles with `@media (hover: hover)` where they cause "sticky hover" on touch (buttons that stay highlighted after tap).

### 2.6 Safe areas
The page already sets `viewport-fit=cover`. Add `env(safe-area-inset-*)` padding to the sticky header top and `main` bottom padding so content isn't hidden behind the iPhone notch/home indicator.

### 2.7 No horizontal scroll
At 360px wide, `document.documentElement.scrollWidth` must equal the viewport width on every screen (setup, login, all 4 tabs, all 4 modals). Nothing may overflow horizontally.

---

## 3. Header & tab bar (phone)

### 3.1 Header
Current: brand (icon + two-line title) left, user badge + admin tag + Sign Out button right; wraps awkwardly ≤600px.
- On ≤600px: shrink `.header-title` to ~1.15rem, hide or shorten `.header-sub`, and keep everything on one row. The user badge may show a shortened name. Sign Out can become an icon-size button (min 44px hit area) or move elsewhere, but must stay reachable.
- Header (sticky) must not consume more than ~64px + safe-area of vertical space on phones. The decorative `.bridge-strip` SVG may shrink to ~16px or be hidden on ≤600px.

### 3.2 Tabs
Current: 4 buttons (`🗓 Calendar / 📋 All Stays / 🔔 Requests / ⚙️ Admin`) at `flex:1`, 0.74rem text on mobile — cramped and truncated.
- On ≤600px, convert the tab bar to a **fixed bottom navigation bar** (standard mobile pattern): icon on top, short label underneath (Calendar / Stays / Requests / Admin), each ≥44px tall, safe-area padding at the bottom. `main` needs matching bottom padding so content isn't hidden behind it.
- The notification badge (`#notifDot`) must remain visible on the Requests item and not overlap the label.
- Admin tab stays hidden for non-admins exactly as now (`style.display` toggling on `#tab-admin-btn` — keep that ID on whatever element becomes the admin nav item).
- On desktop, keep the current top tab design.

---

## 4. Calendar (P0 — the most important section)

The calendar must be **fully functional and readable on a phone without zooming**. The current design puts name-chips inside 7-across grid cells; at 360px each cell is ~48px wide, chips render at ~9px and truncate to nothing. This cannot be fixed by font-size alone — the cell content must be redesigned on phones.

### 4.1 Phone calendar cell design (≤600px)
- Keep the 7-column month grid (users think in weeks), but **replace text chips inside cells with colored indicators**:
  - For each booking covering that day, render a **horizontal color bar** (full cell width, ~5px tall, 2px gap, rounded ends) in the member's color (`getColor(username)`), max 3 bars + a "+N" overflow indicator if more.
  - No usernames inside cells on phones.
- Day number (`.cal-date`): ≥0.8rem, bold — readable at arm's length.
- Day-of-week header row: 12px minimum; use single letters (S M T W T F S) if needed to fit.
- Holiday indication: keep the gold cell background/border, but **drop the text label inside the cell** on phones (0.57rem text is unreadable). Holiday name appears in the day detail panel (§4.2) instead.
- Cells: min-height ~52–60px, minimal padding, no horizontal overflow at 360px.

### 4.2 Day detail panel (replaces hover tooltips)
Because chips no longer show names on phones, add a **day detail panel** directly below the calendar grid (above the legend):
- When the user taps a day, in addition to the existing check-in/check-out selection behavior (`clickCalDay()` — keep it exactly as is), the panel shows that day's info: full date, holiday name if any, and each booking covering that day as a row: color dot + username + date range (`nice(start) → nice(end)` + nights).
- If no bookings that day: show "No reservations" in the panel.
- The panel updates on every day tap and is also useful on desktop (render it there too — it replaces reliance on `title` tooltips, which should be kept as a desktop nicety but never be the only path to the info).
- Tapping a past day (not clickable for selection today) should still show the detail panel — attach a separate listener or extend the existing one; do NOT make past days selectable for booking.

### 4.3 Selection UX on phone
- Keep the tap-to-select check-in → tap-again check-out flow.
- Selected/in-range styling must be clearly visible (already exists: `.cal-selected`, `.cal-in-range` — verify contrast holds with the new bar indicators).
- Show a small persistent hint of current selection state near the calendar (e.g., "Selecting check-out — tap a date after Jul 10"), since on a phone the form inputs may be scrolled off-screen when the calendar is in view.

### 4.4 Month navigation
- Prev/next buttons ≥44×44px, positioned so month label doesn't collide.
- Optional (P2): horizontal swipe on the grid to change months.

### 4.5 Legend
- Legend rows ≥12px text, wrap freely. Keep the member-color mapping and holiday swatch.

---

## 5. Booking lists — "My Reservations", "All Stays", Admin lists (≤600px)

Current `.booking-item` is a single flex row: dot + name/dates + right-aligned action buttons. On phones the buttons get crushed and wrap unpredictably.

- Restack each item on ≤600px: **info block on top (dot + name + dates), action buttons in a row below**, buttons sized ≥40px tall with comfortable spacing (they can share a row: Edit / Remove fit side by side).
- Date text (`.booking-dates`) ≥0.8rem.
- Conflict badge must not overlap or push buttons off-screen; place it inline with the name or as its own line.
- Same treatment applies to `.user-item` rows in Admin and `.notif-item` action rows (Accept/Decline buttons ≥40px tall, side by side, full width available).

## 6. Forms (booking form, login, setup, admin add-member)

- All inputs 16px font (§2.3), height ≥44px.
- `.form-row` already stacks vertically ≤600px — keep.
- Native `<input type="date">` is fine on mobile; keep it.
- Primary action buttons (`.btn-primary`, `.btn-green`, `.btn-save`, `.btn-cancel`): full-width on ≤600px, ≥48px tall.
- Error/success `.msg` text ≥0.85rem.

## 7. Modals (≤600px)

All 4 modals (`#editModal`, `#requestModal`, `#declineModal`, `#resetModal`):
- Convert to **bottom-sheet style** on phones: anchored to bottom of viewport, full width, rounded top corners, slide-up transition. (Desktop keeps the centered card.)
- Modal content must scroll internally (`max-height` + `overflow-y:auto`) — critical for `#requestModal` (the tallest) when the on-screen keyboard is open.
- Action buttons ≥48px tall, full width of the sheet.
- Keep the existing tap-outside-to-close behavior and `openModal`/`closeModal` API.
- Respect bottom safe-area inset inside the sheet.

## 8. Setup & login screens

- Mostly fine already (centered cards, stack naturally). Verify at 360px: card padding may shrink (e.g., 24px → 20px), inputs to 16px font, buttons ≥48px.
- Setup step text (0.83rem) is acceptable; ensure `code` snippets wrap rather than overflow.

## 9. Notifications / Requests tab

- `.notif-item` text sizes: body ≥0.85rem, dates ≥0.8rem, timestamps ≥0.75rem.
- Status pills ≥0.72rem is currently borderline — raise to ≥0.75rem.
- Accept/Decline buttons per §5.

## 10. Acceptance checklist

Test in browser dev-tools device emulation at **360×740, 390×844, 414×896**, plus one desktop width (1280px). For each:

1. [ ] No horizontal scrolling on any screen or tab.
2. [ ] No text below 11px computed size anywhere; body content ≥14px.
3. [ ] Focusing any input on iOS-sized viewport does not zoom the page (all inputs ≥16px font).
4. [ ] Calendar: day numbers and all indicators readable at 360px without zoom; tapping any day shows the detail panel with names and date ranges; check-in/check-out tap-selection still works; month nav buttons easy to hit.
5. [ ] Every button/tap target ≥ ~44px hit area (verify with dev-tools inspection).
6. [ ] Bottom nav visible on all tabs, doesn't cover content, badge shows pending request count.
7. [ ] Each modal opens as a bottom sheet, scrolls internally, buttons reachable with keyboard open.
8. [ ] Booking list items: buttons never overlap or overflow; conflict badge visible.
9. [ ] Desktop (1280px): layout matches current design (top tabs, centered modals, chips with names in calendar cells are OK to keep on desktop, but the day-detail panel exists there too).
10. [ ] All existing functionality still works: login, reserve dates (via calendar taps and via date inputs), edit/remove booking, request date change, accept/decline with reply, admin add/remove user, reset password, conflict display.

## 11. Priorities

- **P0:** §2.3 input zoom fix, §4 calendar redesign + day detail panel, §2.7 no horizontal scroll, §3.2 bottom nav, §2.2 text sizes.
- **P1:** §5 booking list restack, §7 bottom-sheet modals, §2.4 touch targets, §3.1 header compaction.
- **P2:** §2.5 hover guards/active states, §2.6 safe areas, §4.4 swipe month nav, §8 polish.

## 12. Out of scope

- No changes to Supabase schema, auth model, or plaintext-password handling (known limitation, separate concern).
- No PWA/service-worker/offline work.
- No dark mode.
- The `fmt()` timezone quirk (`toISOString` can shift dates across midnight UTC) is a pre-existing bug — do not attempt to fix it as part of this redesign.
