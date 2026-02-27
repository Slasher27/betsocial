-- Verify and fix brand_id nullable constraint
-- This migration is idempotent and can be run multiple times safely

-- Check current state and make brand_id nullable if it isn't already
DO $$
BEGIN
    -- Make brand_id nullable in posts table
    ALTER TABLE posts ALTER COLUMN brand_id DROP NOT NULL;
    RAISE NOTICE 'Successfully made brand_id nullable';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'brand_id may already be nullable or error occurred: %', SQLERRM;
END $$;

-- Add helpful comment
COMMENT ON COLUMN posts.brand_id IS 'Brand this post belongs to. NULL for personal posts by individual users.';

-- Verify the change by showing column info
SELECT
    column_name,
    is_nullable,
    data_type
FROM information_schema.columns
WHERE table_name = 'posts'
AND column_name = 'brand_id';
