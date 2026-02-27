-- Migration 017: Add Trending Posts and Leaderboard Functions
-- Creates helper functions for the Explore page

-- =====================================================
-- 1. Trending Posts Function
-- =====================================================
-- Returns trending posts from last 7 days, sorted by engagement score
-- Score: (likes * 1) + (comments * 3) + (shares * 2) + recency_boost

CREATE OR REPLACE FUNCTION get_trending_posts(
  days_back INTEGER DEFAULT 7,
  result_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  slug TEXT,
  excerpt TEXT,
  cover_image_url TEXT,
  published_at TIMESTAMPTZ,
  like_count INTEGER,
  comment_count INTEGER,
  share_count INTEGER,
  brand_id UUID,
  brand_name TEXT,
  brand_slug TEXT,
  brand_logo_url TEXT,
  author_id UUID,
  author_username TEXT,
  engagement_score NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.title,
    p.slug,
    p.excerpt,
    p.cover_image_url,
    p.published_at,
    p.like_count,
    p.comment_count,
    p.share_count,
    p.brand_id,
    bp.brand_name,
    bp.slug as brand_slug,
    bp.logo_url as brand_logo_url,
    p.author_id,
    pr.username as author_username,
    -- Engagement score with recency boost
    (
      (p.like_count * 1.0) +
      (p.comment_count * 3.0) +
      (p.share_count * 2.0) +
      -- Recency boost: newer posts get higher score
      (EXTRACT(EPOCH FROM (NOW() - p.published_at)) / 86400.0) * -0.5
    )::NUMERIC as engagement_score
  FROM posts p
  LEFT JOIN brand_profiles bp ON p.brand_id = bp.id
  LEFT JOIN profiles pr ON p.author_id = pr.id
  WHERE
    p.status = 'published'
    AND p.published_at >= NOW() - (days_back || ' days')::INTERVAL
  ORDER BY engagement_score DESC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- 2. Top Brands Leaderboard Function
-- =====================================================
-- Returns top brands by follower count, engagement, and growth

CREATE OR REPLACE FUNCTION get_top_brands(
  result_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  brand_name TEXT,
  slug TEXT,
  logo_url TEXT,
  description TEXT,
  follower_count INTEGER,
  total_posts INTEGER,
  total_engagement INTEGER,
  categories TEXT[]
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    bp.id,
    bp.brand_name,
    bp.slug,
    bp.logo_url,
    bp.description,
    bp.follower_count,
    COUNT(DISTINCT p.id)::INTEGER as total_posts,
    (COALESCE(SUM(p.like_count), 0) + COALESCE(SUM(p.comment_count), 0))::INTEGER as total_engagement,
    bp.categories
  FROM brand_profiles bp
  LEFT JOIN posts p ON p.brand_id = bp.id AND p.status = 'published'
  GROUP BY bp.id
  ORDER BY bp.follower_count DESC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- 3. Grant permissions
-- =====================================================
GRANT EXECUTE ON FUNCTION get_trending_posts TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_top_brands TO authenticated, anon;
