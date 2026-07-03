# 🏡 Mackinaw Cottage App — Deployment Guide

Everything you need to get this live in about 15 minutes, for free.

---

## What You'll Set Up

| Service   | Purpose                        | Cost        |
|-----------|--------------------------------|-------------|
| Supabase  | Shared database (all bookings) | Free forever|
| Netlify   | Hosts the website              | Free forever|

---

## Step 1 — Set Up Supabase (the database)

1. Go to **supabase.com** → click **Start your project** → sign up with GitHub or email
2. Click **New Project**, give it a name like `mackinaw-cottage`, set a database password, pick any region
3. Wait ~2 minutes for it to provision
4. Go to **SQL Editor** (left sidebar) → click **New Query**
5. Open the `SETUP.sql` file included with this app, paste the entire contents into the editor, and click **Run**
6. Go to **Settings → API** (left sidebar):
   - Copy the **Project URL** (looks like `https://abcdefgh.supabase.co`)
   - Copy the **anon public** key (long string starting with `eyJ...`)

---

## Step 2 — Deploy to Netlify (the website)

1. Go to **netlify.com** → sign up (free)
2. From your dashboard, click **Add new site → Deploy manually**
3. Drag and drop the `index.html` file onto the upload area
4. Netlify gives you a URL like `https://random-name-123.netlify.app`

**Optional — give it a nicer URL:**
- In Netlify: Site configuration → Change site name → e.g. `mackinaw-cottage`
- That gives you: `https://mackinaw-cottage.netlify.app`
- Or buy a custom domain (~$12/yr) like `mackinawcottage.com`

---

## Step 3 — Connect the App to Supabase

1. Open your Netlify URL in a browser
2. You'll see the one-time setup screen — paste in your Supabase **Project URL** and **anon key**
3. Click **Save & Connect**
4. Sign in with: **Username:** `Admin` · **Password:** `cottage2024`
5. **Change the admin password immediately** via Admin → Reset PW

> Each family member only needs to do the Supabase setup once on each new device/browser.
> After that, it goes straight to the login screen.

---

## Step 4 — Add Family Members

1. Sign in as Admin → go to **Admin tab**
2. Add each family member with a username and initial password
3. Share the Netlify URL and their login credentials with each person

---

## Step 5 — Add to Phone Home Screen

### iPhone (Safari):
1. Open the site in Safari
2. Tap the **Share** button (box with arrow)
3. Scroll down → tap **Add to Home Screen**
4. Name it "Cottage" → tap **Add**

### Android (Chrome):
1. Open the site in Chrome
2. Tap the **⋮ menu** → tap **Add to Home screen**
3. Tap **Add**

The app will open fullscreen like a native app with its own icon.

---

## Updating the App

If you get an updated version of `index.html`:
1. Go to Netlify → your site → **Deploys**
2. Drag and drop the new file
3. Done — all users get the update automatically

---

## Quick Reference

| Item             | Value                                      |
|------------------|--------------------------------------------|
| Default admin    | Username: `Admin` · Password: `cottage2024`|
| Change password  | Admin tab → Current Members → Reset PW     |
| Add members      | Admin tab → Add Family Member              |
| Resolve conflict | Admin tab → Conflict Resolution            |

---

*Built for the Mackinaw Family Cottage · Mackinaw City, Michigan* 🌉
