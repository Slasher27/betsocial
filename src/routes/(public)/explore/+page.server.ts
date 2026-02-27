import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals: { supabase } }) => {
	// Get all brands for category filtering
	const { data: brands } = await supabase
		.from('brand_profiles')
		.select('id, brand_name, slug, description, categories, logo_url, follower_count')
		.order('follower_count', { ascending: false })
		.limit(100);

	// Get trending posts using the database function
	const { data: trendingPosts } = await supabase.rpc('get_trending_posts', {
		days_back: 7,
		result_limit: 20
	});

	// Get top brands using the database function
	const { data: topBrands } = await supabase.rpc('get_top_brands', {
		result_limit: 50
	});

	// Get verified brands (placeholder for when verification is implemented)
	const { data: featuredBrands } = await supabase
		.from('brand_profiles')
		.select('id, brand_name, slug, logo_url, follower_count, description, is_verified')
		.eq('is_verified', true)
		.order('follower_count', { ascending: false })
		.limit(5);

	return {
		brands: brands || [],
		trendingPosts: trendingPosts || [],
		topBrands: topBrands || [],
		featuredBrands: featuredBrands || []
	};
};
