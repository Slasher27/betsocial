-- Fix infinite recursion in brand_members RLS policies
-- The issue: brand_profiles UPDATE policy checks brand_members,
-- and brand_members SELECT policy also checks brand_members (infinite loop)

-- Drop problematic policies
DROP POLICY IF EXISTS "Brand members visible to team" ON brand_members;
DROP POLICY IF EXISTS "Brand owners and admins can manage members" ON brand_members;
DROP POLICY IF EXISTS "Brand owners and admins can remove members" ON brand_members;

-- Recreate with proper references to brand_profiles.owner_id
CREATE POLICY "Brand members visible to team"
    ON brand_members FOR SELECT
    USING (
        -- User can see members if they own the brand
        EXISTS (
            SELECT 1 FROM brand_profiles bp
            WHERE bp.id = brand_members.brand_id
            AND bp.owner_id = auth.uid()
        )
        -- OR if they are themselves a member (for future team features)
        OR brand_members.user_id = auth.uid()
    );

CREATE POLICY "Brand owners can manage members"
    ON brand_members FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM brand_profiles bp
            WHERE bp.id = brand_members.brand_id
            AND bp.owner_id = auth.uid()
        )
    );

CREATE POLICY "Brand owners can update members"
    ON brand_members FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM brand_profiles bp
            WHERE bp.id = brand_members.brand_id
            AND bp.owner_id = auth.uid()
        )
    );

CREATE POLICY "Brand owners can remove members"
    ON brand_members FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM brand_profiles bp
            WHERE bp.id = brand_members.brand_id
            AND bp.owner_id = auth.uid()
        )
    );
