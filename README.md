# 🏡 Mackinaw Cottage

A shared booking calendar for the family cottage in Mackinaw City, Michigan. Built as a single HTML file with a Supabase backend — no app store, no install, just a link.

---

## Features

- **Booking calendar** — click dates to reserve your stay, see the whole family's schedule at a glance
- **Conflict detection** — overlapping bookings are flagged automatically
- **Date-change requests** — send a message asking another family member to shift their dates, they can accept or decline
- **Admin panel** — manage family members, reset passwords, resolve conflicts
- **Works as a home screen app** — add to iPhone or Android for a native-app feel

---

## Tech Stack

| Layer    | Technology                          |
|----------|-------------------------------------|
| Frontend | Vanilla HTML, CSS, JavaScript       |
| Backend  | [Supabase](https://supabase.com) (PostgreSQL + REST API) |
| Hosting  | [Netlify](https://netlify.com) (static file deploy) |
| Fonts    | Cormorant Garamond + Nunito (Google Fonts) |

No frameworks. No build step. One file.

---

## Setup

See [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) for full step-by-step instructions.

**Quick version:**
1. Create a free [Supabase](https://supabase.com) project and run `SETUP.sql` in the SQL editor
2. Drag `cottage-booking.html` onto [Netlify](https://netlify.com)
3. Open the site, paste in your Supabase URL and anon key
4. Sign in as `Admin` / `cottage2024` and change the password immediately
5. Add family members from the Admin tab and share the link

---

## Updating

When a new version of `cottage-booking.html` is available:
1. Go to Netlify → your site → **Deploys**
2. Drag and drop the new file
3. Done — all users get the update instantly

---

## Default Credentials

| Field    | Value          |
|----------|----------------|
| Username | `Admin`        |
| Password | `cottage2024`  |

> **Change the admin password immediately after first login.**

---

*Mackinaw City, Michigan — where Lake Huron meets Lake Michigan* 🌉
