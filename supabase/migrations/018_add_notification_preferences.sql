-- Add notification preferences column to profiles
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT jsonb_build_object(
    'new_post', true,
    'comment_reply', true,
    'new_follower', true,
    'mention', true,
    'promotion', false
);
