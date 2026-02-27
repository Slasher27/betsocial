-- =============================================================================
-- BetChat Database Migration 002 — Restructure: Users first, Brands second
-- Run this in Supabase SQL Editor AFTER 001_initial_schema.sql
-- =============================================================================

-- STEP 1: Drop everything that depends on the old structure
-- =============================================================================

-- Drop triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS follows_count_trigger ON follows;
DROP TRIGGER IF EXISTS comments_updated_at ON comments;
DROP TRIGGER IF EXISTS posts_updated_at ON posts;
DROP TRIGGER IF EXISTS brand_profiles_updated_at ON brand_profiles;
DROP TRIGGER IF EXISTS profiles_updated_at ON profiles;

-- Drop functions
DROP FUNCTION IF EXISTS handle_new_user();
DROP FUNCTION IF EXISTS update_follower_count();
DROP FUNCTION IF EXISTS update_updated_at();

-- Drop all RLS policies
DROP POLICY IF EXISTS "Profiles are publicly readable" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Brand profiles are publicly readable" ON brand_profiles;
DROP POLICY IF EXISTS "Brand owners can update own brand" ON brand_profiles;
DROP POLICY IF EXISTS "Published posts are publicly readable" ON posts;
DROP POLICY IF EXISTS "Brand owners can create posts" ON posts;
DROP POLICY IF EXISTS "Authors can update own posts" ON posts;
DROP POLICY IF EXISTS "Authors can delete own posts" ON posts;
DROP POLICY IF EXISTS "Promotions are publicly readable" ON promotions;
DROP POLICY IF EXISTS "Brand owners can manage promotions" ON promotions;
DROP POLICY IF EXISTS "Follows are publicly readable" ON follows;
DROP POLICY IF EXISTS "Users can follow brands" ON follows;
DROP POLICY IF EXISTS "Users can unfollow brands" ON follows;
DROP POLICY IF EXISTS "Non-hidden comments are publicly readable" ON comments;
DROP POLICY IF EXISTS "Authenticated users can comment" ON comments;
DROP POLICY IF EXISTS "Authors can update own comments" ON comments;
DROP POLICY IF EXISTS "Authors can delete own comments" ON comments;
DROP POLICY IF EXISTS "Reactions are publicly readable" ON reactions;
DROP POLICY IF EXISTS "Users can add reactions" ON reactions;
DROP POLICY IF EXISTS "Users can remove own reactions" ON reactions;
DROP POLICY IF EXISTS "Users can view own bookmarks" ON bookmarks;
DROP POLICY IF EXISTS "Users can add bookmarks" ON bookmarks;
DROP POLICY IF EXISTS "Users can remove own bookmarks" ON bookmarks;
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;

-- Drop all tables (cascade handles FKs)
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS bookmarks CASCADE;
DROP TABLE IF EXISTS reactions CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS follows CASCADE;
DROP TABLE IF EXISTS promotions CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS brand_profiles CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- Drop old enums
DROP TYPE IF EXISTS notification_type;
DROP TYPE IF EXISTS subscription_tier;
DROP TYPE IF EXISTS reaction_type;
DROP TYPE IF EXISTS post_status;
DROP TYPE IF EXISTS post_type;
DROP TYPE IF EXISTS account_type;

-- Clean up any orphaned auth users
DELETE FROM auth.users;

-- =============================================================================
-- STEP 2: Create new enums (no more account_type)
-- =============================================================================

CREATE TYPE post_type AS ENUM ('article', 'promotion', 'news', 'update', 'tip');
CREATE TYPE post_status AS ENUM ('draft', 'published', 'archived');
CREATE TYPE reaction_type AS ENUM ('like', 'fire', 'money', 'trophy');
CREATE TYPE subscription_tier AS ENUM ('free', 'paid');
CREATE TYPE notification_type AS ENUM ('new_post', 'comment_reply', 'new_follower', 'promotion', 'mention');
CREATE TYPE brand_role AS ENUM ('owner', 'admin', 'editor', 'viewer');

-- =============================================================================
-- STEP 3: PROFILES (all users — no account_type)
-- =============================================================================

CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    country_code TEXT,
    betting_interests TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profiles_username ON profiles(username);

-- =============================================================================
-- STEP 4: BRAND PROFILES (created by users, not tied to auth)
-- =============================================================================

CREATE TABLE brand_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
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

CREATE INDEX idx_brand_profiles_slug ON brand_profiles(slug);
CREATE INDEX idx_brand_profiles_owner ON brand_profiles(owner_id);
CREATE INDEX idx_brand_profiles_categories ON brand_profiles USING GIN(categories);
CREATE INDEX idx_brand_profiles_verified ON brand_profiles(is_verified) WHERE is_verified = TRUE;

-- =============================================================================
-- STEP 5: BRAND MEMBERS (multi-user team access)
-- =============================================================================

CREATE TABLE brand_members (
    brand_id UUID NOT NULL REFERENCES brand_profiles(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    role brand_role NOT NULL DEFAULT 'viewer',
    invited_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (brand_id, user_id)
);

CREATE INDEX idx_brand_members_user ON brand_members(user_id);

-- =============================================================================
-- STEP 6: POSTS
-- =============================================================================

CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand_id UUID NOT NULL REFERENCES brand_profiles(id) ON DELETE CASCADE,
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
    is_paywalled BOOLEAN NOT NULL DEFAULT FALSE,
    like_count INTEGER NOT NULL DEFAULT 0,
    comment_count INTEGER NOT NULL DEFAULT 0,
    share_count INTEGER NOT NULL DEFAULT 0,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(brand_id, slug)
);

CREATE INDEX idx_posts_brand_id ON posts(brand_id);
CREATE INDEX idx_posts_author_id ON posts(author_id);
CREATE INDEX idx_posts_status ON posts(status);
CREATE INDEX idx_posts_published_at ON posts(published_at DESC) WHERE status = 'published';
CREATE INDEX idx_posts_post_type ON posts(post_type);
CREATE INDEX idx_posts_search ON posts USING GIN(
    to_tsvector('english', COALESCE(title, '') || ' ' || COALESCE(excerpt, ''))
);

-- =============================================================================
-- STEP 7: PROMOTIONS
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
-- STEP 8: FOLLOWS (users follow brands)
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
-- STEP 9: COMMENTS
-- =============================================================================

CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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
-- STEP 10: REACTIONS
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
-- STEP 11: BOOKMARKS
-- =============================================================================

CREATE TABLE bookmarks (
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, post_id)
);

CREATE INDEX idx_bookmarks_user_id ON bookmarks(user_id);

-- =============================================================================
-- STEP 12: NOTIFICATIONS
-- =============================================================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    type notification_type NOT NULL,
    data JSONB NOT NULL DEFAULT '{}',
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;

-- =============================================================================
-- STEP 13: TRIGGERS
-- =============================================================================

-- Auto-update timestamps
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER brand_profiles_updated_at
    BEFORE UPDATE ON brand_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER posts_updated_at
    BEFORE UPDATE ON posts FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER comments_updated_at
    BEFORE UPDATE ON comments FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Follower count
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
    AFTER INSERT OR DELETE ON follows FOR EACH ROW EXECUTE FUNCTION update_follower_count();

-- Auto-create profile on signup (simple — user only, no brand)
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    base_username TEXT;
    final_username TEXT;
    username_counter INTEGER := 0;
BEGIN
    base_username := COALESCE(
        NEW.raw_user_meta_data->>'username',
        SPLIT_PART(NEW.email, '@', 1)
    );
    base_username := LOWER(REGEXP_REPLACE(base_username, '[^a-zA-Z0-9_]', '', 'g'));
    IF base_username = '' THEN
        base_username := 'user';
    END IF;

    final_username := base_username;
    WHILE EXISTS (SELECT 1 FROM profiles WHERE username = final_username) LOOP
        username_counter := username_counter + 1;
        final_username := base_username || username_counter::TEXT;
    END LOOP;

    INSERT INTO public.profiles (id, username, display_name)
    VALUES (
        NEW.id,
        final_username,
        COALESCE(NEW.raw_user_meta_data->>'display_name', final_username)
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Auto-add brand owner to brand_members on brand creation
CREATE OR REPLACE FUNCTION add_brand_owner_as_member()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO brand_members (brand_id, user_id, role)
    VALUES (NEW.id, NEW.owner_id, 'owner');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER brand_created_add_owner
    AFTER INSERT ON brand_profiles
    FOR EACH ROW EXECUTE FUNCTION add_brand_owner_as_member();

-- =============================================================================
-- STEP 14: ROW LEVEL SECURITY
-- =============================================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE brand_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE brand_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- PROFILES
CREATE POLICY "Profiles are publicly readable"
    ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE USING (auth.uid() = id);

-- BRAND PROFILES
CREATE POLICY "Brand profiles are publicly readable"
    ON brand_profiles FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create brands"
    ON brand_profiles FOR INSERT
    WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Brand owners can update their brand"
    ON brand_profiles FOR UPDATE
    USING (auth.uid() = owner_id OR EXISTS (
        SELECT 1 FROM brand_members
        WHERE brand_members.brand_id = brand_profiles.id
        AND brand_members.user_id = auth.uid()
        AND brand_members.role IN ('owner', 'admin')
    ));
CREATE POLICY "Brand owners can delete their brand"
    ON brand_profiles FOR DELETE
    USING (auth.uid() = owner_id);

-- BRAND MEMBERS
CREATE POLICY "Brand members visible to team"
    ON brand_members FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM brand_members bm
            WHERE bm.brand_id = brand_members.brand_id
            AND bm.user_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM brand_profiles bp
            WHERE bp.id = brand_members.brand_id
            AND bp.owner_id = auth.uid()
        )
    );
CREATE POLICY "Brand owners and admins can manage members"
    ON brand_members FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM brand_members bm
            WHERE bm.brand_id = brand_members.brand_id
            AND bm.user_id = auth.uid()
            AND bm.role IN ('owner', 'admin')
        )
        OR EXISTS (
            SELECT 1 FROM brand_profiles bp
            WHERE bp.id = brand_members.brand_id
            AND bp.owner_id = auth.uid()
        )
    );
CREATE POLICY "Brand owners and admins can remove members"
    ON brand_members FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM brand_members bm
            WHERE bm.brand_id = brand_members.brand_id
            AND bm.user_id = auth.uid()
            AND bm.role IN ('owner', 'admin')
        )
    );

-- POSTS
CREATE POLICY "Published posts are publicly readable"
    ON posts FOR SELECT
    USING (status = 'published' OR auth.uid() = author_id);
CREATE POLICY "Brand members can create posts"
    ON posts FOR INSERT
    WITH CHECK (
        auth.uid() = author_id
        AND EXISTS (
            SELECT 1 FROM brand_members
            WHERE brand_members.brand_id = posts.brand_id
            AND brand_members.user_id = auth.uid()
            AND brand_members.role IN ('owner', 'admin', 'editor')
        )
    );
CREATE POLICY "Authors can update own posts"
    ON posts FOR UPDATE USING (auth.uid() = author_id);
CREATE POLICY "Authors can delete own posts"
    ON posts FOR DELETE USING (auth.uid() = author_id);

-- PROMOTIONS
CREATE POLICY "Promotions are publicly readable"
    ON promotions FOR SELECT USING (true);
CREATE POLICY "Post authors can manage promotions"
    ON promotions FOR ALL
    USING (EXISTS (
        SELECT 1 FROM posts WHERE posts.id = promotions.id AND posts.author_id = auth.uid()
    ));

-- FOLLOWS
CREATE POLICY "Follows are publicly readable"
    ON follows FOR SELECT USING (true);
CREATE POLICY "Users can follow brands"
    ON follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "Users can unfollow brands"
    ON follows FOR DELETE USING (auth.uid() = follower_id);

-- COMMENTS
CREATE POLICY "Non-hidden comments are publicly readable"
    ON comments FOR SELECT USING (is_hidden = false OR auth.uid() = author_id);
CREATE POLICY "Authenticated users can comment"
    ON comments FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Authors can update own comments"
    ON comments FOR UPDATE USING (auth.uid() = author_id);
CREATE POLICY "Authors can delete own comments"
    ON comments FOR DELETE USING (auth.uid() = author_id);

-- REACTIONS
CREATE POLICY "Reactions are publicly readable"
    ON reactions FOR SELECT USING (true);
CREATE POLICY "Users can add reactions"
    ON reactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can remove own reactions"
    ON reactions FOR DELETE USING (auth.uid() = user_id);

-- BOOKMARKS
CREATE POLICY "Users can view own bookmarks"
    ON bookmarks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can add bookmarks"
    ON bookmarks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can remove own bookmarks"
    ON bookmarks FOR DELETE USING (auth.uid() = user_id);

-- NOTIFICATIONS
CREATE POLICY "Users can view own notifications"
    ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications"
    ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- =============================================================================
-- DONE! New structure: Users first, Brands created from profile.
-- =============================================================================
