import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ url, locals: { supabase } }) => {
	const query = url.searchParams.get('q') || '';
	const filter = url.searchParams.get('filter') || 'all'; // all, posts, brands, users

	if (!query.trim()) {
		return {
			query: '',
			filter,
			posts: [],
			brands: [],
			users: [],
			totalResults: 0
		};
	}

	// Search posts
	let postsQuery = supabase
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
			author:profiles!posts_author_id_fkey(username, display_name, avatar_url),
			brand:brand_profiles(slug, brand_name, logo_url)
		`
		)
		.textSearch('search_vector', query, {
			type: 'websearch',
			config: 'english'
		})
		.eq('status', 'published')
		.order('published_at', { ascending: false })
		.limit(filter === 'posts' ? 50 : 10);

	// Search brands
	let brandsQuery = supabase
		.from('brand_profiles')
		.select('id, brand_name, slug, description, logo_url, follower_count')
		.textSearch('search_vector', query, {
			type: 'websearch',
			config: 'english'
		})
		.order('follower_count', { ascending: false })
		.limit(filter === 'brands' ? 50 : 10);

	// Search users
	let usersQuery = supabase
		.from('profiles')
		.select('id, username, display_name, bio, avatar_url')
		.textSearch('search_vector', query, {
			type: 'websearch',
			config: 'english'
		})
		.eq('account_type', 'user')
		.order('created_at', { ascending: false })
		.limit(filter === 'users' ? 50 : 10);

	// Execute queries based on filter
	let posts = [];
	let brands = [];
	let users = [];

	if (filter === 'all' || filter === 'posts') {
		const { data } = await postsQuery;
		posts = data || [];
	}

	if (filter === 'all' || filter === 'brands') {
		const { data } = await brandsQuery;
		brands = data || [];
	}

	if (filter === 'all' || filter === 'users') {
		const { data } = await usersQuery;
		users = data || [];
	}

	const totalResults = posts.length + brands.length + users.length;

	return {
		query,
		filter,
		posts,
		brands,
		users,
		totalResults
	};
};
