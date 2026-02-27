# BetChat Development Guide

## Core Development Principles

### Code Quality Standards

- **Avoid over-engineering** - Keep solutions simple and pragmatic
- **No feature creep** - Build only what's explicitly needed
- **Minimal comments** - Write self-documenting code
- **Trust internal code** - Avoid unnecessary validation layers
- **No premature abstraction** - Only abstract when duplication occurs
- **Create reusable components** - When code duplicates, extract to components
- **Clean up temporary files** - Remove unused files and imports

### Svelte 5 Best Practices

- Use runes API: `$state`, `$derived`, `$effect`, `$props`
- Initialize state with empty values, populate in `$effect()` to maintain reactivity
- Never capture initial prop values directly in state initialization
- Use `$derived` for computed values instead of manual updates
- Only use emojis if explicitly requested by user

### Accessibility Requirements

- Always include ARIA roles on interactive elements
- Add `aria-label` attributes to icon-only buttons
- Use semantic HTML (buttons for actions, links for navigation)
- Ensure proper label/control associations
- Add `role="button"` and `tabindex="0"` for non-button interactive elements

## Technical Stack

### Frontend

- **Framework**: SvelteKit 2.x with Svelte 5 runes
- **Language**: TypeScript
- **Styling**: TailwindCSS + DaisyUI components
- **Icons**: Lucide Svelte (tree-shakeable)
- **Image Handling**: browser-image-compression
- **Rich Text Editor**: TipTap (for post content)

### Backend

- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage (avatars, banners, logos)
- **Real-time**: Supabase Realtime (notifications)

### Build & Dev Tools

- **Package Manager**: npm
- **Dev Server**: Vite
- **Type Checking**: TypeScript strict mode

## Database Architecture

### Core Tables

#### `profiles`

User profiles (all authenticated users)

- `id` (UUID, primary key, references auth.users)
- `username` (TEXT, unique)
- `display_name`, `avatar_url`, `banner_url`, `bio`
- `notification_preferences` (JSONB - new_post, comment_reply, new_follower, mention, promotion)
- Social links: `website_url`, `twitter_url`, `facebook_url`, `instagram_url`, `linkedin_url`, `youtube_url`, `tiktok_url`, `substack_url`

#### `brand_profiles`

Brands created by users

- `id` (UUID, primary key)
- `owner_id` (UUID, references profiles)
- `brand_name`, `slug` (unique), `logo_url`, `banner_url`, `description`
- `website_url`, `license_info`, `is_verified`
- `categories` (TEXT[]), `target_jurisdictions` (TEXT[])
- `follower_count` (INTEGER, auto-updated via trigger)
- `stripe_account_id` (for future monetization)

#### `brand_members`

Team members with role-based access

- `brand_id` (UUID, references brand_profiles)
- `user_id` (UUID, references profiles)
- `role` (brand_role enum: owner, admin, editor, viewer)
- `invited_by` (UUID, references profiles)
- **Roles**:
  - `owner`: Full access, cannot be changed/removed
  - `admin`: Manage posts, edit settings, manage team
  - `editor`: Create, edit, publish posts
  - `viewer`: View drafts and analytics

#### `posts`

Content created by brands

- `id` (UUID, primary key)
- `brand_id` (UUID, references brand_profiles)
- `author_id` (UUID, references profiles)
- `title`, `slug`, `content` (JSONB), `excerpt`, `cover_image_url`
- `post_type` (enum: article, promotion, news, update, tip)
- `status` (enum: draft, published, archived)
- `is_pinned`, `is_paywalled`
- `like_count`, `comment_count`, `share_count` (auto-updated)
- `published_at`, `created_at`, `updated_at`

#### `promotions`

Extended data for promotional posts

- `id` (UUID, references posts)
- `promo_code`, `offer_details`, `terms_conditions`
- `min_deposit`, `wagering_requirements`
- `expires_at`, `destination_url`, `is_exclusive`

#### `follows`

Users following brands

- `follower_id` (UUID, references profiles)
- `brand_id` (UUID, references brand_profiles)
- `subscription_tier` (enum: free, paid)

#### `comments`

Comments on posts

- `id` (UUID, primary key)
- `post_id` (UUID, references posts)
- `author_id` (UUID, references profiles)
- `parent_id` (UUID, references comments - for threading)
- `content` (TEXT), `is_hidden`
- `like_count` (auto-updated)

#### `comment_mentions`

User/brand mentions in comments

- `id` (UUID, primary key)
- `comment_id` (UUID, references comments)
- `mentioned_user_id` (UUID, references profiles)
- `mentioned_brand_id` (UUID, references brand_profiles)

#### `reactions`

Likes/reactions on posts and comments

- `user_id`, `target_type` (post/comment), `target_id`
- `reaction_type` (enum: like, fire, money, trophy)

#### `bookmarks`

User bookmarks for posts

- `user_id` (UUID, references profiles)
- `post_id` (UUID, references posts)

#### `notifications`

User notifications

- `id` (UUID, primary key)
- `user_id` (UUID, references profiles)
- `type` (enum: new_post, comment_reply, new_follower, promotion, mention)
- `data` (JSONB - contextual notification data)
- `is_read` (BOOLEAN)

### Row Level Security (RLS)

All tables have RLS enabled. Key policies:

**Profiles**

- SELECT: Public (everyone can view profiles)
- UPDATE: Users can update own profile

**Brand Profiles**

- SELECT: Public
- INSERT: Authenticated users
- UPDATE: Owner or admins can update
- DELETE: Only owner can delete

**Brand Members**

- SELECT: Visible to team members and owner
- INSERT/UPDATE/DELETE: Only owner can manage

**Posts**

- SELECT: Published posts are public, drafts visible to author
- INSERT: Brand members with editor/admin/owner role
- UPDATE/DELETE: Post author only

**Follows**

- SELECT: Public
- INSERT/DELETE: Users manage own follows

**Comments**

- SELECT: Non-hidden comments public, author can see hidden
- INSERT: Authenticated users
- UPDATE/DELETE: Comment author only

**Notifications**

- SELECT/UPDATE: User can view/update own notifications

### Database Triggers

**Auto-update timestamps**

- `profiles_updated_at`, `brand_profiles_updated_at`, `posts_updated_at`, `comments_updated_at`
- Updates `updated_at` field on row changes

**Follower count**

- `follows_count_trigger` - Auto-increments/decrements `brand_profiles.follower_count`

**Auto-create profile**

- `handle_new_user()` - Creates profile on auth.users insert
- Auto-generates unique username from email

**Auto-add owner as member**

- `add_brand_owner_as_member()` - Adds owner to brand_members on brand creation

**Notification triggers**

- `notify_new_post()` - Notifies followers when brand publishes (checks `new_post` preference)
- `notify_comment_reply()` - Notifies post/comment author (checks `comment_reply` preference)
- `notify_new_follower()` - Notifies brand owner (checks `new_follower` preference)
- `create_mention_notification()` - Notifies mentioned users/brands (checks `mention` preference)

All notification triggers respect user `notification_preferences` settings.

## Project Structure

```
App/
├── src/
│   ├── lib/
│   │   ├── components/     # Reusable Svelte components
│   │   ├── supabase/       # Supabase client setup
│   │   ├── types/          # TypeScript type definitions
│   │   └── utils/          # Helper functions
│   ├── routes/
│   │   ├── (app)/          # Authenticated app routes
│   │   │   ├── dashboard/  # User dashboard, posts, analytics
│   │   │   ├── settings/   # User & brand settings
│   │   │   └── notifications/ # Notification center
│   │   ├── (auth)/         # Auth routes (login, signup)
│   │   ├── [slug]/         # Brand public pages
│   │   └── u/[username]/   # User public pages
│   └── app.html            # Root HTML template
├── supabase/
│   └── migrations/         # Database migration SQL files
├── static/                 # Static assets
└── package.json
```

## Key Features Implemented

### Phase 1: Core Platform ✅

- User authentication (email/password)
- User profiles with social links
- Brand creation and management
- Rich text post editor (TipTap)
- Post publishing and drafts
- Comments with threading
- Likes/reactions
- Follow system
- Bookmarks

### Phase 2: Enhanced Features ✅

- Real-time notifications with preferences
- Notification center UI
- @mentions in comments
- Image uploads (avatars, banners, logos)
- Image compression and optimization
- Brand/user switching interface
- Post analytics (likes, comments, shares)
- Search functionality

### Recent Additions ✅

- **Analytics Dashboard** - Engagement metrics, follower growth, top posts
- **Notification Preferences** - Granular control over notification types
- **Brand Member Management** - Role-based team access (owner, admin, editor, viewer)

### Pending Features

- Post scheduling (future publication dates)
- Email notifications (Phase 4)
- Monetization (subscriptions, paid content) - Phase 3

## Environment Setup

### Required Environment Variables

```env
PUBLIC_SUPABASE_URL=your_supabase_url
PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Local Development

```bash
npm install
npm run dev
```

### Database Setup

1. Create Supabase project
2. Run migrations in order (001, 002, etc.)
3. Enable storage buckets: `profiles`, `brands`
4. Configure storage policies for public read access

## Common Patterns

### Form Handling with Progressive Enhancement

```svelte
<form
  method="POST"
  action="?/actionName"
  use:enhance={() => {
    loading = true;
    return async ({ result, update }) => {
      loading = false;
      await update();
    };
  }}
>
```

### Svelte 5 State Management

```svelte
<script lang="ts">
  let { data } = $props<{ data: PageData }>();

  // Initialize with empty values
  let username = $state('');

  // Populate in $effect for reactivity
  $effect(() => {
    username = data.profile?.username || '';
  });

  // Computed values
  const fullName = $derived(`${firstName} ${lastName}`);
</script>
```

### Loading Brand/Personal Context

```typescript
const brandSlug = url.searchParams.get('brand');
let currentBrand = null;

if (brandSlug) {
  const { data: brand } = await supabase
    .from('brand_profiles')
    .select('*')
    .eq('slug', brandSlug)
    .eq('owner_id', session.user.id)
    .maybeSingle();

  currentBrand = brand;
}
```

### Image Upload with Compression

```typescript
import imageCompression from 'browser-image-compression';

async function compressAvatar(file: File): Promise<File> {
  const options = {
    maxSizeMB: 1,
    maxWidthOrHeight: 800,
    useWebWorker: true,
    initialQuality: 0.9
  };

  const compressedBlob = await imageCompression(file, options);
  return new File([compressedBlob], file.name, {
    type: compressedBlob.type,
    lastModified: Date.now()
  });
}
```

## Troubleshooting

### Svelte Compiler Warnings

- **State reactivity**: Always initialize state with empty values, populate in `$effect()`
- **Accessibility**: Add ARIA roles and labels to all interactive elements
- **Label associations**: Ensure `<label>` elements have proper `for` attributes

### Database Issues

- **RLS Policies**: Always test with authenticated users, not service role
- **Cascade Deletes**: Be aware of FK constraints with CASCADE
- **Trigger Loops**: Avoid recursive triggers by checking OLD vs NEW values

### Development Server

- Multiple dev servers may run on different ports (5173, 5174, 5175)
- EPERM errors on Windows are typically from .svelte-kit type generation (non-critical)

## Future Considerations

### Performance

- Implement pagination for long lists (posts, comments, notifications)
- Add CDN for static assets
- Consider Redis for caching frequently accessed data

### Security

- Rate limiting on API endpoints
- Input sanitization (especially for rich text content)
- CSP headers for XSS protection

### Monitoring

- Error tracking (Sentry)
- Analytics (PostHog, Plausible)
- Performance monitoring (Vercel Analytics)

## Version History

### Latest Session (2026-02-27)

- ✅ Fixed Svelte 5 state management issues
- ✅ Added notification preferences functionality
- ✅ Implemented analytics dashboard
- ✅ Added brand member management with roles
- ✅ Fixed all accessibility warnings

### Previous Work

- User authentication and profiles
- Brand creation and management
- Post editor with rich text
- Comments and mentions
- Follow system and notifications
- Real-time updates
