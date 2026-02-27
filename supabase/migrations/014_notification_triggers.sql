-- =============================================================================
-- MIGRATION 014: Notification Triggers
-- Automatically insert notification rows when key events occur:
--   1. new_post    — brand publishes a post → notify all followers
--   2. comment_reply — someone comments on a post → notify the post author
--   3. new_follower — someone follows a brand → notify the brand owner
-- =============================================================================


-- =============================================================================
-- 1. NEW POST NOTIFICATION
-- Fires when a post transitions to status='published'.
-- Inserts one notification row per follower of the brand.
-- =============================================================================

CREATE OR REPLACE FUNCTION notify_new_post()
RETURNS TRIGGER AS $$
BEGIN
    -- Only trigger when status changes TO 'published'
    IF NEW.status = 'published' AND (OLD.status IS NULL OR OLD.status <> 'published') THEN
        -- Only notify for brand posts (brand_id is not null)
        IF NEW.brand_id IS NOT NULL THEN
            INSERT INTO notifications (user_id, type, data)
            SELECT
                f.follower_id,
                'new_post',
                jsonb_build_object(
                    'post_id',    NEW.id,
                    'post_title', NEW.title,
                    'post_slug',  NEW.slug,
                    'brand_id',   NEW.brand_id
                )
            FROM follows f
            WHERE f.brand_id = NEW.brand_id
              -- Don't notify the author themselves
              AND f.follower_id <> NEW.author_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_new_post
    AFTER INSERT OR UPDATE OF status ON posts
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_post();


-- =============================================================================
-- 2. COMMENT REPLY NOTIFICATION
-- Fires when a comment is inserted on a post.
-- Notifies the post author (or the parent comment author for replies).
-- Does NOT notify the commenter themselves.
-- =============================================================================

CREATE OR REPLACE FUNCTION notify_comment_reply()
RETURNS TRIGGER AS $$
DECLARE
    v_post_author_id UUID;
    v_parent_author_id UUID;
    v_post_slug TEXT;
    v_post_title TEXT;
    v_brand_id UUID;
BEGIN
    -- Get post details
    SELECT author_id, slug, title, brand_id
    INTO v_post_author_id, v_post_slug, v_post_title, v_brand_id
    FROM posts
    WHERE id = NEW.post_id;

    IF NEW.parent_id IS NOT NULL THEN
        -- This is a reply — notify the parent comment author
        SELECT author_id INTO v_parent_author_id
        FROM comments
        WHERE id = NEW.parent_id;

        -- Notify parent comment author (if not the replier themselves)
        IF v_parent_author_id IS NOT NULL AND v_parent_author_id <> NEW.author_id THEN
            INSERT INTO notifications (user_id, type, data)
            VALUES (
                v_parent_author_id,
                'comment_reply',
                jsonb_build_object(
                    'comment_id',  NEW.id,
                    'post_id',     NEW.post_id,
                    'post_slug',   v_post_slug,
                    'post_title',  v_post_title,
                    'brand_id',    v_brand_id,
                    'commenter_id', NEW.author_id
                )
            );
        END IF;
    ELSE
        -- This is a top-level comment — notify the post author
        IF v_post_author_id IS NOT NULL AND v_post_author_id <> NEW.author_id THEN
            INSERT INTO notifications (user_id, type, data)
            VALUES (
                v_post_author_id,
                'comment_reply',
                jsonb_build_object(
                    'comment_id',  NEW.id,
                    'post_id',     NEW.post_id,
                    'post_slug',   v_post_slug,
                    'post_title',  v_post_title,
                    'brand_id',    v_brand_id,
                    'commenter_id', NEW.author_id
                )
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_comment_reply
    AFTER INSERT ON comments
    FOR EACH ROW
    EXECUTE FUNCTION notify_comment_reply();


-- =============================================================================
-- 3. NEW FOLLOWER NOTIFICATION
-- Fires when a follow row is inserted.
-- Notifies the brand owner that someone new followed their brand.
-- =============================================================================

CREATE OR REPLACE FUNCTION notify_new_follower()
RETURNS TRIGGER AS $$
DECLARE
    v_brand_owner_id UUID;
    v_brand_name TEXT;
    v_brand_slug TEXT;
BEGIN
    -- Get brand owner and details
    SELECT owner_id, brand_name, slug
    INTO v_brand_owner_id, v_brand_name, v_brand_slug
    FROM brand_profiles
    WHERE id = NEW.brand_id;

    -- Notify brand owner (but not if they followed their own brand)
    IF v_brand_owner_id IS NOT NULL AND v_brand_owner_id <> NEW.follower_id THEN
        INSERT INTO notifications (user_id, type, data)
        VALUES (
            v_brand_owner_id,
            'new_follower',
            jsonb_build_object(
                'follower_id', NEW.follower_id,
                'brand_id',    NEW.brand_id,
                'brand_name',  v_brand_name,
                'brand_slug',  v_brand_slug
            )
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_new_follower
    AFTER INSERT ON follows
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_follower();


-- =============================================================================
-- Enable Realtime on notifications table so the client can subscribe
-- =============================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
