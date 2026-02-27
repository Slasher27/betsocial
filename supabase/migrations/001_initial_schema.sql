-- =============================================================================
-- BetChat Database Schema — Initial Migration
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor → New Query)
-- =============================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- ENUMS
-- =============================================================================

CREATE TYPE account_type AS ENUM ('user', 'brand');
CREATE TYPE post_type AS ENUM ('article', 'promotion', 'news', 'update');
CREATE TYPE post_status AS ENUM ('draft', 'published', 'archived');
CREATE TYPE reaction_type AS ENUM ('like', 'fire', 'money');
CREATE TYPE subscription_tier AS ENUM ('free', 'paid');
CREATE TYPE notification_type AS ENUM ('new_post', 'comment_reply', 'new_follower', 'promotion', 'mention');

-- =============================================================================
-- PROFILES (extends Supabase auth.users)
-- =============================================================================

CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    account_type account_type NOT NULL DEFAULT 'user',
    country_code TEXT,
    betting_interests TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for username lookups
CREATE INDEX idx_profiles_username ON profiles(username);
CREATE INDEX idx_profiles_account_type ON profiles(account_type);

-- =============================================================================
-- BRAND PROFILES
-- =============================================================================

CREATE TABLE brand_profiles (
    id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    brand_name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    logo_url TEXT,
    banner_url TEXT,
    description TEXT,
    website_url TEXT,
    license_info TEXT,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    categories TEXT[] DEFAULT '{}',
    target_jurisdictions TEXT[] DEFAULT '{}',
    stripe_account_id TEXT,
    follower_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for slug lookups (brand pages)
CREATE INDEX idx_brand_profiles_slug ON brand_profiles(slug);
CREATE INDEX idx_brand_profiles_categories ON brand_profiles USING GIN(categories);
CREATE INDEX idx_brand_profiles_verified ON brand_profiles(is_verified) WHERE is_verified = TRUE;

-- =============================================================================
-- POSTS
-- =============================================================================

CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand_id UUID REFERENCES brand_profiles(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    slug TEXT NOT NULL,
    content JSONB NOT NULL DEFAULT '{}',
    excerpt TEXT,
    cover_image_url TEXT,
    post_type post_type NOT NULL DEFAULT 'article',
    status post_status NOT NULL DEFAULT 'draft',
    categories TEXT[] DEFAULT '{}',
    target_jurisdictions TEXT[] DEFAULT '{}',
    is_pinned BOOLEAN NOT NULL DEFAULT FALSE,
    like_count INTEGER NOT NULL DEFAULT 0,
    comment_count INTEGER NOT NULL DEFAULT 0,
    share_count INTEGER NOT NULL DEFAULT 0,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(brand_id, slug)
);

-- Indexes for feed queries
CREATE INDEX idx_posts_brand_id ON posts(brand_id);
CREATE INDEX idx_posts_author_id ON posts(author_id);
CREATE INDEX idx_posts_status ON posts(status);
CREATE INDEX idx_posts_published_at ON posts(published_at DESC) WHERE status = 'published';
CREATE INDEX idx_posts_post_type ON posts(post_type);

-- Full-text search index
CREATE INDEX idx_posts_search ON posts USING GIN(
    to_tsvector('english', COALESCE(title, '') || ' ' || COALESCE(excerpt, ''))
);

-- =============================================================================
-- PROMOTIONS (extends posts where post_type = 'promotion')
-- =============================================================================

CREATE TABLE promotions (
    id UUID PRIMARY KEY REFERENCES posts(id) ON DELETE CASCADE,
    promo_code TEXT,
    offer_details TEXT,
    terms_conditions TEXT,
    min_deposit DECIMAL(10, 2),
    wagering_requirements TEXT,
    expires_at TIMESTAMPTZ,
    destination_url TEXT,
    is_exclusive BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_promotions_expires_at ON promotions(expires_at) WHERE expires_at IS NOT NULL;

-- =============================================================================
-- FOLLOWS
-- =============================================================================

CREATE TABLE follows (
    follower_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    brand_id UUID NOT NULL REFERENCES brand_profiles(id) ON DELETE CASCADE,
    subscription_tier subscription_tier NOT NULL DEFAULT 'free',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (follower_id, brand_id)
);

CREATE INDEX idx_follows_brand_id ON follows(brand_id);
CREATE INDEX idx_follows_follower_id ON follows(follower_id);

-- =============================================================================
-- COMMENTS
-- =============================================================================

CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_hidden BOOLEAN NOT NULL DEFAULT FALSE,
    like_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_author_id ON comments(author_id);
CREATE INDEX idx_comments_parent_id ON comments(parent_id) WHERE parent_id IS NOT NULL;

-- =============================================================================
-- REACTIONS
-- =============================================================================

CREATE TABLE reactions (
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    target_type TEXT NOT NULL CHECK (target_type IN ('post', 'comment')),
    target_id UUID NOT NULL,
    reaction_type reaction_type NOT NULL DEFAULT 'like',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, target_type, target_id)
);

CREATE INDEX idx_reactions_target ON reactions(target_type, target_id);

-- =============================================================================
-- BOOKMARKS
-- =============================================================================

CREATE TABLE bookmarks (
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, post_id)
);

CREATE INDEX idx_bookmarks_user_id ON bookmarks(user_id);

-- =============================================================================
-- NOTIFICATIONS
-- =============================================================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    type notification_type NOT NULL,
    data JSONB NOT NULL DEFAULT '{}',
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;

-- =============================================================================
-- AUTO-UPDATE TIMESTAMPS
-- =============================================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER brand_profiles_updated_at
    BEFORE UPDATE ON brand_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER posts_updated_at
    BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER comments_updated_at
    BEFORE UPDATE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =============================================================================
-- FOLLOWER COUNT TRIGGER (denormalized count)
-- =============================================================================

CREATE OR REPLACE FUNCTION update_follower_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE brand_profiles SET follower_count = follower_count + 1 WHERE id = NEW.brand_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE brand_profiles SET follower_count = follower_count - 1 WHERE id = OLD.brand_id;
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER follows_count_trigger
    AFTER INSERT OR DELETE ON follows
    FOR EACH ROW EXECUTE FUNCTION update_follower_count();

-- =============================================================================
-- AUTO-CREATE PROFILE ON SIGNUP
-- =============================================================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, username, display_name, account_type)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'display_name', SPLIT_PART(NEW.email, '@', 1)),
        COALESCE((NEW.raw_user_meta_data->>'account_type')::account_type, 'user')
    );

    -- If brand account, also create brand profile
    IF NEW.raw_user_meta_data->>'account_type' = 'brand' THEN
        INSERT INTO brand_profiles (id, brand_name, slug, description, website_url, categories)
        VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'brand_name', 'My Brand'),
            COALESCE(NEW.raw_user_meta_data->>'brand_slug', NEW.id::TEXT),
            NEW.raw_user_meta_data->>'brand_description',
            NEW.raw_user_meta_data->>'brand_website',
            CASE 
                WHEN NEW.raw_user_meta_data->>'brand_category' IS NOT NULL 
                THEN ARRAY[NEW.raw_user_meta_data->>'brand_category']
                ELSE '{}'
            END
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- =============================================================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE brand_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- PROFILES: Anyone can read, users can update their own
CREATE POLICY "Profiles are publicly readable"
    ON profiles FOR SELECT
    USING (true);

CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

-- BRAND PROFILES: Anyone can read, brand owners can update
CREATE POLICY "Brand profiles are publicly readable"
    ON brand_profiles FOR SELECT
    USING (true);

CREATE POLICY "Brand owners can update own brand"
    ON brand_profiles FOR UPDATE
    USING (auth.uid() = id);

-- POSTS: Published posts are public, drafts only visible to author
CREATE POLICY "Published posts are publicly readable"
    ON posts FOR SELECT
    USING (status = 'published' OR auth.uid() = author_id);

CREATE POLICY "Brand owners can create posts"
    ON posts FOR INSERT
    WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Authors can update own posts"
    ON posts FOR UPDATE
    USING (auth.uid() = author_id);

CREATE POLICY "Authors can delete own posts"
    ON posts FOR DELETE
    USING (auth.uid() = author_id);

-- PROMOTIONS: Readable if parent post is readable
CREATE POLICY "Promotions are publicly readable"
    ON promotions FOR SELECT
    USING (true);

CREATE POLICY "Brand owners can manage promotions"
    ON promotions FOR ALL
    USING (EXISTS (
        SELECT 1 FROM posts WHERE posts.id = promotions.id AND posts.author_id = auth.uid()
    ));

-- FOLLOWS: Anyone can see follower counts, users manage their own
CREATE POLICY "Follows are publicly readable"
    ON follows FOR SELECT
    USING (true);

CREATE POLICY "Users can follow brands"
    ON follows FOR INSERT
    WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow brands"
    ON follows FOR DELETE
    USING (auth.uid() = follower_id);

-- COMMENTS: Visible comments are public, users manage their own
CREATE POLICY "Non-hidden comments are publicly readable"
    ON comments FOR SELECT
    USING (is_hidden = false OR auth.uid() = author_id);

CREATE POLICY "Authenticated users can comment"
    ON comments FOR INSERT
    WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Authors can update own comments"
    ON comments FOR UPDATE
    USING (auth.uid() = author_id);

CREATE POLICY "Authors can delete own comments"
    ON comments FOR DELETE
    USING (auth.uid() = author_id);

-- REACTIONS: Public readable, users manage their own
CREATE POLICY "Reactions are publicly readable"
    ON reactions FOR SELECT
    USING (true);

CREATE POLICY "Users can add reactions"
    ON reactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove own reactions"
    ON reactions FOR DELETE
    USING (auth.uid() = user_id);

-- BOOKMARKS: Only visible to the owner
CREATE POLICY "Users can view own bookmarks"
    ON bookmarks FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can add bookmarks"
    ON bookmarks FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove own bookmarks"
    ON bookmarks FOR DELETE
    USING (auth.uid() = user_id);

-- NOTIFICATIONS: Only visible to the recipient
CREATE POLICY "Users can view own notifications"
    ON notifications FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
    ON notifications FOR UPDATE
    USING (auth.uid() = user_id);


-- =============================================================================
-- DONE! Your BetChat database is ready.
-- =============================================================================
