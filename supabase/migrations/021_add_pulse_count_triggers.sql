-- Migration 021: Add Auto-Update Triggers for Pulse Counts
-- Automatically update like_count and comment_count on pulse_posts

-- =====================================================
-- 1. Function to update like_count on pulse_posts
-- =====================================================
CREATE OR REPLACE FUNCTION update_pulse_like_count()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    -- Increment like_count when a like reaction is added
    IF NEW.reaction_type = 'like' THEN
      UPDATE pulse_posts
      SET like_count = like_count + 1
      WHERE id = NEW.pulse_id;
    END IF;
    RETURN NEW;
  ELSIF (TG_OP = 'DELETE') THEN
    -- Decrement like_count when a like reaction is removed
    IF OLD.reaction_type = 'like' THEN
      UPDATE pulse_posts
      SET like_count = GREATEST(like_count - 1, 0)
      WHERE id = OLD.pulse_id;
    END IF;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 2. Function to update comment_count on pulse_posts
-- =====================================================
CREATE OR REPLACE FUNCTION update_pulse_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    -- Increment comment_count when a comment is added
    UPDATE pulse_posts
    SET comment_count = comment_count + 1
    WHERE id = NEW.pulse_id;
    RETURN NEW;
  ELSIF (TG_OP = 'DELETE') THEN
    -- Decrement comment_count when a comment is removed
    UPDATE pulse_posts
    SET comment_count = GREATEST(comment_count - 1, 0)
    WHERE id = OLD.pulse_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. Create triggers
-- =====================================================
DROP TRIGGER IF EXISTS pulse_reactions_like_count_trigger ON pulse_reactions;
CREATE TRIGGER pulse_reactions_like_count_trigger
  AFTER INSERT OR DELETE ON pulse_reactions
  FOR EACH ROW
  EXECUTE FUNCTION update_pulse_like_count();

DROP TRIGGER IF EXISTS pulse_comments_count_trigger ON pulse_comments;
CREATE TRIGGER pulse_comments_count_trigger
  AFTER INSERT OR DELETE ON pulse_comments
  FOR EACH ROW
  EXECUTE FUNCTION update_pulse_comment_count();

-- =====================================================
-- 4. Recalculate existing counts (fix any inconsistencies)
-- =====================================================
-- Update like_count for all pulse posts
UPDATE pulse_posts p
SET like_count = (
  SELECT COUNT(*)
  FROM pulse_reactions pr
  WHERE pr.pulse_id = p.id
  AND pr.reaction_type = 'like'
);

-- Update comment_count for all pulse posts
UPDATE pulse_posts p
SET comment_count = (
  SELECT COUNT(*)
  FROM pulse_comments pc
  WHERE pc.pulse_id = p.id
);
