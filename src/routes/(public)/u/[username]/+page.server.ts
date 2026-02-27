import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals: { supabase, safeGetSession } }) => {
	const { session } = await safeGetSession();

	// Get user profile by username
	const { data: profile, error: profileError } = await supabase
		.from('profiles')
		.select('id, username, display_name, avatar_url, banner_url, bio, created_at, website_url, twitter_url, facebook_url, instagram_url, linkedin_url, youtube_url, tiktok_url, substack_url')
		.eq('username', params.username)
		.maybeSingle();

	if (profileError) {
		console.error('Error fetching profile:', profileError);
		throw error(500, 'Error loading profile');
	}

	if (!profile) {
		throw error(404, 'User not found');
	}

	// Get brands owned by this user
	const { data: brands } = await supabase
		.from('brand_profiles')
		.select('*')
		.eq('owner_id', (profile as any).id);

	// Get user's posts (pinned first, then by date)
	const { data: posts } = await supabase
		.from('posts')
		.select('id, title, slug, excerpt, status, published_at, created_at, updated_at, like_count, comment_count, is_pinned, post_type')
		.eq('author_id', (profile as any).id)
		.eq('status', 'published')
		.order('is_pinned', { ascending: false })
		.order('published_at', { ascending: false })
		.limit(50);

	return {
		profile,
		brands: brands || [],
		posts: posts || [],
		session
	};
};
