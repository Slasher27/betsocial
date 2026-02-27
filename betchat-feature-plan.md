# BetChat — Complete Feature Plan
## Substack Clone for the Betting & Casino Industry

This document maps every Substack feature to BetChat's gambling-focused implementation, organized into development phases with priority levels.

---

## Feature Mapping: Substack → BetChat

### 1. PUBLISHING & CONTENT

| Substack Feature | BetChat Equivalent | Gambling Adaptation |
|---|---|---|
| Long-form posts/essays | **Brand Articles** | Casino reviews, match previews, betting strategy guides, industry news |
| Free + paid post tiers | **Free + VIP content** | Free promos visible to all; VIP tips, exclusive odds, early access behind paywall |
| Post scheduling | **Scheduled posts** | Schedule promos to go live at kickoff time, event start, promo launch |
| Post categories | **Content types** | Articles, Promotions, Tips, News, Match Previews, Casino Reviews |
| Draft system | **Draft editor** | Save drafts, preview before publishing |
| Rich text editor | **TipTap editor** | Custom blocks for odds embeds, promo cards, T&C accordions, affiliate links |
| Image/media in posts | **Media uploads** | Brand banners, promo graphics, sport event images |
| Post embeds | **Post embeds** | Embed other brand posts, cross-promote |
| Podcast hosting | **Audio content** | Betting podcasts, tipster audio shows, match day previews |
| Video content | **Video posts** | Match analysis videos, casino game previews, live draw recordings |
| Discussion threads | **Betting threads** | Pre-match discussion threads, "What are you betting today?" threads |
| Backdated posts | **Import content** | Import existing blog/newsletter content without notifying subscribers |
| SEO-optimized pages | **Public SEO pages** | Brand pages and posts indexable, structured data for Google |
| Custom domains | **Custom domains** | Brands can map their own domain to their BetChat page |

### 2. SOCIAL & COMMUNITY

| Substack Feature | BetChat Equivalent | Gambling Adaptation |
|---|---|---|
| Notes (microblogging) | **Pulse** | Short-form betting tips, quick odds updates, live match reactions, hot takes |
| Chat (group messaging) | **Brand Chat Rooms** | Live match day chats, VIP subscriber chat, community discussions |
| Comments on posts | **Comments** | Threaded comments on articles and promos |
| Reactions/likes | **Reactions** | Like, Fire, Money-bag, Trophy reactions |
| Reader profiles | **Bettor profiles** | Bio, avatar, favourite sports, betting style, followed brands |
| Direct messaging | **DMs** | Subscriber-to-brand messaging for support, VIP communication |
| Livestreaming | **Live Events** | Live match commentary, live casino streams, live Q&A with tipsters |
| Audio spaces | **Voice Rooms** | Live audio rooms during major sporting events |

### 3. DISCOVERY & GROWTH

| Substack Feature | BetChat Equivalent | Gambling Adaptation |
|---|---|---|
| Explore/discovery feed | **Explore page** | Browse by category (Sports, Casino, Poker, Esports), trending, leaderboards |
| Recommendations | **Brand Recommendations** | Brands recommend other brands; shown after subscribe and on profile |
| Leaderboards | **Top Brands** | Ranked by followers, engagement, promo quality, verified status |
| Categories (29 topics) | **Betting categories** | Sports Betting, Online Casino, Poker, Esports, Crypto Gambling, Horse Racing, Lottery, Fantasy Sports |
| Search | **Full-text search** | Search posts, brands, promos, tips across the platform |
| Cross-posting | **Guest posts** | Brands can publish on each other's pages, cross-promote |
| Mentions | **@Mentions** | Tag brands and users in posts and Pulse notes |
| Subscriber referrals | **Referral program** | Users earn rewards for referring new subscribers to a brand |
| Gift referrals | **Gift subscriptions** | Buy someone a paid subscription to a brand |
| Substack Boost | **BetChat Boost** | Platform promotes promising new brands algorithmically |
| Notification system | **Smart notifications** | New post from followed brand, promo alerts, reply notifications, match day reminders |
| App discovery | **In-app discovery** | Algorithm-driven feed, "Brands like this", trending promos |

### 4. MONETIZATION & SUBSCRIPTIONS

| Substack Feature | BetChat Equivalent | Gambling Adaptation |
|---|---|---|
| Free/paid subscription tiers | **Free + Pro tiers** | Free follows, paid VIP with exclusive tips, early promo access |
| Custom subscription pricing ($5+ min) | **Flexible pricing** | Brands set own VIP tier pricing, monthly/annual |
| Stripe payments | **Stripe integration** | Handle all subscription billing, payouts to brands |
| 10% platform cut | **Revenue share** | BetChat takes a % of paid subscription revenue |
| Special offers/discounts | **Promo pricing** | Time-limited discounts on VIP subscriptions |
| Pledge campaigns | **Pre-launch pledges** | New brands gauge interest before launching paid tiers |
| Founding member pricing | **Early supporter tier** | Special rate for first N paid subscribers |
| Tips/donations | **Tips** | Readers can tip a brand or tipster for a winning bet |
| Subscriber-only archives | **VIP archives** | Full post history locked behind paid tier |
| Group subscriptions | **Brand bundles** | Subscribe to multiple brands at a discounted bundle rate |

### 5. EMAIL & NEWSLETTERS

| Substack Feature | BetChat Equivalent | Gambling Adaptation |
|---|---|---|
| Email delivery of posts | **Email newsletters** | Posts delivered to subscriber inboxes |
| Welcome emails | **Welcome sequences** | Auto-welcome new followers with brand intro, best promos, onboarding |
| Email automations | **Drip campaigns** | Auto email series for new subscribers (Day 1: welcome, Day 3: top tips, Day 7: VIP upsell) |
| Digest emails | **Weekly roundup** | Weekly digest of best posts from followed brands |
| Import subscriber list | **List import** | Brands import existing email lists (CSV upload) |
| Export subscriber list | **List export** | Brands can always export their follower list |
| Email design templates | **Email templates** | Pre-built templates optimized for promo delivery |

### 6. ANALYTICS & INSIGHTS

| Substack Feature | BetChat Equivalent | Gambling Adaptation |
|---|---|---|
| Subscriber stats | **Follower analytics** | Total, new, churned followers over time |
| Post performance | **Post analytics** | Views, reads, read-through rate, shares, saves |
| Growth sources | **Traffic sources** | Where followers come from: in-app, external, referrals, search |
| Engagement metrics | **Engagement dashboard** | Comments, reactions, click-through on promo links |
| Revenue reporting | **Revenue dashboard** | MRR, subscriber LTV, churn rate, payout history |
| Unique visitor stats | **Visitor analytics** | Daily unique visitors, page views per post |
| A/B testing (titles) | **Title testing** | Test different post titles for engagement |

### 7. BRAND PAGE / PUBLICATION SETUP

| Substack Feature | BetChat Equivalent | Gambling Adaptation |
|---|---|---|
| Publication homepage | **Brand page** | Full branded page with logo, banner, about, posts, promos |
| Custom navigation | **Custom nav bar** | Add custom links (main site, Telegram, Discord), hide/show sections |
| Sections/categories | **Content sections** | Organize posts into sections: Promos, Tips, News, Reviews |
| About page | **About page** | Brand story, licensing info, responsible gambling links |
| Custom colors/fonts | **Theme customization** | Brands pick accent colors, layout options for their page |
| Pinned posts | **Pinned content** | Pin best promo or welcome post to top of page |
| Publication logo/branding | **Brand identity** | Logo, banner image, favicon, brand colors |

### 8. PLATFORM & ADMIN

| Substack Feature | BetChat Equivalent | Gambling Adaptation |
|---|---|---|
| Mobile apps (iOS/Android) | **BetChat mobile app** | PWA first, then Capacitor-wrapped native apps |
| Reader app experience | **Feed reader** | Scrollable feed like Instagram/Substack reader |
| Content moderation | **Moderation tools** | Report, hide, ban; responsible gambling compliance |
| Creator terms/policies | **Brand guidelines** | T&Cs for brands, content policy, advertising standards |
| Team/multi-author | **Team accounts** | Multiple staff can publish under one brand page |
| Custom URLs | **Clean URLs** | betchat.social/brand-name/post-title |

### 9. GAMBLING-SPECIFIC (Unique to BetChat)

| Feature | Description |
|---|---|
| **Promo cards** | Rich promo blocks with code, T&Cs, wagering requirements, min deposit, expiry countdown |
| **Odds embeds** | Embed live or static odds into posts |
| **Geo-targeting** | Show content based on user jurisdiction (AU, CA, UK, ZA, etc.) |
| **Responsible gambling** | Mandatory links, self-exclusion integration, age verification, cooling-off reminders |
| **License verification** | Display and verify gambling licenses on brand pages |
| **Affiliate link tracking** | Click tracking on promo links, conversion attribution |
| **Event calendar** | Major sporting events, casino tournaments, promo deadlines |
| **Bet slip sharing** | Users can share bet slips as images/cards in Pulse |
| **Promo expiry alerts** | Auto-notify followers when a saved promo is about to expire |
| **Odds comparison widgets** | Compare odds across multiple brands for the same event |

---

## Development Phases

### Phase 1 — Core Publishing ✅ COMPLETE
**Goal:** Brands can sign up, create pages, and publish content. Users can follow and read.

- [x] SvelteKit + Supabase + Tailwind + DaisyUI setup
- [x] Auth (email/password, unified user flow)
- [x] Database schema with RLS
- [x] Profile system (user + brand with owner_id)
- [x] Landing page, login, signup, brand creation
- [x] Feed page with post display
- [x] Explore page structure
- [x] **Brand public page** (`/[brandSlug]`) — header, about, posts list
- [x] **User public page** (`/u/[username]`) — profile, posts list
- [x] **TipTap post editor** — rich text with image uploads, draft/publish
- [x] **Post display page** (`/[brandSlug]/[postSlug]` and `/u/[username]/[postSlug]`) — SSR
- [x] **Post edit page** — update existing posts
- [x] **Dashboard** — view and manage own posts, context switching
- [x] **Settings page** — profile/brand settings, avatar/banner upload, social links
- [x] **Basic image uploads** — avatar, banner upload via Supabase Storage
- [x] **Advanced image uploads** — drag & drop, preview, compression, dimension validation, delete
- [x] **Post slugs and clean URLs** — SEO-friendly routes
- [x] **Brand context switching** — switch between personal and brand accounts
- [x] **Context-aware navigation** — profile menu shows current context avatar/logo
- [ ] **Content sections** — organize posts by type (Articles, Promos, Tips, News)
- [ ] **Pinned posts** — brands can pin one post to top

### Phase 2 — Social Graph & Engagement ⚠️ IN PROGRESS
**Goal:** Following, feeds, comments, and reactions create a social loop.

- [x] **Follow/unfollow** — one-click follow with real-time follower count
- [x] **Personalized feed** — posts from followed brands in chronological order
- [x] **Bookmarks** — bookmarks page structure exists
- [x] **Comments on posts** — threaded replies on long-form posts with brand context support
- [x] **Comments on Pulse** — threaded replies on Pulse posts with brand context support
- [x] **Comment counts** — auto-updating counts via database triggers
- [x] **Reactions on posts** — like, fire, money-bag, trophy reactions with database triggers
- [ ] **Reactions on comments** — extend reaction system to comments
- [x] **Bookmarks UI** — toggle buttons on feed cards + remove button on bookmarks page
- [x] **Share** — X/Twitter, WhatsApp, Telegram social share buttons + copy link
- [x] **In-app notifications** — new post, comment reply, new follower with Realtime badge
- [ ] **@Mentions** — tag brands/users in comments
- [ ] **Explore page v2** — category tabs, trending posts, search, leaderboard
- [ ] **Full-text search** — search across posts, brands, users (Postgres FTS)

### Phase 3 — Pulse (Notes equivalent) ✅ COMPLETE
**Goal:** Short-form social feed for real-time engagement.

- [x] **Pulse feed** — global short-form feed integrated into main feed
- [x] **Create Pulse posts** — text posts with character limit (500 chars)
- [x] **Pulse reactions & replies** — like and comment on Pulse posts
- [x] **Brand context for Pulse** — post as personal or brand account
- [ ] **Repost/share** — repost a Pulse to your followers
- [ ] **Images in Pulse** — image uploads for Pulse posts
- [ ] **Hashtags** — #EPL, #Casino, #CryptoGambling for discoverability
- [ ] **Trending Pulse** — algorithm surfaces popular short-form content

### Phase 4 — Promotions Engine (Weeks 11–13)
**Goal:** Gambling-specific promo system that no other social platform has.

- [ ] **Promo card builder** — rich promo blocks in the post editor
- [ ] **Promo fields** — code, T&Cs, min deposit, wagering, expiry, destination URL
- [ ] **Expiry countdown** — real-time countdown timer on active promos
- [ ] **Promo notifications** — alert followers when brand posts a new promo
- [ ] **Promo expiry alerts** — notify users when saved promo is about to expire
- [ ] **Exclusive promos** — VIP-only promos for paid subscribers
- [ ] **Affiliate link tracking** — click tracking, UTM parameters, conversion logging
- [ ] **Geo-targeted promos** — show promos based on user jurisdiction
- [ ] **Promo archive** — browseable history of past promotions per brand

### Phase 5 — Monetization & Subscriptions (Weeks 14–17)
**Goal:** Brands can offer paid tiers, BetChat earns revenue.

- [ ] **Stripe Connect integration** — onboard brands as connected accounts
- [ ] **Free/VIP subscription tiers** — brands set pricing (monthly/annual)
- [ ] **Paywall on posts** — mark posts as VIP-only, teaser visible to free followers
- [ ] **Subscribe/checkout flow** — Stripe Checkout for paid subscriptions
- [ ] **Subscription management** — users manage/cancel subscriptions
- [ ] **Revenue dashboard** — brands see MRR, subscriber count, payout history
- [ ] **Platform revenue share** — BetChat takes 10% (configurable) of paid subs
- [ ] **Special offers** — time-limited discounts on VIP subscriptions
- [ ] **Founding supporter pricing** — discounted rate for first N paid subscribers
- [ ] **Tips/donations** — one-time tips to brands or tipsters
- [ ] **Brand bundles** — subscribe to multiple brands at a discount
- [ ] **Pledge campaigns** — gauge interest before launching paid tier

### Phase 6 — Email & Newsletters (Weeks 18–20)
**Goal:** Posts delivered to inboxes, automated sequences.

- [ ] **Email delivery** — published posts sent to follower inboxes (Resend/Postmark)
- [ ] **Email templates** — branded, mobile-responsive email layouts
- [ ] **Welcome email** — auto-sent on new follow, customizable per brand
- [ ] **Email automations** — drip sequences (Day 1, 3, 7 welcome series)
- [ ] **Weekly digest** — automated roundup of top posts from followed brands
- [ ] **Subscriber import** — CSV upload of existing email lists
- [ ] **Subscriber export** — brands can always export their follower list
- [ ] **Unsubscribe handling** — one-click unsubscribe, manage email preferences
- [ ] **Email analytics** — open rate, click rate, bounce rate per send

### Phase 7 — Chat & Live (Weeks 21–23)
**Goal:** Real-time community features like Substack Chat + Livestreaming.

- [ ] **Brand Chat rooms** — per-brand group chat for subscribers
- [ ] **VIP-only chat** — paid subscribers get exclusive chat access
- [ ] **Live match day chats** — event-triggered group discussions
- [ ] **Chat moderation** — pin messages, mute users, delete messages
- [ ] **Direct messages** — user-to-brand and user-to-user DMs
- [ ] **Live Events** — livestreaming for brands (match commentary, live picks)
- [ ] **Voice Rooms** — audio spaces during major events
- [ ] **Bet slip sharing** — share bet slips as cards in chat and Pulse

### Phase 8 — Discovery & Growth Engine (Weeks 24–26)
**Goal:** Platform-driven growth features that help brands find audiences.

- [ ] **Recommendations system** — brands recommend other brands
- [ ] **Post-subscribe recommendations** — "You might also like..." after following
- [ ] **Cross-posting** — guest posts on other brands' pages
- [ ] **Referral program** — users earn rewards for referring friends
- [ ] **Gift subscriptions** — buy someone a VIP subscription
- [ ] **BetChat Boost** — platform algorithmically promotes promising new brands
- [ ] **Leaderboards** — top brands by category, most engaged, fastest growing
- [ ] **Trending algorithm** — surface trending posts and Pulse content
- [ ] **SEO optimization** — sitemaps, structured data, OG image generation
- [ ] **Growth sources dashboard** — show brands where their subscribers come from

### Phase 9 — Analytics & Brand Tools (Weeks 27–29)
**Goal:** Give brands the data they need to grow.

- [ ] **Follower analytics** — growth chart, churn, demographics
- [ ] **Post analytics** — views, reads, read-through %, engagement rate
- [ ] **Traffic sources** — in-app, external, referral, search breakdown
- [ ] **Promo performance** — clicks, conversions, revenue attribution
- [ ] **Revenue reporting** — MRR, LTV, churn, payout history
- [ ] **Team accounts** — invite staff to manage brand page
- [ ] **Content calendar** — plan and schedule posts
- [ ] **A/B title testing** — test post titles for better engagement
- [ ] **Export analytics** — CSV/PDF export of reports

### Phase 10 — Mobile App & Platform Polish (Weeks 30–34)
**Goal:** Native app experience, performance, responsible gambling.

- [ ] **PWA optimization** — offline support, add-to-homescreen, service worker
- [ ] **Capacitor wrapper** — iOS and Android builds from SvelteKit
- [ ] **Push notifications** — OneSignal/FCM for mobile push
- [ ] **Infinite scroll feeds** — virtualized lists for performance
- [ ] **Image optimization** — Cloudflare R2 CDN, responsive images, lazy loading
- [ ] **Custom domains** — brands map their own domain to BetChat page
- [ ] **Brand verification** — admin review and verified badge system
- [ ] **Responsible gambling** — age verification, self-exclusion, cooling-off, mandatory links
- [ ] **License verification** — display and verify gambling licenses
- [ ] **Content moderation** — report system, admin queue, auto-moderation
- [ ] **Event calendar** — major sporting events and promo deadlines
- [ ] **Odds comparison widget** — compare odds across brands

---

## Priority Matrix

### Must-Have for MVP (Phases 1–5)
These are the features that make BetChat a viable product:
- Publishing (posts, editor, brand pages)
- Social graph (follow, feed, comments, reactions)
- Pulse (short-form social feed)
- Promotions engine (the killer feature for gambling)
- Paid subscriptions (revenue model)

### Should-Have for Launch (Phases 6–8)
These make BetChat competitive with Substack:
- Email newsletters
- Chat rooms
- Discovery and recommendations
- Referrals and growth tools

### Nice-to-Have for Growth (Phases 9–10)
These scale the platform:
- Advanced analytics
- Mobile native apps
- Custom domains
- Odds comparison
- Livestreaming

---

## Revenue Model

| Revenue Stream | Description | Estimated % of Revenue |
|---|---|---|
| **Subscription revenue share** | 10% of all paid VIP subscription revenue | 50% |
| **Brand Pro plans** | Monthly fee for premium brand features (analytics, automations, team accounts) | 25% |
| **Boosted posts** | Brands pay to promote posts in Explore/Feed | 15% |
| **Affiliate revenue** | Platform-level affiliate deals with betting operators | 10% |

### Pricing Tiers for Brands

| Tier | Price | Features |
|---|---|---|
| **Free** | $0/mo | Brand page, unlimited posts, up to 1,000 followers, basic analytics |
| **Pro** | $29/mo | Unlimited followers, email delivery, advanced analytics, promo cards, team accounts |
| **Business** | $99/mo | Everything in Pro + custom domain, API access, priority support, boosted visibility |
| **Enterprise** | Custom | White-label options, dedicated account manager, custom integrations |

---

## Tech Stack Summary

| Layer | Technology |
|---|---|
| Frontend | SvelteKit (SSR + SPA) |
| Styling | Tailwind CSS + DaisyUI |
| Editor | TipTap (ProseMirror) |
| Database | PostgreSQL (Supabase) |
| Auth | Supabase Auth |
| Real-time | Supabase Realtime (WebSockets) |
| Storage | Supabase Storage + Cloudflare R2 |
| Email | Resend (transactional + newsletters) |
| Payments | Stripe Connect |
| Analytics | PostHog |
| Search | Postgres FTS → Meilisearch at scale |
| CDN | Cloudflare |
| Hosting | Vercel (frontend) + Supabase Cloud (backend) |
| Mobile | PWA + Capacitor (iOS/Android) |
| Monitoring | Sentry |

---

## What Makes BetChat Different from Substack

1. **Gambling-native features** — promo cards, odds embeds, geo-targeting, affiliate tracking, responsible gambling tools. No other platform has this.
2. **Dual audience** — both brands AND bettors create content. Substack is creator-only.
3. **Promotions engine** — the killer feature. Time-limited offers with codes, T&Cs, wagering requirements, and expiry countdowns are first-class content types.
4. **Jurisdiction awareness** — content filtered by user location for regulatory compliance.
5. **Industry trust signals** — license verification, verified badges, responsible gambling compliance built into the platform.
6. **Pulse** — real-time short-form feed for live match reactions and quick tips. More active than Substack Notes because betting is time-sensitive.
7. **Event-driven engagement** — content and chat activity spikes around live sporting events, creating natural engagement loops.

---

## Current Status (Updated Feb 18, 2026)

**Completed:**
- ✅ Phase 1: Core Publishing - COMPLETE
- ✅ Phase 3: Pulse (basic implementation) - COMPLETE
- ⚠️ Phase 2: Social Graph & Engagement - IN PROGRESS

**Active Features:**
- User and brand profiles with context switching
- Post creation and editing with TipTap
- Pulse (short-form posts) with reactions and comments
- Follow/unfollow functionality
- Feed with posts and Pulse
- Brand and user public pages
- Dashboard with context-aware post management
- Settings with comprehensive profile/brand configuration
- Advanced image uploads (drag & drop, preview, compression, validation, delete)
- Context-aware navigation (profile menu shows correct avatar/logo)
- Threaded comments on posts and Pulse with brand context support
- Reactions (like, fire, money-bag, trophy) on posts with auto-updating counts
- Bookmarks with toggle on feed cards, post pages, and remove on bookmarks page
- Social share menu (X/Twitter, WhatsApp, Telegram, copy link) on all post pages
- In-app notifications with Realtime badge, dropdown panel, and full `/notifications` page

**Recent Session Completed (Feb 18, 2026):**
- ✅ **A11y fix** — Added `aria-label="Add image"` to PulseInput icon button (was causing vite-plugin-svelte warning)
- ✅ **Bookmarks UI** — Fully wired end-to-end
  - Fixed broken query (`id` → `post_id` — bookmarks table has no `id` column)
  - Bookmark toggle button on every feed post card (optimistic UI, per-card loading spinner)
  - Remove bookmark button on bookmarks page (instant removal without page reload)
  - Feed server loader now fetches `bookmarkedPostIds` array to pre-populate state
  - Session passed through bookmarks server loader for client-side delete
- ✅ **Share functionality** — Social share menu on all post pages
  - Created `ShareMenu.svelte` component with dropdown (X/Twitter, WhatsApp, Telegram, Copy link)
  - Copy link shows "Copied!" confirmation for 2 seconds then resets
  - Click-outside closes the dropdown
  - Wired into brand post page (`/[brandSlug]/[postSlug]`) and user post page (`/u/[username]/[postSlug]`)
  - Decision: Facebook excluded — actively suppresses gambling/affiliate content
  - Decision: Pulse bookmarks excluded — Pulse is ephemeral; bookmarks are for long-form content only
- ✅ **In-app Notifications** — Full notification system
  - Migration 014: 3 DB triggers (`notify_new_post`, `notify_comment_reply`, `notify_new_follower`)
  - Realtime enabled on `notifications` table via `supabase_realtime` publication
  - `NotificationBell.svelte` — bell icon with red unread badge (capped at 9+), lazy-loaded dropdown, Realtime subscription pushes new notifications live
  - Layout server loader fetches unread count (count-only query) on every page load
  - Full `/notifications` page — lists 50 most recent, batch-fetches actor profiles and brand slugs, mark-all-read with `invalidateAll` to refresh navbar badge
  - Supabase CLI linked and migration history repaired; migration 014 pushed to production

**Database Migrations Added:**
- `011_add_comment_count_triggers.sql` — Auto-update comment counts
- `012_add_reaction_count_triggers.sql` — Auto-update like counts
- `013_add_brand_id_to_comments.sql` — Brand context for comments
- `014_notification_triggers.sql` — new_post, comment_reply, new_follower triggers + Realtime

**Known Future Enhancements:**
- User-to-user following (currently only users → brands)
- Reactions on comments (currently only on posts)
- Pulse bookmarks (deferred — Pulse is intentionally ephemeral)

## Next Immediate Steps (Phase 2 Remaining)

1. **@Mentions** — Tag brands/users in comments with autocomplete
2. **Explore page v2** — Category tabs, trending posts, leaderboard
3. **Full-text search** — Search across posts, brands, users (Postgres FTS)

## Future Phases

1. **Phase 4** — Build promotions engine (the killer feature)
2. **Polish existing features** — Content sections, pinned posts
3. **Seed content** — Create demo brand pages with sample posts and promos
4. **Alpha test** — Get 2–3 real betting brands to try the platform
5. **Iterate on UX** — Refine posting and reading experience based on feedback

---

*This is the living feature roadmap for BetChat. Last updated: February 2026. Phases can overlap. Update as priorities shift based on user feedback.*
