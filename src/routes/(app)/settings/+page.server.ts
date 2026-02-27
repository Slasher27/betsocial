import { redirect, fail, error } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals: { supabase, safeGetSession }, url }) => {
	try {
		const { session } = await safeGetSession();

		if (!session) {
			throw redirect(303, '/auth/login');
		}

		// Check if in brand context
		const brandSlug = url.searchParams.get('brand');

		// Get user profile
		const { data: profile, error: profileError } = await supabase
			.from('profiles')
			.select('id, username, display_name, avatar_url, banner_url, bio, created_at, website_url, twitter_url, facebook_url, instagram_url, linkedin_url, youtube_url, tiktok_url, substack_url, notification_preferences')
			.eq('id', session.user.id)
			.maybeSingle();

		if (profileError) {
			throw error(500, `Error loading profile: ${profileError.message}`);
		}

		// If no profile exists, create one
		if (!profile) {
			const username = session.user.email?.split('@')[0] || 'user';
			const { error: createError } = await supabase
				.from('profiles')
				.insert({
					id: session.user.id,
					username,
					display_name: username
				});

			if (createError) {
				throw error(500, `Failed to create profile: ${createError.message}`);
			}

			// Reload the page to fetch the new profile
			throw redirect(303, '/settings');
		}

		// Get brands owned by this user
		const { data: brands } = await supabase
			.from('brand_profiles')
			.select('*')
			.eq('owner_id', session.user.id);

		// If brand context requested, verify user owns it and load brand data
		let currentBrand = null;
		if (brandSlug) {
			const { data: brand } = await supabase
				.from('brand_profiles')
				.select('*')
				.eq('slug', brandSlug)
				.eq('owner_id', session.user.id)
				.maybeSingle();

			if (!brand) {
				// User doesn't own this brand, redirect to personal settings
				throw redirect(303, '/settings');
			}

			currentBrand = brand;
		}

		// Get following count (personal - brands user follows)
		const { count: followingCount } = await supabase
			.from('follows')
			.select('*', { count: 'exact', head: true })
			.eq('follower_id', session.user.id);

		// Get list of brands user is following
		const { data: followingList } = await supabase
			.from('follows')
			.select('brand:brand_profiles!follows_brand_id_fkey(id, brand_name, slug, logo_url, follower_count)')
			.eq('follower_id', session.user.id);

		// Get followers data (for brand context)
		let followersCount = 0;
		let followersList = [];
		let brandMembers = [];
		if (currentBrand) {
			const { count } = await supabase
				.from('follows')
				.select('*', { count: 'exact', head: true })
				.eq('brand_id', currentBrand.id);
			followersCount = count || 0;

			const { data: followers } = await supabase
				.from('follows')
				.select('follower:profiles!follows_follower_id_fkey(id, username, display_name, avatar_url)')
				.eq('brand_id', currentBrand.id);
			followersList = followers || [];

			// Get brand members
			const { data: members } = await supabase
				.from('brand_members')
				.select('role, created_at, user:profiles!brand_members_user_id_fkey(id, username, display_name, avatar_url), invited_by')
				.eq('brand_id', currentBrand.id)
				.order('created_at', { ascending: true });
			brandMembers = members || [];
		}

		return {
			profile,
			brands: brands || [],
			brand: currentBrand, // Current brand context
			followingCount: followingCount || 0,
			following: followingList || [],
			followersCount,
			followers: followersList,
			brandMembers,
			session
		};
	} catch (err) {
		throw error(500, `Server error: ${err instanceof Error ? err.message : 'Unknown error'}`);
	}
};

export const actions: Actions = {
	updateProfile: async ({ request, locals: { supabase, safeGetSession } }) => {
		const { session } = await safeGetSession();
		if (!session) return fail(401, { error: 'Unauthorized' });

		const formData = await request.formData();
		const username = formData.get('username') as string;
		const bio = formData.get('bio') as string;
		const website_url = formData.get('website_url') as string;
		const twitter_url = formData.get('twitter_url') as string;
		const facebook_url = formData.get('facebook_url') as string;
		const instagram_url = formData.get('instagram_url') as string;
		const linkedin_url = formData.get('linkedin_url') as string;
		const youtube_url = formData.get('youtube_url') as string;
		const tiktok_url = formData.get('tiktok_url') as string;
		const substack_url = formData.get('substack_url') as string;

		const { error } = await supabase
			.from('profiles')
			.update({
				username,
				bio: bio || null,
				website_url: website_url || null,
				twitter_url: twitter_url || null,
				facebook_url: facebook_url || null,
				instagram_url: instagram_url || null,
				linkedin_url: linkedin_url || null,
				youtube_url: youtube_url || null,
				tiktok_url: tiktok_url || null,
				substack_url: substack_url || null
			})
			.eq('id', session.user.id);

		if (error) return fail(400, { error: error.message });
		return { success: true, message: 'Profile updated successfully!' };
	},

	uploadAvatar: async ({ request, locals: { supabase, safeGetSession } }) => {
		try {
			const { session } = await safeGetSession();
			if (!session) return fail(401, { error: 'Unauthorized' });

			const formData = await request.formData();
			const file = formData.get('avatar') as File;

			if (!file || file.size === 0) {
				return fail(400, { error: 'No file provided' });
			}

			// Validate file size (2MB max)
			if (file.size > 2 * 1024 * 1024) {
				return fail(400, { error: 'File size must be less than 2MB' });
			}

			// Validate file type
			if (!file.type.startsWith('image/')) {
				return fail(400, { error: 'File must be an image' });
			}

			const fileExt = file.name.split('.').pop();
			const fileName = `${session.user.id}-${Date.now()}.${fileExt}`;
			const filePath = `avatars/${fileName}`;

			// Convert File to ArrayBuffer for Supabase
			const arrayBuffer = await file.arrayBuffer();

			// Upload to Supabase Storage
			const { error: uploadError } = await supabase.storage
				.from('profiles')
				.upload(filePath, arrayBuffer, {
					contentType: file.type,
					upsert: true
				});

			if (uploadError) {
				return fail(500, { error: `Failed to upload image: ${uploadError.message}` });
			}

			// Get public URL
			const { data: { publicUrl } } = supabase.storage
				.from('profiles')
				.getPublicUrl(filePath);

			// Update profile with new avatar URL
			const { error: updateError } = await supabase
				.from('profiles')
				.update({ avatar_url: publicUrl })
				.eq('id', session.user.id);

			if (updateError) {
				return fail(500, { error: `Failed to update profile: ${updateError.message}` });
			}

			return { success: true, message: 'Avatar updated successfully!' };
		} catch (error) {
			return fail(500, { error: `Server error: ${error instanceof Error ? error.message : 'Unknown error'}` });
		}
	},

	uploadUserBanner: async ({ request, locals: { supabase, safeGetSession } }) => {
		const { session } = await safeGetSession();
		if (!session) return fail(401, { error: 'Unauthorized' });

		const formData = await request.formData();
		const file = formData.get('banner') as File;

		if (!file || file.size === 0) {
			return fail(400, { error: 'No file provided' });
		}

		if (file.size > 5 * 1024 * 1024) {
			return fail(400, { error: 'File size must be less than 5MB' });
		}

		if (!file.type.startsWith('image/')) {
			return fail(400, { error: 'File must be an image' });
		}

		const fileExt = file.name.split('.').pop();
		const fileName = `${session.user.id}-banner-${Date.now()}.${fileExt}`;
		const filePath = `banners/${fileName}`;

		// Convert File to ArrayBuffer for Supabase
		const arrayBuffer = await file.arrayBuffer();

		const { error: uploadError } = await supabase.storage
			.from('profiles')
			.upload(filePath, arrayBuffer, {
				contentType: file.type,
				upsert: true
			});

		if (uploadError) {
			return fail(500, { error: `Failed to upload banner: ${uploadError.message}` });
		}

		const { data: { publicUrl } } = supabase.storage
			.from('profiles')
			.getPublicUrl(filePath);

		const { error: updateError } = await supabase
			.from('profiles')
			.update({ banner_url: publicUrl })
			.eq('id', session.user.id);

		if (updateError) {
			return fail(500, { error: `Failed to update profile: ${updateError.message}` });
		}

		return { success: true, message: 'Cover image updated successfully!' };
	},

	uploadLogo: async ({ request, locals: { supabase, safeGetSession } }) => {
		const { session } = await safeGetSession();
		if (!session) return fail(401, { error: 'Unauthorized' });

		const formData = await request.formData();
		const file = formData.get('logo') as File;
		const brandId = formData.get('brand_id') as string;

		if (!brandId) {
			return fail(400, { error: 'Brand ID is required' });
		}

		// Verify ownership
		const { data: brand } = await supabase
			.from('brand_profiles')
			.select('id')
			.eq('id', brandId)
			.eq('owner_id', session.user.id)
			.maybeSingle();

		if (!brand) {
			return fail(403, { error: 'You do not own this brand' });
		}

		if (!file || file.size === 0) {
			return fail(400, { error: 'No file provided' });
		}

		if (file.size > 2 * 1024 * 1024) {
			return fail(400, { error: 'File size must be less than 2MB' });
		}

		if (!file.type.startsWith('image/')) {
			return fail(400, { error: 'File must be an image' });
		}

		const fileExt = file.name.split('.').pop();
		const fileName = `${brandId}-logo-${Date.now()}.${fileExt}`;
		const filePath = `logos/${fileName}`;

		// Convert File to ArrayBuffer for Supabase
		const arrayBuffer = await file.arrayBuffer();

		const { error: uploadError } = await supabase.storage
			.from('brands')
			.upload(filePath, arrayBuffer, {
				contentType: file.type,
				upsert: true
			});

		if (uploadError) {
			return fail(500, { error: 'Failed to upload logo' });
		}

		const { data: { publicUrl } } = supabase.storage
			.from('brands')
			.getPublicUrl(filePath);

		const { error: updateError } = await supabase
			.from('brand_profiles')
			.update({ logo_url: publicUrl })
			.eq('id', brandId)
			.eq('owner_id', session.user.id);

		if (updateError) {
			return fail(500, { error: 'Failed to update brand profile' });
		}

		return { success: true, message: 'Logo updated successfully!' };
	},

	uploadBrandBanner: async ({ request, locals: { supabase, safeGetSession } }) => {
		const { session } = await safeGetSession();
		if (!session) return fail(401, { error: 'Unauthorized' });

		const formData = await request.formData();
		const file = formData.get('banner') as File;
		const brandId = formData.get('brand_id') as string;

		if (!brandId) {
			return fail(400, { error: 'Brand ID is required' });
		}

		// Verify ownership
		const { data: brand } = await supabase
			.from('brand_profiles')
			.select('id')
			.eq('id', brandId)
			.eq('owner_id', session.user.id)
			.maybeSingle();

		if (!brand) {
			return fail(403, { error: 'You do not own this brand' });
		}

		if (!file || file.size === 0) {
			return fail(400, { error: 'No file provided' });
		}

		if (file.size > 5 * 1024 * 1024) {
			return fail(400, { error: 'File size must be less than 5MB' });
		}

		if (!file.type.startsWith('image/')) {
			return fail(400, { error: 'File must be an image' });
		}

		const fileExt = file.name.split('.').pop();
		const fileName = `${brandId}-banner-${Date.now()}.${fileExt}`;
		const filePath = `banners/${fileName}`;

		// Convert File to ArrayBuffer for Supabase
		const arrayBuffer = await file.arrayBuffer();

		const { error: uploadError } = await supabase.storage
			.from('brands')
			.upload(filePath, arrayBuffer, {
				contentType: file.type,
				upsert: true
			});

		if (uploadError) {
			return fail(500, { error: 'Failed to upload banner' });
		}

		const { data: { publicUrl } } = supabase.storage
			.from('brands')
			.getPublicUrl(filePath);

		const { error: updateError } = await supabase
			.from('brand_profiles')
			.update({ banner_url: publicUrl })
			.eq('id', brandId)
			.eq('owner_id', session.user.id);

		if (updateError) {
			return fail(500, { error: 'Failed to update brand profile' });
		}

		return { success: true, message: 'Cover image updated successfully!' };
	},

	updateBrand: async ({ request, locals: { supabase, safeGetSession } }) => {
		const { session } = await safeGetSession();
		if (!session) return fail(401, { error: 'Unauthorized' });

		const formData = await request.formData();
		const brandId = formData.get('brand_id') as string;
		const brand_name = formData.get('brand_name') as string;
		const description = formData.get('description') as string;
		const website_url = formData.get('website_url') as string;
		const categories = formData.get('categories') as string;

		// Verify ownership
		const { data: brand } = await supabase
			.from('brand_profiles')
			.select('id')
			.eq('id', brandId)
			.eq('owner_id', session.user.id)
			.maybeSingle();

		if (!brand) {
			return fail(403, { error: 'You do not own this brand' });
		}

		const { error } = await supabase
			.from('brand_profiles')
			.update({
				brand_name,
				description: description || null,
				website_url: website_url || null,
				categories: categories ? categories.split(',').map((c) => c.trim()) : []
			})
			.eq('id', brandId)
			.eq('owner_id', session.user.id);

		if (error) return fail(400, { error: error.message });
		return { success: true, message: 'Brand profile updated successfully!' };
	},

	updateNotificationPreferences: async ({ request, locals: { supabase, safeGetSession } }) => {
		const { session } = await safeGetSession();
		if (!session) return fail(401, { error: 'Unauthorized' });

		const formData = await request.formData();

		const preferences = {
			new_post: formData.get('new_post') === 'on',
			comment_reply: formData.get('comment_reply') === 'on',
			new_follower: formData.get('new_follower') === 'on',
			mention: formData.get('mention') === 'on',
			promotion: formData.get('promotion') === 'on'
		};

		const { error } = await supabase
			.from('profiles')
			.update({ notification_preferences: preferences })
			.eq('id', session.user.id);

		if (error) return fail(400, { error: error.message });
		return { success: true, message: 'Notification preferences updated successfully!' };
	},

	addBrandMember: async ({ request, locals: { supabase, safeGetSession } }) => {
		const { session } = await safeGetSession();
		if (!session) return fail(401, { error: 'Unauthorized' });

		const formData = await request.formData();
		const brandId = formData.get('brand_id') as string;
		const username = formData.get('username') as string;
		const role = formData.get('role') as string;

		if (!brandId || !username || !role) {
			return fail(400, { error: 'Brand ID, username, and role are required' });
		}

		// Verify ownership
		const { data: brand } = await supabase
			.from('brand_profiles')
			.select('id')
			.eq('id', brandId)
			.eq('owner_id', session.user.id)
			.maybeSingle();

		if (!brand) {
			return fail(403, { error: 'You do not own this brand' });
		}

		// Find user by username
		const { data: targetUser, error: userError } = await supabase
			.from('profiles')
			.select('id, username')
			.eq('username', username)
			.maybeSingle();

		if (userError || !targetUser) {
			return fail(404, { error: 'User not found' });
		}

		// Check if already a member
		const { data: existingMember } = await supabase
			.from('brand_members')
			.select('user_id')
			.eq('brand_id', brandId)
			.eq('user_id', targetUser.id)
			.maybeSingle();

		if (existingMember) {
			return fail(400, { error: 'User is already a member of this brand' });
		}

		// Add member
		const { error: insertError } = await supabase
			.from('brand_members')
			.insert({
				brand_id: brandId,
				user_id: targetUser.id,
				role,
				invited_by: session.user.id
			});

		if (insertError) {
			return fail(500, { error: `Failed to add member: ${insertError.message}` });
		}

		return { success: true, message: `${username} added as ${role} successfully!` };
	},

	updateBrandMemberRole: async ({ request, locals: { supabase, safeGetSession } }) => {
		const { session } = await safeGetSession();
		if (!session) return fail(401, { error: 'Unauthorized' });

		const formData = await request.formData();
		const brandId = formData.get('brand_id') as string;
		const userId = formData.get('user_id') as string;
		const role = formData.get('role') as string;

		if (!brandId || !userId || !role) {
			return fail(400, { error: 'Brand ID, user ID, and role are required' });
		}

		// Verify ownership
		const { data: brand } = await supabase
			.from('brand_profiles')
			.select('id, owner_id')
			.eq('id', brandId)
			.eq('owner_id', session.user.id)
			.maybeSingle();

		if (!brand) {
			return fail(403, { error: 'You do not own this brand' });
		}

		// Don't allow changing owner's role
		if (userId === brand.owner_id) {
			return fail(400, { error: 'Cannot change the owner\'s role' });
		}

		// Update role
		const { error: updateError } = await supabase
			.from('brand_members')
			.update({ role })
			.eq('brand_id', brandId)
			.eq('user_id', userId);

		if (updateError) {
			return fail(500, { error: `Failed to update role: ${updateError.message}` });
		}

		return { success: true, message: 'Member role updated successfully!' };
	},

	removeBrandMember: async ({ request, locals: { supabase, safeGetSession } }) => {
		const { session } = await safeGetSession();
		if (!session) return fail(401, { error: 'Unauthorized' });

		const formData = await request.formData();
		const brandId = formData.get('brand_id') as string;
		const userId = formData.get('user_id') as string;

		if (!brandId || !userId) {
			return fail(400, { error: 'Brand ID and user ID are required' });
		}

		// Verify ownership
		const { data: brand } = await supabase
			.from('brand_profiles')
			.select('id, owner_id')
			.eq('id', brandId)
			.eq('owner_id', session.user.id)
			.maybeSingle();

		if (!brand) {
			return fail(403, { error: 'You do not own this brand' });
		}

		// Don't allow removing the owner
		if (userId === brand.owner_id) {
			return fail(400, { error: 'Cannot remove the brand owner' });
		}

		// Remove member
		const { error: deleteError } = await supabase
			.from('brand_members')
			.delete()
			.eq('brand_id', brandId)
			.eq('user_id', userId);

		if (deleteError) {
			return fail(500, { error: `Failed to remove member: ${deleteError.message}` });
		}

		return { success: true, message: 'Member removed successfully!' };
	}
};
