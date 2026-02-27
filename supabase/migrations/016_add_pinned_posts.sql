-- Migration 016: Add Pinned Posts
-- Allows brands to pin one post to the top of their profile

-- =====================================================
-- 1. Add is_pinned column to posts
-- =====================================================

ALTER TABLE posts ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT false;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS posts_pinned_idx ON posts(is_pinned) WHERE is_pinned = true;

-- =====================================================
-- 2. Create trigger to enforce one pinned post per brand
-- =====================================================

-- Function to ensure only one post is pinned per brand
CREATE OR REPLACE FUNCTION enforce_single_pinned_post() RETURNS TRIGGER AS $$
BEGIN
  -- If this post is being pinned
  IF NEW.is_pinned = true THEN
    -- Unpin all other posts for this brand/author
    IF NEW.brand_id IS NOT NULL THEN
      -- Brand post: unpin other posts from this brand
      UPDATE posts
      SET is_pinned = false
      WHERE brand_id = NEW.brand_id
        AND id != NEW.id
        AND is_pinned = true;
    ELSE
      -- User post: unpin other posts from this author
      UPDATE posts
      SET is_pinned = false
      WHERE author_id = NEW.author_id
        AND brand_id IS NULL
        AND id != NEW.id
        AND is_pinned = true;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS enforce_single_pinned_post_trigger ON posts;
CREATE TRIGGER enforce_single_pinned_post_trigger
  BEFORE INSERT OR UPDATE OF is_pinned
  ON posts
  FOR EACH ROW
  EXECUTE FUNCTION enforce_single_pinned_post();

-- =====================================================
-- 3. Add RLS policy for pinning posts
-- =====================================================

-- Users can pin their own posts
-- (Already covered by existing update policy, but being explicit)

COMMENT ON COLUMN posts.is_pinned IS 'Whether this post is pinned to the top of the brand/user profile. Only one post can be pinned at a time.';
