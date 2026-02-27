import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals: { supabase, safeGetSession } }) => {
	const { session } = await safeGetSession();

	// Get user profile by username
	const { data: author } = await supabase
		.from('profiles')
		.select('id, username, display_name, avatar_url')
		.eq('username', params.username)
		.single();

	if (!author) {
		throw error(404, 'User not found');
	}

	// Get post by slug and author
	const { data: post } = await supabase
		.from('posts')
		.select('*')
		.eq('author_id', (author as any).id)
		.eq('slug', params.postSlug)
		.single();

	if (!post) {
		throw error(404, 'Post not found');
	}

	// Check if post is published or belongs to current user
	if ((post as any).status !== 'published' && (!session || session.user.id !== (author as any).id)) {
		throw error(404, 'Post not found');
	}

	// Check if user has bookmarked this post
	let isBookmarked = false;
	if (session) {
		const { data: bookmark } = await supabase
			.from('bookmarks')
			.select('*')
			.eq('user_id', session.user.id)
			.eq('post_id', (post as any).id)
			.single();
		isBookmarked = !!bookmark;
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
		post,
		author,
		isBookmarked,
		session,
		comments: comments || []
	};
};
