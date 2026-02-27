-- =============================================================================
-- Add triggers to automatically update comment_count on posts and pulse_posts
-- =============================================================================

-- Function to update comment count on posts table
CREATE OR REPLACE FUNCTION update_post_comment_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET comment_count = GREATEST(0, comment_count - 1) WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update post comment count on insert/delete
CREATE TRIGGER update_post_comment_count_trigger
    AFTER INSERT OR DELETE ON comments
    FOR EACH ROW
    EXECUTE FUNCTION update_post_comment_count();

-- Function to update comment count on pulse_posts table
CREATE OR REPLACE FUNCTION update_pulse_comment_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE pulse_posts SET comment_count = comment_count + 1 WHERE id = NEW.pulse_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE pulse_posts SET comment_count = GREATEST(0, comment_count - 1) WHERE id = OLD.pulse_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update pulse comment count on insert/delete
CREATE TRIGGER update_pulse_comment_count_trigger
    AFTER INSERT OR DELETE ON pulse_comments
    FOR EACH ROW
    EXECUTE FUNCTION update_pulse_comment_count();
