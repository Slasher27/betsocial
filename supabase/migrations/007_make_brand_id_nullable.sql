-- Make brand_id nullable in posts table to allow personal posts
-- Users should be able to create posts without a brand (personal posts)

ALTER TABLE posts ALTER COLUMN brand_id DROP NOT NULL;

-- Add a comment explaining the change
COMMENT ON COLUMN posts.brand_id IS 'Brand this post belongs to. NULL for personal posts.';
