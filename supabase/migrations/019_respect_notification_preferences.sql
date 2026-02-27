-- Update notification triggers to respect user preferences

-- 1. NEW POST NOTIFICATION - check new_post preference
CREATE OR REPLACE FUNCTION notify_new_post()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'published' AND (OLD.status IS NULL OR OLD.status <> 'published') THEN
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
            JOIN profiles p ON p.id = f.follower_id
            WHERE f.brand_id = NEW.brand_id
              AND f.follower_id <> NEW.author_id
              AND (p.notification_preferences->>'new_post')::boolean = true;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. COMMENT REPLY NOTIFICATION - check comment_reply preference
CREATE OR REPLACE FUNCTION notify_comment_reply()
RETURNS TRIGGER AS $$
DECLARE
    v_post_author_id UUID;
    v_parent_author_id UUID;
    v_post_slug TEXT;
    v_post_title TEXT;
    v_brand_id UUID;
    v_notify_enabled BOOLEAN;
BEGIN
    SELECT author_id, slug, title, brand_id
    INTO v_post_author_id, v_post_slug, v_post_title, v_brand_id
    FROM posts
    WHERE id = NEW.post_id;

    IF NEW.parent_id IS NOT NULL THEN
        SELECT author_id INTO v_parent_author_id
        FROM comments
        WHERE id = NEW.parent_id;

        IF v_parent_author_id IS NOT NULL AND v_parent_author_id <> NEW.author_id THEN
            SELECT (notification_preferences->>'comment_reply')::boolean INTO v_notify_enabled
            FROM profiles
            WHERE id = v_parent_author_id;

            IF v_notify_enabled THEN
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
                        'commenter_id', NEW.author_id,
                        'parent_id',   NEW.parent_id
                    )
                );
            END IF;
        END IF;
    ELSE
        IF v_post_author_id IS NOT NULL AND v_post_author_id <> NEW.author_id THEN
            SELECT (notification_preferences->>'comment_reply')::boolean INTO v_notify_enabled
            FROM profiles
            WHERE id = v_post_author_id;

            IF v_notify_enabled THEN
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
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. NEW FOLLOWER NOTIFICATION - check new_follower preference
CREATE OR REPLACE FUNCTION notify_new_follower()
RETURNS TRIGGER AS $$
DECLARE
    v_brand_owner_id UUID;
    v_brand_name TEXT;
    v_brand_slug TEXT;
    v_notify_enabled BOOLEAN;
BEGIN
    SELECT owner_id, brand_name, slug
    INTO v_brand_owner_id, v_brand_name, v_brand_slug
    FROM brand_profiles
    WHERE id = NEW.brand_id;

    IF v_brand_owner_id IS NOT NULL AND v_brand_owner_id <> NEW.follower_id THEN
        SELECT (notification_preferences->>'new_follower')::boolean INTO v_notify_enabled
        FROM profiles
        WHERE id = v_brand_owner_id;

        IF v_notify_enabled THEN
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
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. MENTION NOTIFICATION - check mention preference
CREATE OR REPLACE FUNCTION create_mention_notification()
RETURNS TRIGGER AS $$
DECLARE
  v_author_id UUID;
  v_post_id UUID;
  v_post_slug TEXT;
  v_post_title TEXT;
  v_brand_id UUID;
  v_notify_enabled BOOLEAN;
BEGIN
  SELECT author_id, post_id
  INTO v_author_id, v_post_id
  FROM comments
  WHERE id = NEW.comment_id;

  SELECT slug, title, brand_id
  INTO v_post_slug, v_post_title, v_brand_id
  FROM posts
  WHERE id = v_post_id;

  IF NEW.mentioned_user_id IS NOT NULL THEN
    SELECT (notification_preferences->>'mention')::boolean INTO v_notify_enabled
    FROM profiles
    WHERE id = NEW.mentioned_user_id;

    IF v_notify_enabled THEN
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
  END IF;

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
    JOIN profiles ON profiles.id = brand_profiles.owner_id
    WHERE brand_profiles.id = NEW.mentioned_brand_id
    AND owner_id IS NOT NULL
    AND owner_id <> v_author_id
    AND (profiles.notification_preferences->>'mention')::boolean = true;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
