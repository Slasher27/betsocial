import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals: { supabase, safeGetSession }, url }) => {
	const { session } = await safeGetSession();

	if (!session) {
		throw redirect(303, '/auth/login');
	}

	// Check if in brand context
	const brandSlug = url.searchParams.get('brand');

	// Get user profile for Pulse input
	const { data: profile } = await supabase
		.from('profiles')
		.select('id, username, avatar_url')
		.eq('id', session.user.id)
		.single();

	// If brand context requested, load brand data
	let currentBrand = null;
	if (brandSlug) {
		const { data: brand } = await supabase
			.from('brand_profiles')
			.select('id, brand_name, slug, logo_url')
			.eq('slug', brandSlug)
			.eq('owner_id', session.user.id)
			.maybeSingle();

		if (brand) {
			currentBrand = brand;
		}
	}

	// Get all published posts (from both users and brands)
	// This creates a social media feed showing all content
	const { data: posts } = await supabase
		.from('posts')
		.select(
			`
			id,
			title,
			slug,
			excerpt,
			published_at,
			brand_id,
			author_id,
			author:profiles!posts_author_id_fkey (
				id,
				username,
				display_name,
				avatar_url
			),
			brand:brand_profiles (
				id,
				brand_name,
				slug,
				logo_url
			)
		`
		)
		.eq('status', 'published')
		.order('published_at', { ascending: false })
		.limit(50);

	// Get recent Pulse posts
	const { data: pulsePosts } = await supabase
		.from('pulse_posts')
		.select(
			`
			id,
			content,
			image_url,
			like_count,
			comment_count,
			repost_count,
			created_at,
			brand_id,
			author:profiles!pulse_posts_author_id_fkey (
				id,
				username,
				display_name,
				avatar_url
			),
			brand:brand_profiles!pulse_posts_brand_id_fkey (
				id,
				brand_name,
				slug,
				logo_url
			),
			user_reactions:pulse_reactions!pulse_reactions_pulse_id_fkey (
				user_id,
				reaction_type
			)
		`
		)
		.order('created_at', { ascending: false })
		.limit(20);

	// Get user's bookmarked post IDs for the feed
	const { data: userBookmarks } = await supabase
		.from('bookmarks')
		.select('post_id')
		.eq('user_id', session.user.id);

	const bookmarkedPostIds = new Set((userBookmarks || []).map((b: any) => b.post_id));

	// Get comments for all pulse posts
	let pulseComments: any[] = [];
	if (pulsePosts && pulsePosts.length > 0) {
		const pulseIds = pulsePosts.map(p => p.id);
		const { data: comments } = await supabase
			.from('pulse_comments')
			.select(
				`
				id,
				pulse_id,
				content,
				parent_id,
				brand_id,
				created_at,
				author:profiles!pulse_comments_author_id_fkey (
					id,
					username,
					display_name,
					avatar_url
				),
				brand:brand_profiles!pulse_comments_brand_id_fkey (
					id,
					brand_name,
					slug,
					logo_url
				)
			`
			)
			.in('pulse_id', pulseIds)
			.order('created_at', { ascending: true });

		pulseComments = comments || [];
	}

	// Attach comments to each pulse post
	const pulsePostsWithComments = (pulsePosts || []).map(pulse => ({
		...pulse,
		comments: pulseComments.filter((c: any) => c.pulse_id === pulse.id)
	}));

	return {
		profile,
		posts: posts || [],
		pulsePosts: pulsePostsWithComments,
		bookmarkedPostIds: [...bookmarkedPostIds],
		session,
		brand: currentBrand // Current brand context for Pulse input
	};
};
