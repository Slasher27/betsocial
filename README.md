# BetChat

**A Substack-style publishing platform for the betting & casino industry**

BetChat is a feature-rich content publishing and community platform built specifically for the gambling industry. Brands can create articles, share betting tips, post promotions, and build engaged communities of bettors.

---

## 🚀 Tech Stack

- **Frontend:** SvelteKit 2.50.2 + Svelte 5 (Runes API)
- **Backend:** Supabase (PostgreSQL, Auth, Storage, Realtime)
- **Styling:** Tailwind CSS 4.x + DaisyUI 5.5.18
- **Editor:** TipTap 3.19.0 (rich text editor)
- **Icons:** lucide-svelte
- **Deployment:** Vercel (Edge adapter)

---

## 📋 Current Status

✅ **Phase 1 Complete:** Core publishing, user profiles, brand pages, subscriptions
✅ **Phase 2 Complete:** Comments, reactions, search, pinned posts, @mentions, Pulse, Explore page

**Progress:** ~35% (2 of 6 phases complete)

See [PROGRESS.md](./PROGRESS.md) for detailed status and next steps.

---

## 🛠️ Development Setup

### Prerequisites

- Node.js 18+ and npm
- Supabase account (free tier works)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd App
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**

   Create a `.env` file in the root directory:
   ```env
   PUBLIC_SUPABASE_URL=your_supabase_url
   PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. **Run database migrations**

   If using Supabase remotely:
   - Go to your Supabase Dashboard → SQL Editor
   - Run migrations from `supabase/migrations/` in order (001 through 017)

5. **Start the development server**
   ```bash
   npm run dev
   ```

6. **Open the app**

   Navigate to `http://localhost:5173` in your browser.

---

## 📁 Project Structure

```
App/
├── src/
│   ├── lib/
│   │   ├── components/      # Reusable Svelte components
│   │   ├── supabase/        # Supabase client setup
│   │   └── utils/           # Utility functions
│   ├── routes/
│   │   ├── (app)/           # Authenticated routes
│   │   │   ├── dashboard/   # User dashboard
│   │   │   ├── feed/        # Home feed
│   │   │   ├── settings/    # User settings
│   │   │   └── ...
│   │   ├── (public)/        # Public routes
│   │   │   ├── [brandSlug]/ # Brand pages
│   │   │   ├── u/           # User pages
│   │   │   ├── explore/     # Discovery page
│   │   │   └── ...
│   │   ├── auth/            # Authentication
│   │   └── brands/          # Brand management
│   └── app.html             # HTML template
├── supabase/
│   └── migrations/          # Database migrations
├── specs/                   # Product specifications
├── static/                  # Static assets
├── ARCHITECTURE.md          # System architecture
├── PROGRESS.md              # Development progress
└── betchat-feature-plan.md  # Feature roadmap
```

---

## 🗄️ Database

**Provider:** Supabase (PostgreSQL)

**Migrations:** 17 applied (see `supabase/migrations/`)

**Key Tables:**
- `profiles` - User accounts
- `brand_profiles` - Brands/publications
- `posts` - Long-form content
- `pulse_posts` - Short-form content (Twitter-style)
- `comments` - Threaded discussions
- `mentions` - @Mention tracking
- `reactions` - Post/comment likes
- `follows` - Brand subscriptions
- `notifications` - User notifications

**Features:**
- Row-Level Security (RLS) on all tables
- Automatic triggers for counts and search vectors
- PostgreSQL Full-Text Search
- Realtime subscriptions ready

See [specs/global-db-erd.md](./specs/global-db-erd.md) for complete schema.

---

## 🎯 Key Features

### Content Publishing
- Rich text editor (TipTap) with custom extensions
- Post types: Articles, Promotions, News, Updates, Tips
- Draft and published states
- SEO-friendly URLs and meta tags
- Cover images and excerpts

### Social & Community
- Follow brands
- Like/react to posts
- Threaded comments with @mentions
- Pulse (Twitter-like short posts)
- Notifications for interactions

### Discovery
- Full-text search across posts, brands, users
- Trending posts (7-day engagement)
- Browse brands by category
- Brand leaderboards by followers

### User Experience
- Brand and personal profiles
- Feed showing followed brand posts
- Bookmark posts for later
- Pin one post to profile
- Mobile-responsive design

---

## 🔐 Authentication

**Provider:** Supabase Auth

**Supported Methods:**
- Email/password
- Magic links
- (Social OAuth ready for future)

**User Types:**
- **Readers:** Can follow brands, like posts, comment
- **Creators:** Can create brands, publish content, manage followers
- **Brand Members:** Multi-user access to brands (owner, admin, editor roles)

---

## 🚧 Upcoming Features

### Phase 3: Monetization
- Stripe integration
- Paid subscriptions (Free vs Pro tiers)
- Paywall for premium content
- Revenue dashboards

### Phase 4: Email & Rich Media
- Email newsletters (Resend integration)
- Video and podcast hosting
- Email templates and automations

### Phase 5: Growth & Discovery
- Recommendation algorithms
- Referral programs
- Cross-promotions

See [PROGRESS.md](./PROGRESS.md) for complete roadmap.

---

## 📖 Documentation

- **[PROGRESS.md](./PROGRESS.md)** - Detailed development status and next steps
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - System architecture overview
- **[betchat-feature-plan.md](./betchat-feature-plan.md)** - Full Substack feature mapping
- **[specs/](./specs/)** - Product specifications and database docs

---

## 🧪 Testing

**Current Status:** No automated tests yet

**Planned:**
- Unit tests for utilities
- Component tests with Vitest
- E2E tests with Playwright

---

## 📦 Building for Production

```bash
# Build the app
npm run build

# Preview the production build
npm run preview
```

**Deployment:** Configured for Vercel with edge adapter

---

## 🤝 Contributing

This is a private project. If you have access and want to contribute:

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Submit a pull request

---

## 📄 License

Proprietary - All rights reserved

---

## 🐛 Known Issues

See [PROGRESS.md](./PROGRESS.md#-known-issues--tech-debt) for current issues and tech debt.

---

## 📞 Support

For questions or issues, contact the development team.

---

**Built with ❤️ for the betting community**
