import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals: { safeGetSession } }) => {
	const { session } = await safeGetSession();

	// If user is already logged in, redirect to feed
	if (session) {
		throw redirect(303, '/feed');
	}

	// Otherwise, show the landing page
	return {};
};
