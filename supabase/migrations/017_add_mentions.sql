-- Add mentions table to track @mentions in comments
CREATE TABLE IF NOT EXISTS mentions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  comment_id UUID NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
  mentioned_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  mentioned_brand_id UUID REFERENCES brand_profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),

  -- Ensure either user or brand is mentioned, not both
  CONSTRAINT check_mention_target CHECK (
    (mentioned_user_id IS NOT NULL AND mentioned_brand_id IS NULL) OR
    (mentioned_user_id IS NULL AND mentioned_brand_id IS NOT NULL)
  )
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_mentions_comment_id ON mentions(comment_id);
CREATE INDEX IF NOT EXISTS idx_mentions_user_id ON mentions(mentioned_user_id) WHERE mentioned_user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_mentions_brand_id ON mentions(mentioned_brand_id) WHERE mentioned_brand_id IS NOT NULL;

-- RLS Policies
ALTER TABLE mentions ENABLE ROW LEVEL SECURITY;

-- Anyone can read mentions
DO $$ BEGIN
  CREATE POLICY "Mentions are viewable by everyone"
    ON mentions FOR SELECT
    USING (true);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Only the comment author can create mentions (this will be enforced via the comment creation)
DO $$ BEGIN
  CREATE POLICY "Users can create mentions on their own comments"
    ON mentions FOR INSERT
    WITH CHECK (
      EXISTS (
        SELECT 1 FROM comments
        WHERE comments.id = comment_id
        AND comments.author_id = auth.uid()
      )
    );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Create notification trigger for mentions
CREATE OR REPLACE FUNCTION create_mention_notification() RETURNS TRIGGER AS $$
DECLARE
  v_author_id UUID;
  v_post_id UUID;
  v_post_slug TEXT;
  v_post_title TEXT;
  v_brand_id UUID;
BEGIN
  -- Get comment and post details
  SELECT author_id, post_id
  INTO v_author_id, v_post_id
  FROM comments
  WHERE id = NEW.comment_id;

  SELECT slug, title, brand_id
  INTO v_post_slug, v_post_title, v_brand_id
  FROM posts
  WHERE id = v_post_id;

  -- Create notification for mentioned user
  IF NEW.mentioned_user_id IS NOT NULL THEN
    INSERT INTO notifications (user_id, type, data)
    VALUES (
      NEW.mentioned_user_id,
      'mention',
      jsonb_build_object(
        'comment_id', NEW.comment_id,
        'post_id', v_post_id,
        'post_slug', v_post_slug,
        'post_title', v_post_title,
        'brand_id', v_brand_id,
        'commenter_id', v_author_id
      )
    );
  END IF;

  -- Create notification for mentioned brand (notify brand owner)
  IF NEW.mentioned_brand_id IS NOT NULL THEN
    INSERT INTO notifications (user_id, type, data)
    SELECT
      owner_id,
      'mention',
      jsonb_build_object(
        'comment_id', NEW.comment_id,
        'post_id', v_post_id,
        'post_slug', v_post_slug,
        'post_title', v_post_title,
        'brand_id', NEW.mentioned_brand_id,
        'commenter_id', v_author_id
      )
    FROM brand_profiles
    WHERE id = NEW.mentioned_brand_id
    AND owner_id IS NOT NULL
    AND owner_id <> v_author_id; -- Don't notify yourself
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_create_mention_notification ON mentions;
CREATE TRIGGER trigger_create_mention_notification
  AFTER INSERT ON mentions
  FOR EACH ROW
  EXECUTE FUNCTION create_mention_notification();
