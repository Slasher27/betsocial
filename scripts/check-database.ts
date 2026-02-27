/**
 * Database State Checker
 *
 * This script checks the current state of your Supabase database to help debug
 * signup issues and verify that migrations have been applied correctly.
 */

import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.PUBLIC_SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
	console.error('❌ Missing environment variables!');
	console.error('Required: PUBLIC_SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY');
	console.error('\nAdd SUPABASE_SERVICE_ROLE_KEY to your .env file');
	console.error('(Find it in Supabase Dashboard → Settings → API)');
	process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
	auth: {
		autoRefreshToken: false,
		persistSession: false
	}
});

async function checkDatabaseState() {
	console.log('🔍 Checking Supabase Database State\n');
	console.log('=' .repeat(60));

	// Check if profiles table exists
	console.log('\n📋 Checking Tables...');
	const { data: tables, error: tableError } = await supabase
		.from('profiles')
		.select('id')
		.limit(0);

	if (tableError) {
		console.error('❌ Profiles table not found or not accessible');
		console.error('Error:', tableError.message);
		console.log('\n💡 Solution: Run migrations in Supabase SQL Editor');
		return;
	}

	console.log('✅ Profiles table exists');

	// Check if trigger function exists
	console.log('\n🔧 Checking Trigger Function...');
	const { data: functions, error: funcError } = await supabase.rpc('pg_get_functiondef', {
		funcoid: 'public.handle_new_user'
	}).single();

	if (funcError) {
		console.log('❌ handle_new_user() function not found');
		console.log('Error:', funcError.message);
		console.log('\n💡 Solution: Run migration 003_recreate_auth_trigger.sql or 004_fix_schema_search_path.sql');
	} else {
		console.log('✅ handle_new_user() function exists');
	}

	// Check existing profiles
	console.log('\n👥 Checking Existing Profiles...');
	const { data: profiles, error: profileError, count } = await supabase
		.from('profiles')
		.select('username, display_name, account_type', { count: 'exact' });

	if (profileError) {
		console.error('❌ Error fetching profiles:', profileError.message);
	} else {
		console.log(`✅ Found ${count} existing profile(s)`);
		if (profiles && profiles.length > 0) {
			console.log('\nExisting usernames:');
			profiles.forEach((p: any) => {
				console.log(`  - ${p.username} (${p.display_name}) [${p.account_type}]`);
			});
		}
	}

	// Check for brand_profiles table
	console.log('\n🏢 Checking Brand Profiles Table...');
	const { error: brandError } = await supabase
		.from('brand_profiles')
		.select('id')
		.limit(0);

	if (brandError) {
		console.error('❌ Brand profiles table not found');
		console.error('Error:', brandError.message);
	} else {
		console.log('✅ Brand profiles table exists');
	}

	// Check RLS policies
	console.log('\n🔒 Checking RLS Policies...');
	const { data: policies, error: policyError } = await supabase
		.rpc('exec_sql', {
			sql: `
				SELECT schemaname, tablename, policyname
				FROM pg_policies
				WHERE schemaname = 'public' AND tablename = 'profiles'
			`
		});

	if (policyError) {
		console.log('⚠️  Could not check RLS policies (requires custom RPC function)');
		console.log('This is optional - policies may still be configured correctly');
	} else if (policies && policies.length > 0) {
		console.log(`✅ Found ${policies.length} RLS policies on profiles table`);
	}

	console.log('\n' + '='.repeat(60));
	console.log('\n✨ Database check complete!\n');
}

// Run the check
checkDatabaseState().catch((error) => {
	console.error('❌ Unexpected error:', error);
	process.exit(1);
});
