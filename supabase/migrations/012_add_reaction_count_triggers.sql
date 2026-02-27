-- =============================================================================
-- Add triggers to automatically update like_count on posts when reactions change
-- =============================================================================

-- Function to update like count on posts table
CREATE OR REPLACE FUNCTION update_post_like_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Only increment for 'like' reaction type
        IF NEW.reaction_type = 'like' AND NEW.target_type = 'post' THEN
            UPDATE posts SET like_count = like_count + 1 WHERE id = NEW.target_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        -- Only decrement for 'like' reaction type
        IF OLD.reaction_type = 'like' AND OLD.target_type = 'post' THEN
            UPDATE posts SET like_count = GREATEST(0, like_count - 1) WHERE id = OLD.target_id;
        END IF;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Handle reaction type changes
        IF OLD.target_type = 'post' THEN
            IF OLD.reaction_type = 'like' AND NEW.reaction_type != 'like' THEN
                -- Changed from like to something else - decrement
                UPDATE posts SET like_count = GREATEST(0, like_count - 1) WHERE id = OLD.target_id;
            ELSIF OLD.reaction_type != 'like' AND NEW.reaction_type = 'like' THEN
                -- Changed from something else to like - increment
                UPDATE posts SET like_count = like_count + 1 WHERE id = NEW.target_id;
            END IF;
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update post like count on insert/delete/update
CREATE TRIGGER update_post_like_count_trigger
    AFTER INSERT OR DELETE OR UPDATE ON reactions
    FOR EACH ROW
    EXECUTE FUNCTION update_post_like_count();

-- Function to update like count on comments table
CREATE OR REPLACE FUNCTION update_comment_like_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Only increment for 'like' reaction type on comments
        IF NEW.reaction_type = 'like' AND NEW.target_type = 'comment' THEN
            UPDATE comments SET like_count = like_count + 1 WHERE id = NEW.target_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        -- Only decrement for 'like' reaction type on comments
        IF OLD.reaction_type = 'like' AND OLD.target_type = 'comment' THEN
            UPDATE comments SET like_count = GREATEST(0, like_count - 1) WHERE id = OLD.target_id;
        END IF;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Handle reaction type changes
        IF OLD.target_type = 'comment' THEN
            IF OLD.reaction_type = 'like' AND NEW.reaction_type != 'like' THEN
                -- Changed from like to something else - decrement
                UPDATE comments SET like_count = GREATEST(0, like_count - 1) WHERE id = OLD.target_id;
            ELSIF OLD.reaction_type != 'like' AND NEW.reaction_type = 'like' THEN
                -- Changed from something else to like - increment
                UPDATE comments SET like_count = like_count + 1 WHERE id = NEW.target_id;
            END IF;
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update comment like count on insert/delete/update
CREATE TRIGGER update_comment_like_count_trigger
    AFTER INSERT OR DELETE OR UPDATE ON reactions
    FOR EACH ROW
    EXECUTE FUNCTION update_comment_like_count();
