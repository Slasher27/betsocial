import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals: { supabase, safeGetSession } }) => {
	const { session } = await safeGetSession();

	if (!session) {
		throw redirect(303, '/auth/login');
	}

	// Get user's bookmarked posts with brand info
	const { data: bookmarks } = await supabase
		.from('bookmarks')
		.select(
			`
			post_id,
			created_at,
			post:posts(
				id,
				title,
				slug,
				excerpt,
				cover_image_url,
				published_at,
				like_count,
				comment_count,
				brand:brand_profiles(
					id,
					brand_name,
					slug,
					logo_url
				)
			)
		`
		)
		.eq('user_id', session.user.id)
		.order('created_at', { ascending: false });

	return {
		bookmarks: bookmarks || [],
		session
	};
};
