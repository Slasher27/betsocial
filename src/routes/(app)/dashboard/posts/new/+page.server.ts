import { redirect, fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals: { supabase, safeGetSession }, url }) => {
	const { session } = await safeGetSession();

	if (!session) {
		throw redirect(303, '/auth/login');
	}

	// Check if in brand context
	const brandSlug = url.searchParams.get('brand');

	// Get user profile
	const { data: profile } = await supabase
		.from('profiles')
		.select('id, username')
		.eq('id', session.user.id)
		.single();

	// If brand context requested, verify user owns it
	let currentBrand = null;
	if (brandSlug) {
		const { data: brand } = await supabase
			.from('brand_profiles')
			.select('id, brand_name, slug')
			.eq('slug', brandSlug)
			.eq('owner_id', session.user.id)
			.maybeSingle();

		if (!brand) {
			// User doesn't own this brand, redirect to personal post creation
			throw redirect(303, '/dashboard/posts/new');
		}

		currentBrand = brand;
	}

	return {
		profile,
		brand: currentBrand // Current brand context (null if personal)
	};
};

export const actions: Actions = {
	default: async ({ request, locals: { supabase, safeGetSession } }) => {
		const { session } = await safeGetSession();

		if (!session) {
			return fail(401, { error: 'Unauthorized' });
		}

		try {
			const formData = await request.formData();
			const title = formData.get('title') as string;
			const slug = formData.get('slug') as string;
			const excerpt = formData.get('excerpt') as string;
			const content = formData.get('content') as string;
			const status = formData.get('status') as 'draft' | 'published';
			const categories = formData.get('categories') as string;
			const brandId = formData.get('brand_id') as string; // Hidden field with context brand_id

			// Validate required fields
			if (!title || !slug || !content) {
				return fail(400, { error: 'Title, slug, and content are required' });
			}

			// Parse and validate content
			let parsedContent;
			try {
				parsedContent = JSON.parse(content);
			} catch (parseError) {
				return fail(400, { error: 'Invalid content format' });
			}

			const postData: any = {
				author_id: session.user.id,
				title,
				slug,
				excerpt: excerpt || null,
				content: parsedContent,
				status,
				categories: categories ? categories.split(',').map((c) => c.trim()) : [],
				published_at: status === 'published' ? new Date().toISOString() : null
			};

			// Only add brand_id if it's not empty (brand context)
			if (brandId && brandId !== '') {
				postData.brand_id = brandId;
			}

			const { data: post, error } = await supabase.from('posts').insert(postData).select().single();

			if (error) {
				return fail(400, { error: `Database error: ${error.message}` });
			}

			// Redirect back to dashboard with brand context if applicable
			const message = status === 'draft' ? 'Draft saved successfully!' : 'Post published successfully!';
			const brandSlugFromForm = formData.get('brand_slug') as string;

			// Only redirect to brand context if BOTH brand_id and brand_slug are present
			const dashboardUrl = (brandId && brandId !== '' && brandSlugFromForm && brandSlugFromForm !== '')
				? `/dashboard?brand=${brandSlugFromForm}&success=${encodeURIComponent(message)}`
				: `/dashboard?success=${encodeURIComponent(message)}`;

			throw redirect(303, dashboardUrl);
		} catch (err) {
			// Don't catch redirects - check for redirect status
			if (err && typeof err === 'object' && 'status' in err && err.status === 303) {
				throw err;
			}

			// Check if it's a SvelteKit redirect
			if (err && typeof err === 'object' && 'location' in err) {
				throw err;
			}

			return fail(500, { error: `Server error: ${err instanceof Error ? err.message : JSON.stringify(err)}` });
		}
	}
};
