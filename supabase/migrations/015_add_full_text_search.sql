-- Migration 015: Add Full-Text Search
-- Adds Postgres full-text search capabilities to posts, brands, and profiles

-- =====================================================
-- 1. Add search_vector columns
-- =====================================================

-- Posts: Search on title, excerpt, and content (text extracted from JSONB)
ALTER TABLE posts ADD COLUMN IF NOT EXISTS search_vector tsvector;

-- Brand profiles: Search on brand_name and description
ALTER TABLE brand_profiles ADD COLUMN IF NOT EXISTS search_vector tsvector;

-- User profiles: Search on username and display_name
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS search_vector tsvector;

-- =====================================================
-- 2. Create GIN indexes for fast full-text search
-- =====================================================

CREATE INDEX IF NOT EXISTS posts_search_idx ON posts USING gin(search_vector);
CREATE INDEX IF NOT EXISTS brand_profiles_search_idx ON brand_profiles USING gin(search_vector);
CREATE INDEX IF NOT EXISTS profiles_search_idx ON profiles USING gin(search_vector);

-- =====================================================
-- 3. Create functions to update search vectors
-- =====================================================

-- Posts search vector update function
CREATE OR REPLACE FUNCTION update_posts_search_vector() RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('english', coalesce(NEW.title, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(NEW.excerpt, '')), 'B') ||
    setweight(to_tsvector('english', coalesce(NEW.slug, '')), 'C');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Brand profiles search vector update function
CREATE OR REPLACE FUNCTION update_brand_profiles_search_vector() RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('english', coalesce(NEW.brand_name, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(NEW.slug, '')), 'B') ||
    setweight(to_tsvector('english', coalesce(NEW.description, '')), 'C');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Profiles search vector update function
CREATE OR REPLACE FUNCTION update_profiles_search_vector() RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('english', coalesce(NEW.username, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(NEW.display_name, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(NEW.bio, '')), 'C');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 4. Create triggers to auto-update search vectors
-- =====================================================

DROP TRIGGER IF EXISTS posts_search_vector_update ON posts;
CREATE TRIGGER posts_search_vector_update
  BEFORE INSERT OR UPDATE OF title, excerpt, slug
  ON posts
  FOR EACH ROW
  EXECUTE FUNCTION update_posts_search_vector();

DROP TRIGGER IF EXISTS brand_profiles_search_vector_update ON brand_profiles;
CREATE TRIGGER brand_profiles_search_vector_update
  BEFORE INSERT OR UPDATE OF brand_name, slug, description
  ON brand_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_brand_profiles_search_vector();

DROP TRIGGER IF EXISTS profiles_search_vector_update ON profiles;
CREATE TRIGGER profiles_search_vector_update
  BEFORE INSERT OR UPDATE OF username, display_name, bio
  ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_profiles_search_vector();

-- =====================================================
-- 5. Populate search vectors for existing rows
-- =====================================================

-- Update all existing posts
UPDATE posts SET search_vector =
  setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
  setweight(to_tsvector('english', coalesce(excerpt, '')), 'B') ||
  setweight(to_tsvector('english', coalesce(slug, '')), 'C');

-- Update all existing brand profiles
UPDATE brand_profiles SET search_vector =
  setweight(to_tsvector('english', coalesce(brand_name, '')), 'A') ||
  setweight(to_tsvector('english', coalesce(slug, '')), 'B') ||
  setweight(to_tsvector('english', coalesce(description, '')), 'C');

-- Update all existing profiles
UPDATE profiles SET search_vector =
  setweight(to_tsvector('english', coalesce(username, '')), 'A') ||
  setweight(to_tsvector('english', coalesce(display_name, '')), 'A') ||
  setweight(to_tsvector('english', coalesce(bio, '')), 'C');

-- =====================================================
-- 6. Create search helper function (optional)
-- =====================================================

-- Helper function to search across all entities
-- Returns combined results with entity type
CREATE OR REPLACE FUNCTION search_all(search_query TEXT, result_limit INT DEFAULT 20)
RETURNS TABLE(
  entity_type TEXT,
  entity_id UUID,
  title TEXT,
  subtitle TEXT,
  url TEXT,
  rank REAL
) AS $$
BEGIN
  RETURN QUERY

  WITH all_results AS (
    -- Search posts
    SELECT
      'post'::TEXT as entity_type,
      p.id as entity_id,
      p.title as title,
      p.excerpt as subtitle,
      CASE
        WHEN p.brand_id IS NOT NULL THEN '/' || bp.slug || '/' || p.slug
        ELSE '/u/' || pr.username || '/' || p.slug
      END as url,
      ts_rank(p.search_vector, websearch_to_tsquery('english', search_query)) as rank
    FROM posts p
    LEFT JOIN brand_profiles bp ON p.brand_id = bp.id
    LEFT JOIN profiles pr ON p.author_id = pr.id
    WHERE p.search_vector @@ websearch_to_tsquery('english', search_query)
      AND p.status = 'published'

    UNION ALL

    -- Search brands
    SELECT
      'brand'::TEXT as entity_type,
      bp.id as entity_id,
      bp.brand_name as title,
      bp.description as subtitle,
      '/' || bp.slug as url,
      ts_rank(bp.search_vector, websearch_to_tsquery('english', search_query)) as rank
    FROM brand_profiles bp
    WHERE bp.search_vector @@ websearch_to_tsquery('english', search_query)

    UNION ALL

    -- Search users
    SELECT
      'user'::TEXT as entity_type,
      p.id as entity_id,
      COALESCE(p.display_name, p.username) as title,
      p.bio as subtitle,
      '/u/' || p.username as url,
      ts_rank(p.search_vector, websearch_to_tsquery('english', search_query)) as rank
    FROM profiles p
    WHERE p.search_vector @@ websearch_to_tsquery('english', search_query)
      AND p.account_type = 'user'
  )
  SELECT * FROM all_results
  ORDER BY rank DESC
  LIMIT result_limit;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION search_all(TEXT, INT) TO authenticated;

COMMENT ON FUNCTION search_all IS 'Full-text search across posts, brands, and users';
