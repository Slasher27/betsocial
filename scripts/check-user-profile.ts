import { createClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL } from '$env/static/public';
import { SUPABASE_SERVICE_ROLE_KEY } from '$env/static/private';

const supabaseUrl = PUBLIC_SUPABASE_URL;
const supabaseKey = SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkUserProfile() {
	console.log('Checking user profiles...\n');

	// Get all auth users
	const { data: { users }, error: authError } = await supabase.auth.admin.listUsers();

	if (authError) {
		console.error('Error fetching auth users:', authError);
		return;
	}

	console.log(`Found ${users.length} auth users\n`);

	for (const user of users) {
		console.log(`User ID: ${user.id}`);
		console.log(`Email: ${user.email}`);
		console.log(`Created: ${user.created_at}`);

		// Check if profile exists
		const { data: profile, error: profileError } = await supabase
			.from('profiles')
			.select('*')
			.eq('id', user.id)
			.maybeSingle();

		if (profileError) {
			console.error(`  ERROR fetching profile:`, profileError);
		} else if (!profile) {
			console.log(`  ⚠️  NO PROFILE FOUND - This user has no profile entry!`);
		} else {
			console.log(`  ✅ Profile exists: ${profile.username} (${profile.display_name || 'no display name'})`);
		}

		// Check brands
		const { data: brands } = await supabase
			.from('brand_profiles')
			.select('brand_name, slug')
			.eq('owner_id', user.id);

		if (brands && brands.length > 0) {
			console.log(`  Brands: ${brands.map(b => `${b.brand_name} (/${b.slug})`).join(', ')}`);
		}

		console.log('');
	}
}

checkUserProfile();
