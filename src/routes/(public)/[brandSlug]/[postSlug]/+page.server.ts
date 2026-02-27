import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({
	params,
	locals: { supabase, safeGetSession }
}) => {
	const { session } = await safeGetSession();

	// Get brand profile
	const { data: brand, error: brandError } = await supabase
		.from('brand_profiles')
		.select('id, brand_name, slug, logo_url')
		.eq('slug', params.brandSlug)
		.maybeSingle();

	if (brandError) {
		console.error('Error fetching brand:', brandError);
		throw error(500, 'Error loading brand');
	}

	if (!brand) {
		throw error(404, 'Brand not found');
	}

	// Get post
	const { data: post, error: postError } = await supabase
		.from('posts')
		.select('*')
		.eq('brand_id', (brand as any).id)
		.eq('slug', params.postSlug)
		.eq('status', 'published')
		.maybeSingle();

	if (postError) {
		console.error('Error fetching post:', postError);
		throw error(500, 'Error loading post');
	}

	if (!post) {
		throw error(404, 'Post not found');
	}

	// Check if user has bookmarked this post
	let isBookmarked = false;
	if (session) {
		const { data: bookmarkData} = await supabase
			.from('bookmarks')
			.select('user_id')
			.eq('user_id', session.user.id)
			.eq('post_id', (post as any).id)
			.maybeSingle();

		isBookmarked = !!bookmarkData;
	}

	// Fetch comments for this post
	const { data: comments } = await supabase
		.from('comments')
		.select(
			`
			id,
			content,
			parent_id,
			like_count,
			created_at,
			author:profiles!comments_author_id_fkey (
				id,
				username,
				display_name,
				avatar_url
			),
			mentions (
				mentioned_user_id,
				mentioned_brand_id,
				mentioned_user:profiles!mentions_mentioned_user_id_fkey (username),
				mentioned_brand:brand_profiles!mentions_mentioned_brand_id_fkey (slug)
			)
		`
		)
		.eq('post_id', (post as any).id)
		.eq('is_hidden', false)
		.order('created_at', { ascending: true });

	return {
		brand,
		post,
		isBookmarked,
		comments: comments || []
	};
};
