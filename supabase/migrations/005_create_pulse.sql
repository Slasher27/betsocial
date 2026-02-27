-- Create Pulse table for short-form content (like Substack Notes / Twitter)
-- Pulse posts are quick thoughts, tips, updates from users and brands

CREATE TABLE pulse_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    brand_id UUID REFERENCES brand_profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL CHECK (char_length(content) <= 500), -- 500 char limit
    image_url TEXT,
    link_url TEXT,
    link_title TEXT,
    link_description TEXT,
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    repost_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_pulse_author_id ON pulse_posts(author_id);
CREATE INDEX idx_pulse_brand_id ON pulse_posts(brand_id);
CREATE INDEX idx_pulse_created_at ON pulse_posts(created_at DESC);

-- Comments on pulse posts (threaded replies)
CREATE TABLE pulse_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pulse_id UUID NOT NULL REFERENCES pulse_posts(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL CHECK (char_length(content) <= 500),
    parent_id UUID REFERENCES pulse_comments(id) ON DELETE CASCADE, -- For threading
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_pulse_comments_pulse_id ON pulse_comments(pulse_id);
CREATE INDEX idx_pulse_comments_author_id ON pulse_comments(author_id);
CREATE INDEX idx_pulse_comments_parent_id ON pulse_comments(parent_id);

-- Pulse reactions (like, fire, etc.)
CREATE TABLE pulse_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pulse_id UUID NOT NULL REFERENCES pulse_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    reaction_type reaction_type NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(pulse_id, user_id, reaction_type)
);

CREATE INDEX idx_pulse_reactions_pulse_id ON pulse_reactions(pulse_id);
CREATE INDEX idx_pulse_reactions_user_id ON pulse_reactions(user_id);

-- Pulse reposts (share to your followers)
CREATE TABLE pulse_reposts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pulse_id UUID NOT NULL REFERENCES pulse_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(pulse_id, user_id)
);

CREATE INDEX idx_pulse_reposts_pulse_id ON pulse_reposts(pulse_id);
CREATE INDEX idx_pulse_reposts_user_id ON pulse_reposts(user_id);

-- Enable RLS
ALTER TABLE pulse_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE pulse_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE pulse_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE pulse_reposts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for pulse_posts
CREATE POLICY "Pulse posts are publicly readable"
    ON pulse_posts FOR SELECT USING (true);

CREATE POLICY "Users can create pulse posts"
    ON pulse_posts FOR INSERT
    WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Authors can update own pulse posts"
    ON pulse_posts FOR UPDATE USING (auth.uid() = author_id);

CREATE POLICY "Authors can delete own pulse posts"
    ON pulse_posts FOR DELETE USING (auth.uid() = author_id);

-- RLS Policies for pulse_comments
CREATE POLICY "Pulse comments are publicly readable"
    ON pulse_comments FOR SELECT USING (true);

CREATE POLICY "Authenticated users can comment on pulse"
    ON pulse_comments FOR INSERT
    WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Authors can update own comments"
    ON pulse_comments FOR UPDATE USING (auth.uid() = author_id);

CREATE POLICY "Authors can delete own comments"
    ON pulse_comments FOR DELETE USING (auth.uid() = author_id);

-- RLS Policies for pulse_reactions
CREATE POLICY "Pulse reactions are publicly readable"
    ON pulse_reactions FOR SELECT USING (true);

CREATE POLICY "Users can add pulse reactions"
    ON pulse_reactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove own pulse reactions"
    ON pulse_reactions FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for pulse_reposts
CREATE POLICY "Pulse reposts are publicly readable"
    ON pulse_reposts FOR SELECT USING (true);

CREATE POLICY "Users can repost pulse posts"
    ON pulse_reposts FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove own reposts"
    ON pulse_reposts FOR DELETE USING (auth.uid() = user_id);

-- Trigger to update updated_at
CREATE TRIGGER update_pulse_posts_updated_at
    BEFORE UPDATE ON pulse_posts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_pulse_comments_updated_at
    BEFORE UPDATE ON pulse_comments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
