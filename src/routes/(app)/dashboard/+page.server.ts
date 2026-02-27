import { redirect, error, fail } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';

export const load: PageServerLoad = async ({ locals: { supabase, safeGetSession }, url }) => {
	const { session } = await safeGetSession();

	if (!session) {
		throw redirect(303, '/auth/login');
	}

	// Check if viewing as a brand (via ?brand=slug query param)
	const brandSlug = url.searchParams.get('brand');

	// Get user's profile
	const { data: profile, error: profileError } = await supabase
		.from('profiles')
		.select('*')
		.eq('id', session.user.id)
		.maybeSingle();

	if (profileError) {
		console.error('Error fetching profile:', profileError);
		throw error(500, `Error loading profile: ${profileError.message}`);
	}

	// If no profile exists, create one
	if (!profile) {
		console.log('No profile found, creating one for user:', session.user.id);
		const username = session.user.email?.split('@')[0] || 'user';
		const { error: createError } = await supabase
			.from('profiles')
			.insert({
				id: session.user.id,
				username,
				display_name: username
			});

		if (createError) {
			console.error('Error creating profile:', createError);
			throw error(500, `Failed to create profile: ${createError.message}`);
		}

		// Reload the page to fetch the new profile
		throw redirect(303, '/dashboard');
	}

	// Get brands owned by this user
	const { data: brands } = await supabase
		.from('brand_profiles')
		.select('*')
		.eq('owner_id', session.user.id);

	// If brand context requested, verify user owns it
	let currentBrand = null;
	if (brandSlug) {
		const { data: brand } = await supabase
			.from('brand_profiles')
			.select('*')
			.eq('slug', brandSlug)
			.eq('owner_id', session.user.id)
			.maybeSingle();

		if (!brand) {
			// User doesn't own this brand, redirect to personal dashboard
			throw redirect(303, '/dashboard');
		}

		currentBrand = brand;
	}

	// Get posts based on current context
	let postsQuery = supabase
		.from('posts')
		.select('id, title, slug, excerpt, status, published_at, like_count, comment_count, created_at, updated_at, brand_id, is_pinned')
		.eq('author_id', session.user.id);

	if (currentBrand) {
		// Brand context: show only posts for this brand
		postsQuery = postsQuery.eq('brand_id', currentBrand.id);
		console.log('Loading brand posts for brand:', currentBrand.id);
	} else {
		// Personal context: show only personal posts (no brand_id)
		postsQuery = postsQuery.is('brand_id', null);
		console.log('Loading personal posts (brand_id IS NULL)');
	}

	const { data: posts } = await postsQuery.order('created_at', { ascending: false});
	console.log('Posts loaded:', posts?.length, 'posts');
	if (posts && posts.length > 0) {
		console.log('First post brand_id:', posts[0].brand_id);
	}

	return {
		profile,
		brands: brands || [],
		posts: posts || [],
		brand: currentBrand // Current brand context (null if personal)
	};
};

export const actions: Actions = {
	togglePin: async ({ request, locals: { supabase, safeGetSession } }) => {
		const { session } = await safeGetSession();
		if (!session) {
			return fail(401, { error: 'Unauthorized' });
		}

		const formData = await request.formData();
		const postId = formData.get('postId') as string;
		const currentlyPinned = formData.get('isPinned') === 'true';

		if (!postId) {
			return fail(400, { error: 'Post ID is required' });
		}

		// Verify the post belongs to the user
		const { data: post } = await supabase
			.from('posts')
			.select('id, author_id, is_pinned')
			.eq('id', postId)
			.eq('author_id', session.user.id)
			.single();

		if (!post) {
			return fail(404, { error: 'Post not found or you do not have permission' });
		}

		// Toggle the pin state
		const { error: updateError } = await supabase
			.from('posts')
			.update({ is_pinned: !currentlyPinned })
			.eq('id', postId);

		if (updateError) {
			console.error('Error toggling pin:', updateError);
			return fail(500, { error: 'Failed to update post' });
		}

		return { success: true };
	}
};
