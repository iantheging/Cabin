# 🏡 Bond Family Cottage App — Deployment Guide

How this app is hosted, updated, and used. Free on every service involved.

---

## What's Set Up

| Service   | Purpose                        | Cost        |
|-----------|--------------------------------|-------------|
| Supabase  | Shared database (all bookings) | Free forever|
| GitHub    | Source of truth for the code   | Free        |
| Netlify   | Hosts the website              | Free forever|

The whole app is a single file, `index.html`. Netlify is connected to the GitHub repo and **auto-deploys on every push** — there is no manual upload step.

---

## Updating the App (the normal workflow)

1. Edit `index.html` (or any file) and commit the change
2. **Push to the `main` branch on GitHub**
3. Netlify detects the push and redeploys automatically within a minute or two
4. Everyone gets the update on their next page load

That's it — **commit + push = live**. You can watch build status in the Netlify dashboard under **Deploys**.

---

## Using the App

The Supabase connection is **baked into `index.html`**, so there's no setup screen — the app connects automatically and goes straight to the login page on any device.

1. Open the site
2. Sign in (default admin: **Username** `Admin` · **Password** `cottage2024`)
3. **Change the admin password immediately** via Admin → Current Members → Reset PW

> If you ever need to point the app at a different Supabase project, use the **Reconnect to Supabase** link on the login screen — that override is stored in the browser only.

---

## Add Family Members

1. Sign in as Admin → go to the **Admin tab**
2. Add each family member with a username and initial password
3. Share the site URL and their login credentials with each person

---

## Add to Phone Home Screen

### iPhone (Safari):
1. Open the site in Safari
2. Tap the **Share** button (box with arrow)
3. Scroll down → tap **Add to Home Screen** → **Add**

### Android (Chrome):
1. Open the site in Chrome
2. Tap the **⋮ menu** → **Add to Home screen** → **Add**

The app opens fullscreen like a native app.

---

## First-Time Infrastructure Setup (already done — reference only)

You only need this if rebuilding from scratch or pointing at a new Supabase project.

**Supabase (database):**
1. **supabase.com** → New Project → set a database password, pick a region
2. **SQL Editor** → New Query → paste all of `SETUP.sql` → **Run**
3. **Settings → API** → copy the **Project URL** and **anon public** key
4. Put those into the `DEFAULT_SB_URL` / `DEFAULT_SB_KEY` constants near the top of the `<script>` in `index.html` (the anon key is a public, client-side key by design)

**Netlify (hosting):**
1. **netlify.com** → **Add new site → Import an existing project** → connect the GitHub repo
2. No build command needed; publish directory is the repo root (it just serves `index.html`)
3. Optional: Site configuration → Change site name for a nicer `*.netlify.app` URL, or add a custom domain

---

## Quick Reference

| Item             | Value                                      |
|------------------|--------------------------------------------|
| Deploy           | `git push` to `main` → Netlify auto-deploys|
| Default admin    | Username: `Admin` · Password: `cottage2024`|
| Change password  | Admin tab → Current Members → Reset PW     |
| Add members      | Admin tab → Add Family Member              |
| Resolve conflict | Admin tab → Conflict Resolution            |

---

*Built for the Bond Family Cottage · Mackinaw City, Michigan* 🌉
