import { redirect } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';

export const load: PageServerLoad = async ({ locals: { supabase, safeGetSession } }) => {
	const { session } = await safeGetSession();

	if (!session) {
		throw redirect(303, '/auth/login');
	}

	// Fetch all notifications with actor profile info baked into data
	const { data: notifications } = await supabase
		.from('notifications')
		.select('id, type, data, is_read, created_at')
		.eq('user_id', session.user.id)
		.order('created_at', { ascending: false })
		.limit(50);

	// Collect unique actor IDs to batch-fetch profiles
	const actorIds = new Set<string>();
	for (const n of notifications || []) {
		const actorId = n.data?.commenter_id || n.data?.follower_id;
		if (actorId) actorIds.add(actorId);
	}

	let profileMap: Record<string, any> = {};
	if (actorIds.size > 0) {
		const { data: profiles } = await supabase
			.from('profiles')
			.select('id, username, display_name, avatar_url')
			.in('id', [...actorIds]);

		for (const p of profiles || []) {
			profileMap[p.id] = p;
		}
	}

	// Collect brand IDs to batch-fetch brand slugs for post links
	const brandIds = new Set<string>();
	for (const n of notifications || []) {
		if (n.data?.brand_id) brandIds.add(n.data.brand_id);
	}

	let brandMap: Record<string, any> = {};
	if (brandIds.size > 0) {
		const { data: brands } = await supabase
			.from('brand_profiles')
			.select('id, slug, brand_name')
			.in('id', [...brandIds]);

		for (const b of brands || []) {
			brandMap[b.id] = b;
		}
	}

	const enriched = (notifications || []).map((n: any) => {
		const actorId = n.data?.commenter_id || n.data?.follower_id;
		return {
			...n,
			actor: actorId ? profileMap[actorId] || null : null,
			brand: n.data?.brand_id ? brandMap[n.data.brand_id] || null : null
		};
	});

	return { notifications: enriched, session };
};

export const actions: Actions = {
	markAllRead: async ({ locals: { supabase, safeGetSession } }) => {
		const { session } = await safeGetSession();
		if (!session) return;

		await supabase
			.from('notifications')
			.update({ is_read: true })
			.eq('user_id', session.user.id)
			.eq('is_read', false);
	}
};
