# Database Debugging Scripts

These scripts help you diagnose and fix signup errors related to your Supabase database.

## Setup

Before running these scripts, you need to add your Supabase service role key to your `.env` file:

1. Go to [Supabase Dashboard](https://supabase.com/dashboard) → Your Project → Settings → API
2. Copy the `service_role` key (⚠️ **Keep this secret!**)
3. Add it to your `.env` file:

```env
PUBLIC_SUPABASE_URL=https://eqzmhofuyfzxwqeayymx.supabase.co
PUBLIC_SUPABASE_ANON_KEY=sb_publishable_...
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
```

## Available Scripts

### 1. Check Database State

```bash
npm run check:db
```

This script checks:
- ✅ If the `profiles` table exists
- ✅ If the `handle_new_user()` trigger function exists
- ✅ Existing profiles and usernames
- ✅ If the `brand_profiles` table exists
- ✅ RLS (Row Level Security) policies

**When to use:** Run this first to get an overview of your database state.

### 2. Verify Migrations

```bash
npm run check:migrations
```

This script verifies:
- ✅ Profiles table structure
- ✅ Brand profiles table
- ✅ Posts table
- ✅ Trigger existence (with SQL to check manually)
- ✅ Username uniqueness constraint

**When to use:** Run this to verify that all migrations have been applied correctly.

## Common Issues & Solutions

### Issue 1: "500 Internal Server Error" on Signup

**Symptoms:** Browser console shows a 500 error when trying to sign up.

**Likely Causes:**
1. Database trigger `handle_new_user()` is missing or has errors
2. Migrations haven't been run on your Supabase cloud instance
3. Username conflict (duplicate username)

**Solutions:**

1. **Run the verification scripts:**
   ```bash
   npm run check:migrations
   npm run check:db
   ```

2. **If trigger is missing, run migrations in Supabase Dashboard:**
   - Go to Supabase Dashboard → SQL Editor
   - Run these migrations in order:
     - `supabase/migrations/001_initial_schema.sql`
     - `supabase/migrations/003_recreate_auth_trigger.sql`
     - `supabase/migrations/004_fix_schema_search_path.sql`

3. **Check browser console for detailed error:**
   - Open DevTools (F12)
   - Go to Console tab
   - Try signing up
   - Look for "Signup error:" message with details

### Issue 2: "Username already taken" Error

**Symptoms:** Error message appears when trying to use a username.

**Solution:** The client-side validation now checks for duplicate usernames in real-time! Just try a different username.

### Issue 3: Tables Don't Exist

**Symptoms:** `check:db` reports tables are missing.

**Solution:**
1. Go to Supabase Dashboard → SQL Editor
2. Run `supabase/migrations/001_initial_schema.sql`
3. Run all other migrations in order
4. Run `npm run check:db` again to verify

## Client-Side Username Validation

The signup form now includes:
- ✅ **Real-time availability check** - Checks if username is taken as you type
- ✅ **Debounced validation** - Waits 500ms after you stop typing to avoid excessive checks
- ✅ **Visual feedback** - Shows spinner while checking, success/error states
- ✅ **Minimum length** - Enforces 3 character minimum
- ✅ **Format validation** - Only allows letters, numbers, hyphens, and underscores

## Need More Help?

If you're still experiencing issues:

1. Check the browser console for detailed error messages
2. Run both diagnostic scripts
3. Verify all migrations have been applied in Supabase Dashboard
4. Check the Supabase Dashboard → Logs for server-side errors
