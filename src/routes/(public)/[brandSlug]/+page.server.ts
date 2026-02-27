import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals: { supabase, safeGetSession } }) => {
	const { session } = await safeGetSession();

	// Get brand profile
	const { data: brand, error: brandError } = await supabase
		.from('brand_profiles')
		.select('*')
		.eq('slug', params.brandSlug)
		.maybeSingle();

	if (brandError) {
		console.error('Error fetching brand:', brandError);
		throw error(500, 'Error loading brand');
	}

	if (!brand) {
		throw error(404, 'Brand not found');
	}

	// Get brand's published posts (pinned posts first, then by date)
	const { data: posts } = await supabase
		.from('posts')
		.select('id, title, slug, excerpt, cover_image_url, published_at, like_count, comment_count, is_pinned, post_type')
		.eq('brand_id', (brand as any).id)
		.eq('status', 'published')
		.order('is_pinned', { ascending: false })
		.order('published_at', { ascending: false })
		.limit(50);

	// Check if current user follows this brand
	let isFollowing = false;
	if (session) {
		const { data: followData } = await supabase
			.from('follows')
			.select('follower_id')
			.eq('follower_id', session.user.id)
			.eq('brand_id', (brand as any).id)
			.maybeSingle();

		isFollowing = !!followData;
	}

	return {
		brand,
		posts: posts || [],
		isFollowing
	};
};
