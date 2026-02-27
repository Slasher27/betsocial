import { error, redirect, fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals: { supabase, safeGetSession } }) => {
	const { session } = await safeGetSession();

	if (!session) {
		throw redirect(303, '/auth/login');
	}

	// Get user profile
	const { data: profile } = await supabase
		.from('profiles')
		.select('id, username')
		.eq('id', session.user.id)
		.single();

	// Get post - check ownership by author_id
	const { data: post, error: postError } = await supabase
		.from('posts')
		.select('*, brand:brand_profiles(id, brand_name, slug)')
		.eq('id', params.postId)
		.eq('author_id', session.user.id)
		.single();

	if (postError || !post) {
		throw error(404, 'Post not found');
	}

	return {
		profile,
		post
	};
};

export const actions: Actions = {
	default: async ({ request, params, locals: { supabase, safeGetSession } }) => {
		const { session } = await safeGetSession();

		if (!session) {
			return fail(401, { error: 'Unauthorized' });
		}

		const formData = await request.formData();
		const title = formData.get('title') as string;
		const slug = formData.get('slug') as string;
		const excerpt = formData.get('excerpt') as string;
		const content = formData.get('content') as string;
		const status = formData.get('status') as 'draft' | 'published';
		const categories = formData.get('categories') as string;

		// Verify ownership by author_id
		const { data: existingPost } = await supabase
			.from('posts')
			.select('author_id')
			.eq('id', params.postId)
			.single();

		if (!existingPost || (existingPost as any).author_id !== session.user.id) {
			return fail(403, { error: 'Not authorized to edit this post' });
		}

		const updateData: any = {
			title,
			slug,
			excerpt: excerpt || null,
			content: JSON.parse(content),
			status,
			categories: categories ? categories.split(',').map((c) => c.trim()) : []
		};

		// Set published_at only when transitioning from draft to published
		if (status === 'published') {
			const { data: currentPost } = await supabase
				.from('posts')
				.select('status, published_at')
				.eq('id', params.postId)
				.single();

			if ((currentPost as any)?.status === 'draft' && !(currentPost as any)?.published_at) {
				updateData.published_at = new Date().toISOString();
			}
		}

		const { data: updatedPost, error } = await supabase
			.from('posts')
			.update(updateData)
			.eq('id', params.postId)
			.select('brand_id')
			.single();

		if (error) {
			return fail(400, { error: error.message });
		}

		// Get brand slug if this is a brand post
		let brandSlug = null;
		if ((updatedPost as any)?.brand_id) {
			const { data: brand } = await supabase
				.from('brand_profiles')
				.select('slug')
				.eq('id', (updatedPost as any).brand_id)
				.single();
			brandSlug = brand?.slug;
		}

		// Redirect back to appropriate dashboard
		const dashboardUrl = brandSlug ? `/dashboard?brand=${brandSlug}` : '/dashboard';
		throw redirect(303, dashboardUrl);
	}
};
