-- Fix posts RLS policy to allow personal posts (without brand_id)
-- Users should be able to create posts as themselves OR as a brand they own/manage

DROP POLICY IF EXISTS "Brand members can create posts" ON posts;

-- New policy: Users can create posts as themselves OR as a brand they manage
CREATE POLICY "Users can create posts"
    ON posts FOR INSERT
    WITH CHECK (
        -- User is the author
        auth.uid() = author_id
        AND (
            -- Either: Personal post (no brand_id)
            brand_id IS NULL
            OR
            -- Or: Brand post where user owns the brand
            EXISTS (
                SELECT 1 FROM brand_profiles
                WHERE brand_profiles.id = posts.brand_id
                AND brand_profiles.owner_id = auth.uid()
            )
            OR
            -- Or: Brand post where user is a team member with posting permissions
            EXISTS (
                SELECT 1 FROM brand_members
                WHERE brand_members.brand_id = posts.brand_id
                AND brand_members.user_id = auth.uid()
                AND brand_members.role IN ('owner', 'admin', 'editor')
            )
        )
    );
