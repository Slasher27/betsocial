# BetChat — Architecture Documentation

This document provides a comprehensive overview of the BetChat application architecture, data flows, and working relationships between components.

## Tech Stack

- **Frontend:** SvelteKit + Svelte 5 (with runes API)
- **Backend:** Supabase (Authentication, Database, Storage)
- **Styling:** Tailwind CSS 4.x + DaisyUI + custom dark theme
- **Rich Text:** TipTap editor with extensions
- **TypeScript:** Full type safety throughout

---

## File Structure

```
C:\Websites\Betchat\App\
├── src/
│   ├── app.d.ts                    # TypeScript globals & app types
│   ├── app.html                    # HTML shell
│   ├── hooks.server.ts             # Server-side request interceptor
│   ├── lib/
│   │   ├── components/
│   │   │   ├── TipTapEditor.svelte    # Rich text editor
│   │   │   └── TipTapRenderer.svelte  # Read-only content renderer
│   │   ├── supabase/
│   │   │   ├── client.ts           # Browser Supabase client
│   │   │   └── server.ts           # Server Supabase client factory
│   │   └── types/
│   │       └── database.ts         # TypeScript database schema
│   └── routes/
│       ├── +layout.server.ts       # Root layout server load
│       ├── +layout.svelte          # Root layout with nav
│       ├── +page.svelte            # Landing page
│       ├── (app)/                  # Protected routes group
│       │   ├── bookmarks/
│       │   ├── dashboard/
│       │   │   └── posts/
│       │   │       ├── new/
│       │   │       └── [postId]/edit/
│       │   ├── feed/
│       │   └── settings/
│       ├── (public)/               # Public routes group
│       │   ├── explore/
│       │   ├── [brandSlug]/
│       │   │   └── [postSlug]/
│       │   └── u/[username]/
│       │       └── [postSlug]/
│       └── auth/
│           ├── callback/
│           ├── login/
│           ├── logout/
│           └── signup/
│               └── brand/
├── supabase/
│   └── migrations/                 # Database schema migrations
└── [config files]
```

### Key Architectural Decisions

- **Route Groups**: Uses `(app)` and `(public)` folders for logical separation without affecting URL structure
- **Single Root Layout**: No route-specific layouts; root layout handles all navigation variations
- **Lib Organization**: Shared code in `$lib` with clear separation (components, supabase clients, types)

---

## Authentication Architecture

### 1. Server-Side Request Handling (`hooks.server.ts`)

Runs on **every request** before any route handler:

```typescript
export const handle: Handle = async ({ event, resolve }) => {
    // 1. Create Supabase client with cookie handling
    event.locals.supabase = createSupabaseServerClient(event);

    // 2. Provide safe session getter to all routes
    event.locals.safeGetSession = async () => {
        const { data: { user }, error } = await event.locals.supabase.auth.getUser();
        if (error || !user) return { session: null, user: null };

        const { data: { session } } = await event.locals.supabase.auth.getSession();
        return { session, user };
    };

    // 3. Allow Supabase headers through
    return resolve(event, {
        filterSerializedResponseHeaders(name) {
            return name === 'content-range' || name === 'x-supabase-api-version';
        }
    });
};
```

### 2. Supabase Client Creation

**Server Client** (`lib/supabase/server.ts`):
```typescript
// Creates server client with SSR cookie support
export const createSupabaseServerClient = (event) => {
    return createServerClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY, {
        cookies: {
            getAll: () => event.cookies.getAll(),
            setAll: (cookiesToSet) => {
                cookiesToSet.forEach(({ name, value, options }) => {
                    event.cookies.set(name, value, { ...options, path: '/' });
                });
            }
        }
    });
};
```

**Browser Client** (`lib/supabase/client.ts`):
```typescript
// Simple browser client for client-side operations
export const supabase = createBrowserClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY);
```

### 3. Root Layout Authentication (`routes/+layout.server.ts`)

Loads session data for all routes:

```typescript
export const load: LayoutServerLoad = async ({ locals: { safeGetSession, supabase }, depends }) => {
    depends('supabase:auth'); // Invalidation key
    const { session } = await safeGetSession();

    // Load profile and determine account type
    if (session) {
        const { data: profile } = await supabase
            .from('profiles')
            .select('account_type, username')
            .eq('id', session.user.id)
            .single();

        // Build profile URL based on account type
        const isBrand = profile?.account_type === 'brand';
        const profileUrl = isBrand
            ? `/${brandProfile.slug}`
            : `/u/${profile.username}`;

        return { session, isBrand, profileUrl };
    }

    return { session: null, isBrand: false, profileUrl: null };
};
```

### 4. Client-Side Auth State Sync (`routes/+layout.svelte`)

Listens for auth changes and updates UI:

```typescript
onMount(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange(() => {
        invalidate('supabase:auth'); // Triggers layout reload
    });
    return () => subscription.unsubscribe();
});
```

### 5. Authentication Routes

**Login** (`auth/login/+page.svelte`):
- Client-side form using `supabase.auth.signInWithPassword()`
- On success: `invalidate('supabase:auth')` + `goto('/feed')`

**Signup** (`auth/signup/+page.svelte`):
- Uses `supabase.auth.signUp()` with email confirmation
- Metadata passed: `account_type`, `username`, etc.

**Brand Signup** (`auth/signup/brand/+page.svelte`):
- Similar to user signup but includes `brand_name`, `brand_slug` in metadata
- Database trigger creates both `profiles` and `brand_profiles` records

**Callback** (`auth/callback/+server.ts`):
```typescript
export const GET: RequestHandler = async ({ url, locals: { supabase } }) => {
    const code = url.searchParams.get('code');
    if (code) {
        await supabase.auth.exchangeCodeForSession(code);
    }
    throw redirect(303, '/feed');
};
```

**Logout** (`auth/logout/+server.ts`):
```typescript
export const POST: RequestHandler = async ({ locals: { supabase } }) => {
    await supabase.auth.signOut();
    throw redirect(303, '/');
};
```

---

## Route Architecture

### (app) Group - Protected Routes

All routes in `(app)` require authentication. Protection is enforced in each page's server load function:

**Routes:**
- `/bookmarks` - User's saved posts
- `/dashboard` - User/Brand dashboard with post management
- `/dashboard/posts/new` - Create new post
- `/dashboard/posts/[postId]/edit` - Edit existing post
- `/feed` - Personalized feed of followed brands
- `/settings` - Account settings

**Protection Pattern:**
```typescript
export const load: PageServerLoad = async ({ locals: { safeGetSession } }) => {
    const { session } = await safeGetSession();
    if (!session) {
        throw redirect(303, '/auth/login');
    }
    // ... load protected data
};
```

### (public) Group - Public Routes

Accessible without authentication, but may show different UI when logged in:

**Routes:**
- `/explore` - Browse all brands
- `/[brandSlug]` - Brand profile page
- `/[brandSlug]/[postSlug]` - Brand post detail
- `/u/[username]` - User profile page
- `/u/[username]/[postSlug]` - User post detail

**Conditional Features Pattern:**
```typescript
export const load: PageServerLoad = async ({ params, locals: { safeGetSession, supabase } }) => {
    const { session } = await safeGetSession();

    // Always load public data
    const { data: post } = await supabase.from('posts')...;

    // Conditionally load user-specific data
    let isBookmarked = false;
    if (session) {
        const { data } = await supabase.from('bookmarks')
            .select()
            .eq('user_id', session.user.id)
            .eq('post_id', post.id);
        isBookmarked = !!data;
    }

    return { post, isBookmarked, session };
};
```

---

## Layout and Page Relationship

### Single Root Layout Architecture

```
+layout.server.ts (loads session, profile data)
     ↓
+layout.svelte (renders nav based on auth state, sets up auth listener)
     ↓
Pages inherit this context via $page.data
```

**No Group-Specific Layouts:** The root layout handles all UI variations:

```svelte
<!-- +layout.svelte -->
{#if data?.session}
    <!-- Authenticated navbar with dropdown menu, notifications -->
    <nav class="navbar">...</nav>
{:else}
    <!-- Public navbar with login/signup buttons -->
    <nav class="navbar">
        <a href="/auth/login">Login</a>
        <a href="/auth/signup">Sign Up</a>
    </nav>
{/if}

<main>
    {@render children()}  <!-- Page content -->
</main>
```

**Data Flow:**
1. `+layout.server.ts` runs first, returns `{ session, isBrand, profileUrl }`
2. `+layout.svelte` receives this in `$props()`, passes to navigation
3. Individual pages access via their own `load` functions or `$page.data`

---

## Server-Client Interaction

### Hybrid Rendering Model

#### Server Load Functions (`+page.server.ts`)
Runs on server, data available on initial page load:

```typescript
export const load: PageServerLoad = async ({ locals: { supabase, safeGetSession } }) => {
    const { session } = await safeGetSession();
    const { data: posts } = await supabase.from('posts')
        .select('*, author:profiles(*), brand:brand_profiles(*)')
        .eq('status', 'published')
        .order('published_at', { ascending: false });

    return { posts };
};
```

#### Server Actions (`+page.server.ts`)
Form submissions with progressive enhancement:

```typescript
export const actions: Actions = {
    default: async ({ request, locals: { supabase, safeGetSession } }) => {
        const { session } = await safeGetSession();
        if (!session) return fail(401);

        const formData = await request.formData();
        const title = formData.get('title') as string;

        const { error } = await supabase.from('posts').insert({ title, author_id: session.user.id });

        if (error) return fail(400, { error: error.message });
        throw redirect(303, '/dashboard');
    }
};
```

#### Client-Side Reactivity (`+page.svelte`)
Interactive features using browser Supabase client:

```typescript
let { data } = $props<{ data: PageData }>();
let bookmarked = $state(data.isBookmarked);

async function toggleBookmark() {
    // Client-side Supabase call
    const { error } = await supabase.from('bookmarks')
        .insert({ user_id: data.session.user.id, post_id: data.post.id });

    if (!error) {
        bookmarked = true;
        await invalidateAll(); // Re-run server load functions
    }
}
```

#### Progressive Enhancement with Forms
```svelte
<form method="POST" use:enhance={() => {
    saving = true;
    return async ({ update }) => {
        await update();
        saving = false;
    };
}}>
    <!-- Form works without JS, enhanced with JS -->
</form>
```

### Key Patterns

- **Server-first**: Initial data always from server
- **Client enhancement**: Interactive features use client-side Supabase
- **Optimistic updates**: UI updates immediately, revalidates in background
- **Form enhancement**: Progressive enhancement via SvelteKit's `enhance` action

---

## Database Schema

### Core Tables

**profiles** (extends auth.users):
```typescript
{
    id: UUID (FK → auth.users)
    username: TEXT UNIQUE
    display_name: TEXT
    avatar_url: TEXT
    bio: TEXT
    account_type: 'user' | 'brand'
    country_code: TEXT
    betting_interests: TEXT[]
}
```

**brand_profiles** (1:1 with brand profiles):
```typescript
{
    id: UUID (FK → profiles)
    brand_name: TEXT
    slug: TEXT UNIQUE
    logo_url: TEXT
    banner_url: TEXT
    description: TEXT
    website_url: TEXT
    is_verified: BOOLEAN
    categories: TEXT[]
    stripe_account_id: TEXT
    follower_count: INTEGER (denormalized)
}
```

**posts** (content from users or brands):
```typescript
{
    id: UUID
    brand_id: UUID (FK → brand_profiles, nullable)
    author_id: UUID (FK → profiles)
    title: TEXT
    slug: TEXT
    content: JSONB (TipTap JSON)
    excerpt: TEXT
    status: 'draft' | 'published' | 'archived'
    categories: TEXT[]
    like_count: INTEGER (denormalized)
    published_at: TIMESTAMPTZ
    UNIQUE(brand_id, slug)
}
```

**follows** (user → brand relationships):
```typescript
{
    follower_id: UUID (FK → profiles)
    brand_id: UUID (FK → brand_profiles)
    subscription_tier: 'free' | 'paid'
    PRIMARY KEY (follower_id, brand_id)
}
```

**bookmarks** (user saved posts):
```typescript
{
    user_id: UUID (FK → profiles)
    post_id: UUID (FK → posts)
    PRIMARY KEY (user_id, post_id)
}
```

**Additional tables**: comments, reactions, notifications (see migration file)

### TypeScript Type System

**database.ts** provides full type safety:

```typescript
export interface Database {
    public: {
        Tables: {
            profiles: {
                Row: { /* Full row type */ },
                Insert: { /* Insert type with optionals */ },
                Update: { /* Update type all optional */ }
            },
            // ... all other tables
        }
    }
}
```

**Usage:**
```typescript
import type { Database } from '$lib/types/database';

const supabase = createSupabaseServerClient<Database>(event);

// Fully typed queries
const { data } = await supabase
    .from('posts')
    .select('id, title, author:profiles(username)')
    .eq('status', 'published'); // TypeScript knows valid columns
```

### Database Triggers & Functions

**Auto-create profile on signup:**
```sql
CREATE FUNCTION handle_new_user() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, username, account_type) VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
        COALESCE((NEW.raw_user_meta_data->>'account_type')::account_type, 'user')
    );

    IF NEW.raw_user_meta_data->>'account_type' = 'brand' THEN
        INSERT INTO brand_profiles (id, brand_name, slug) VALUES (
            NEW.id,
            NEW.raw_user_meta_data->>'brand_name',
            NEW.raw_user_meta_data->>'brand_slug'
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Denormalized follower counts:**
```sql
CREATE FUNCTION update_follower_count() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE brand_profiles SET follower_count = follower_count + 1 WHERE id = NEW.brand_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE brand_profiles SET follower_count = follower_count - 1 WHERE id = OLD.brand_id;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

---

## Component Architecture

### UI Component Stack

- **Tailwind CSS 4.x** - Utility-first styling
- **DaisyUI** - Component library with custom dark theme
- **@tailwindcss/typography** - Prose styling for articles
- **@tailwindcss/forms** - Form styling

### Key Components

#### TipTapEditor.svelte (Rich Text Editor)

Full-featured WYSIWYG editor with:
- StarterKit (bold, italic, headings, lists, etc.)
- TextStyle + Color (text color picker)
- Highlight (background color)
- TextAlign (left, center, right)
- Image (URL-based)
- Link support
- Toolbar with all controls
- Bindable content (JSON format)

```typescript
let { content = $bindable() } = $props();

let editor: Editor | undefined;

onMount(() => {
    editor = new Editor({
        content,
        onUpdate: ({ editor }) => {
            content = editor.getJSON();
        }
    });
});
```

#### TipTapRenderer.svelte (Read-Only Display)

Renders TipTap JSON as styled HTML:
- Same extensions as editor
- Non-editable
- Custom styling for article layout
- Handles images, lists, quotes, alignment

### UI Patterns

**Responsive Navigation:**
- Desktop: Horizontal menu with icons
- Mobile: Hamburger dropdown
- Consistent across authenticated/public states

**Card-Based Layouts:**
```svelte
<div class="card bg-base-200">
    <div class="card-body">
        <h2 class="card-title">{brand.name}</h2>
        <p>{brand.description}</p>
        <div class="card-actions">
            <button class="btn btn-primary">Follow</button>
        </div>
    </div>
</div>
```

**Stat Displays:**
```svelte
<div class="stat bg-base-200">
    <div class="stat-title">Total Posts</div>
    <div class="stat-value">{posts.length}</div>
</div>
```

---

## Key Data Flows

### Authentication Flow
```
User submits login form
    ↓ (client)
supabase.auth.signInWithPassword()
    ↓ (Supabase)
Sets auth cookies
    ↓ (client)
invalidate('supabase:auth')
    ↓ (SvelteKit)
Re-runs +layout.server.ts load()
    ↓ (server)
Loads session, profile, determines account type
    ↓ (client)
Layout re-renders with authenticated nav
    ↓
goto('/feed')
```

### Post Creation Flow
```
User fills post form
    ↓ (client)
Submit with use:enhance
    ↓ (server)
+page.server.ts actions.default()
    ↓
Verify session via safeGetSession()
    ↓
Get user profile to determine if brand
    ↓
Insert into posts table with:
  - brand_id (if brand) or null (if user)
  - author_id (always user ID)
  - content (TipTap JSON)
    ↓ (RLS)
Policy check: auth.uid() = author_id
    ↓ (server)
throw redirect(303, '/dashboard')
    ↓ (client)
Navigate to dashboard
```

### Feed Loading Flow
```
Navigate to /feed
    ↓ (server)
+page.server.ts load()
    ↓
Check authentication (redirect if not logged in)
    ↓
Query posts with joins:
  SELECT posts.*,
         author:profiles(*),
         brand:brand_profiles(*)
  WHERE status = 'published'
  ORDER BY published_at DESC
    ↓ (RLS)
Row-level security allows all published posts
    ↓ (server)
Return { posts }
    ↓ (client)
Render feed with post cards
```

### Bookmark Toggle Flow
```
User clicks bookmark button
    ↓ (client)
Check if logged in (redirect if not)
    ↓
Client-side Supabase call:
  supabase.from('bookmarks').insert()
    ↓ (RLS)
Policy check: auth.uid() = user_id
    ↓ (client)
Update local state optimistically
    ↓
await invalidateAll()
    ↓ (server)
Re-run current page load function
    ↓ (client)
UI reflects saved state
```

### Profile/Brand Page Flow
```
Navigate to /[brandSlug] or /u/[username]
    ↓ (server)
+page.server.ts load()
    ↓
Query brand_profiles or profiles by slug/username
    ↓
Query posts by brand_id/author_id
    ↓
If logged in:
  - Check if following (for brands)
  - Load bookmark status
    ↓ (server)
Return { brand/profile, posts, isFollowing, session }
    ↓ (client)
Render profile with conditional follow button
```

---

## Architecture Highlights

### Security
- **Row-Level Security (RLS)** on all tables
- **Server-side authentication checks** in all protected routes
- **SECURITY DEFINER functions** for privileged operations
- **No direct password handling** (Supabase Auth manages this)

### Performance
- **Denormalized counts** (follower_count, like_count) for faster queries
- **Indexed queries** (slug lookups, status filters)
- **Server-side rendering** for SEO and initial load performance
- **Client-side navigation** for instant page transitions

### Type Safety
- **Full TypeScript** throughout application
- **Generated database types** from Supabase schema
- **Typed Supabase queries** catch errors at compile time
- **Type-safe form actions** with proper validation

### Scalability
- **Database triggers** handle data consistency automatically
- **Supabase infrastructure** handles auth, database, storage
- **Edge-ready** deployment with Vercel
- **Static generation** possible with appropriate adapter

### Developer Experience
- **File-based routing** with clear conventions
- **Hot module replacement** for fast development
- **Type inference** reduces boilerplate
- **Single source of truth** (database schema generates types)

---

## Common Patterns Reference

### Protected Route Pattern
```typescript
// +page.server.ts
export const load: PageServerLoad = async ({ locals: { safeGetSession } }) => {
    const { session } = await safeGetSession();
    if (!session) throw redirect(303, '/auth/login');
    return { session };
};
```

### Form Action Pattern
```typescript
// +page.server.ts
export const actions: Actions = {
    default: async ({ request, locals: { supabase, safeGetSession } }) => {
        const { session } = await safeGetSession();
        if (!session) return fail(401);

        const formData = await request.formData();
        // ... process form

        throw redirect(303, '/success-page');
    }
};
```

### Client-Side Mutation Pattern
```typescript
// +page.svelte
async function performAction() {
    const { error } = await supabase
        .from('table')
        .insert({ data });

    if (!error) {
        await invalidateAll(); // Refresh server data
    }
}
```

### Conditional UI Based on Auth
```svelte
{#if data.session}
    <button onclick={performAction}>Action</button>
{:else}
    <a href="/auth/login" class="btn">Login to continue</a>
{/if}
```

---

## Reference Locations

### Key Files for Different Tasks

**Authentication:**
- `src/hooks.server.ts` - Request interceptor
- `src/lib/supabase/server.ts` - Server client
- `src/lib/supabase/client.ts` - Browser client
- `src/routes/+layout.server.ts` - Session loading
- `src/routes/auth/*` - Auth pages

**Database Types:**
- `src/lib/types/database.ts` - Generated types
- `supabase/migrations/001_initial_schema.sql` - Schema

**Components:**
- `src/lib/components/TipTapEditor.svelte` - Rich text editor
- `src/lib/components/TipTapRenderer.svelte` - Content display

**Routes:**
- `src/routes/(app)/*` - Protected routes
- `src/routes/(public)/*` - Public routes
- `src/routes/auth/*` - Authentication routes

---

This architecture document provides the foundation for understanding and extending the BetChat application. Refer to SETUP.md for initial setup instructions.
