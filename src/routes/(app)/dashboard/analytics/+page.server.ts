import { redirect, error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals: { supabase, safeGetSession }, url }) => {
	const { session } = await safeGetSession();

	if (!session) {
		throw redirect(303, '/auth/login');
	}

	const brandSlug = url.searchParams.get('brand');

	const { data: profile } = await supabase
		.from('profiles')
		.select('*')
		.eq('id', session.user.id)
		.maybeSingle();

	if (!profile) {
		throw error(500, 'Profile not found');
	}

	const { data: brands } = await supabase
		.from('brand_profiles')
		.select('*')
		.eq('owner_id', session.user.id);

	let currentBrand = null;
	if (brandSlug) {
		const { data: brand } = await supabase
			.from('brand_profiles')
			.select('*')
			.eq('slug', brandSlug)
			.eq('owner_id', session.user.id)
			.maybeSingle();

		if (!brand) {
			throw redirect(303, '/dashboard/analytics');
		}

		currentBrand = brand;
	}

	let postsQuery = supabase
		.from('posts')
		.select('id, title, slug, status, published_at, like_count, comment_count, share_count, created_at')
		.eq('author_id', session.user.id)
		.eq('status', 'published');

	if (currentBrand) {
		postsQuery = postsQuery.eq('brand_id', currentBrand.id);
	} else {
		postsQuery = postsQuery.is('brand_id', null);
	}

	const { data: posts } = await postsQuery.order('published_at', { ascending: false });

	let followersOverTime = [];
	if (currentBrand) {
		const { data: followers } = await supabase
			.from('follows')
			.select('created_at')
			.eq('brand_id', currentBrand.id)
			.order('created_at', { ascending: true });

		followersOverTime = followers || [];
	}

	return {
		profile,
		brands: brands || [],
		brand: currentBrand,
		posts: posts || [],
		followersOverTime
	};
};
