-- =============================================================================
-- Add brand_id to comments and pulse_comments to support brand context commenting
-- =============================================================================

-- Add brand_id to comments table with named constraint
ALTER TABLE comments
ADD COLUMN brand_id UUID;

ALTER TABLE comments
ADD CONSTRAINT comments_brand_id_fkey
FOREIGN KEY (brand_id)
REFERENCES brand_profiles(id)
ON DELETE CASCADE;

-- Add brand_id to pulse_comments table with named constraint
ALTER TABLE pulse_comments
ADD COLUMN brand_id UUID;

ALTER TABLE pulse_comments
ADD CONSTRAINT pulse_comments_brand_id_fkey
FOREIGN KEY (brand_id)
REFERENCES brand_profiles(id)
ON DELETE CASCADE;

-- Add indexes for performance
CREATE INDEX idx_comments_brand_id ON comments(brand_id) WHERE brand_id IS NOT NULL;
CREATE INDEX idx_pulse_comments_brand_id ON pulse_comments(brand_id) WHERE brand_id IS NOT NULL;

-- Comments will work like posts:
-- If brand_id is NULL, it's a personal comment by the user (author_id)
-- If brand_id is set, it's a comment made in brand context (still tracks author_id for audit)
