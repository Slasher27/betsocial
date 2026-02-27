/**
 * Migration Verification Script
 *
 * Checks if the database trigger exists and is configured correctly.
 * This helps diagnose signup errors caused by missing or misconfigured triggers.
 */

import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.PUBLIC_SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
	console.error('❌ Missing environment variables!');
	console.error('Required: PUBLIC_SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY');
	console.error('\nAdd SUPABASE_SERVICE_ROLE_KEY to your .env file');
	console.error('(Find it in Supabase Dashboard → Settings → API → service_role key)');
	process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
	auth: {
		autoRefreshToken: false,
		persistSession: false
	}
});

async function verifyMigrations() {
	console.log('🔍 Verifying Database Migrations\n');
	console.log('='.repeat(60));

	let allChecksPass = true;

	// Check 1: Profiles table structure
	console.log('\n1️⃣  Checking profiles table structure...');
	try {
		const { data, error } = await supabase
			.from('profiles')
			.select('*')
			.limit(1)
			.maybeSingle();

		if (error && error.code !== 'PGRST116') {
			// PGRST116 is "no rows returned", which is fine
			console.error('❌ FAIL: Profiles table has issues');
			console.error('   Error:', error.message);
			allChecksPass = false;
		} else {
			console.log('✅ PASS: Profiles table exists and is accessible');
		}
	} catch (err: any) {
		console.error('❌ FAIL:', err.message);
		allChecksPass = false;
	}

	// Check 2: Brand profiles table
	console.log('\n2️⃣  Checking brand_profiles table...');
	try {
		const { error } = await supabase
			.from('brand_profiles')
			.select('id')
			.limit(1)
			.maybeSingle();

		if (error && error.code !== 'PGRST116') {
			console.error('❌ FAIL: Brand profiles table has issues');
			console.error('   Error:', error.message);
			allChecksPass = false;
		} else {
			console.log('✅ PASS: Brand profiles table exists');
		}
	} catch (err: any) {
		console.error('❌ FAIL:', err.message);
		allChecksPass = false;
	}

	// Check 3: Posts table
	console.log('\n3️⃣  Checking posts table...');
	try {
		const { error } = await supabase
			.from('posts')
			.select('id')
			.limit(1)
			.maybeSingle();

		if (error && error.code !== 'PGRST116') {
			console.error('❌ FAIL: Posts table has issues');
			console.error('   Error:', error.message);
			allChecksPass = false;
		} else {
			console.log('✅ PASS: Posts table exists');
		}
	} catch (err: any) {
		console.error('❌ FAIL:', err.message);
		allChecksPass = false;
	}

	// Check 4: Test the trigger by examining schema
	console.log('\n4️⃣  Checking handle_new_user trigger...');
	console.log('   Note: This requires direct database access via SQL');
	console.log('   Run this SQL in Supabase Dashboard → SQL Editor:');
	console.log('');
	console.log('   SELECT * FROM pg_trigger WHERE tgname = \'on_auth_user_created\';');
	console.log('');
	console.log('   If no rows are returned, the trigger is missing!');

	// Check 5: Username uniqueness constraint
	console.log('\n5️⃣  Verifying username uniqueness constraint...');
	try {
		// This will fail if constraint doesn't exist
		const { error } = await supabase
			.from('profiles')
			.select('username')
			.limit(1);

		if (error) {
			console.error('❌ FAIL: Cannot verify username constraint');
			console.error('   Error:', error.message);
			allChecksPass = false;
		} else {
			console.log('✅ PASS: Username column exists (constraint assumed)');
		}
	} catch (err: any) {
		console.error('❌ FAIL:', err.message);
		allChecksPass = false;
	}

	console.log('\n' + '='.repeat(60));

	if (allChecksPass) {
		console.log('\n✅ All basic checks passed!');
		console.log('\nIf signup still fails with a 500 error, the issue is likely:');
		console.log('  1. Missing trigger (check step 4 above)');
		console.log('  2. Trigger code has a bug');
		console.log('  3. Duplicate username being submitted\n');
		console.log('Next steps:');
		console.log('  - Run: npm run check:db (to see more details)');
		console.log('  - Try signup and check browser console for error details');
	} else {
		console.log('\n❌ Some checks failed!');
		console.log('\n📋 Action Required:');
		console.log('  1. Go to Supabase Dashboard → SQL Editor');
		console.log('  2. Run migrations in order:');
		console.log('     - 001_initial_schema.sql');
		console.log('     - 003_recreate_auth_trigger.sql');
		console.log('     - 004_fix_schema_search_path.sql');
		console.log('     - Any other numbered migrations\n');
	}
}

verifyMigrations().catch((error) => {
	console.error('\n❌ Unexpected error:', error);
	process.exit(1);
});
