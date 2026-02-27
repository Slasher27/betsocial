-- =============================================================================
-- Allow Users to Create Posts (like Substack)
-- =============================================================================

-- Make brand_id nullable so users can create posts too
ALTER TABLE posts ALTER COLUMN brand_id DROP NOT NULL;

-- Update the unique constraint to handle both user and brand posts
ALTER TABLE posts DROP CONSTRAINT IF EXISTS posts_brand_id_slug_key;

-- Add a new unique constraint that works for both user posts and brand posts
-- For brand posts: brand_id + slug must be unique
-- For user posts: author_id + slug must be unique
CREATE UNIQUE INDEX posts_brand_slug_unique
    ON posts(brand_id, slug)
    WHERE brand_id IS NOT NULL;

CREATE UNIQUE INDEX posts_author_slug_unique
    ON posts(author_id, slug)
    WHERE brand_id IS NULL;

-- Update RLS policy to allow all authenticated users to create posts
DROP POLICY IF EXISTS "Brand owners can create posts" ON posts;

CREATE POLICY "Authenticated users can create posts"
    ON posts FOR INSERT
    WITH CHECK (auth.uid() = author_id);

-- Add comment to clarify the new structure
COMMENT ON COLUMN posts.brand_id IS 'NULL for user posts, populated for brand posts';

-- =============================================================================
-- DONE! Users can now create posts alongside brands
-- =============================================================================
