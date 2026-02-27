import type { LayoutServerLoad } from './$types';

export const load: LayoutServerLoad = async ({ locals: { safeGetSession, supabase }, depends, url }) => {
	depends('supabase:auth');
	const { session } = await safeGetSession();

	let profileUrl = null;
	let currentBrand = null;

	// Check if in brand context from URL
	const brandSlug = url.searchParams.get('brand');

	if (session) {
		try {
			const { data: profile } = await supabase
				.from('profiles')
				.select('username, avatar_url, display_name')
				.eq('id', session.user.id)
				.single();

			// Load all user's brands for context switching
			const { data: brands } = await supabase
				.from('brand_profiles')
				.select('id, brand_name, slug, logo_url')
				.eq('owner_id', session.user.id)
				.order('brand_name');

			// All users have a user profile URL
			profileUrl = profile?.username ? `/u/${profile.username}` : null;

			// If brand context requested, load brand data
			if (brandSlug) {
				const { data: brand } = await supabase
					.from('brand_profiles')
					.select('id, brand_name, slug, logo_url')
					.eq('slug', brandSlug)
					.eq('owner_id', session.user.id)
					.maybeSingle();

				if (brand) {
					currentBrand = brand;
					// Override profileUrl with brand URL when in brand context
					profileUrl = `/${brand.slug}`;
				}
			}

			// Get unread notification count (lightweight — count only)
			const { count: unreadCount } = await supabase
				.from('notifications')
				.select('*', { count: 'exact', head: true })
				.eq('user_id', session.user.id)
				.eq('is_read', false);

			return {
				session,
				profileUrl,
				currentBrand,
				profile, // Include profile data
				brands: brands || [], // Include all brands for context switching
				unreadCount: unreadCount ?? 0
			};
		} catch (error) {
			console.error('Error loading profile:', error);
			profileUrl = null;
		}
	}

	return {
		session,
		profileUrl,
		currentBrand,
		profile: null,
		brands: [],
		unreadCount: 0
	};
};
