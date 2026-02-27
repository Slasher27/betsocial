<script lang="ts">
	import { supabase } from '$lib/supabase/client';
	import { goto } from '$app/navigation';

	let { data } = $props();

	let brandName = $state('');
	let slug = $state('');
	let description = $state('');
	let websiteUrl = $state('');
	let category = $state('');
	let loading = $state(false);
	let error = $state('');

	const categories = [
		'Sports Betting',
		'Online Casino',
		'Poker',
		'Esports',
		'Crypto Gambling',
		'Fantasy Sports',
		'Horse Racing',
		'Lottery',
		'Affiliate'
	];

	// Auto-generate slug from brand name
	$effect(() => {
		slug = brandName.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
	});

	async function handleCreateBrand(e: Event) {
		e.preventDefault();
		loading = true;
		error = '';

		if (!data.user) {
			error = 'You must be logged in to create a brand.';
			loading = false;
			return;
		}

		// Check slug availability
		const { data: existingBrand, error: checkError } = await supabase
			.from('brand_profiles')
			.select('slug')
			.eq('slug', slug)
			.maybeSingle();

		if (checkError) {
			console.error('Error checking slug:', checkError);
			error = `Error checking availability: ${checkError.message}`;
			loading = false;
			return;
		}

		if (existingBrand) {
			error = 'This brand URL is already taken. Try a different name.';
			loading = false;
			return;
		}

		// Create brand profile
		const { data: newBrand, error: createError } = await supabase
			.from('brand_profiles')
			.insert({
				owner_id: data.user.id,
				brand_name: brandName,
				slug,
				description: description || null,
				website_url: websiteUrl || null,
				categories: category ? [category] : []
			})
			.select()
			.single();

		if (createError) {
			console.error('Error creating brand:', createError);
			error = `Failed to create brand: ${createError.message}`;
			loading = false;
			return;
		}

		// Redirect to settings where user can see their brands
		goto('/settings');
	}
</script>

<svelte:head>
	<title>Create a Brand — BetChat</title>
</svelte:head>

<div class="min-h-[80vh] flex items-center justify-center px-4 py-12">
	<div class="card w-full max-w-lg bg-base-200 shadow-xl">
		<div class="card-body">
			<h1 class="text-2xl font-bold text-center mb-2">Create Your Brand</h1>
			<p class="text-center text-base-content/60 mb-6">
				Set up a brand page to publish content, promotions, and grow your audience on BetChat.
			</p>

			{#if error}
				<div class="alert alert-error mb-4">
					<span>{error}</span>
				</div>
			{/if}

			<form onsubmit={handleCreateBrand} class="space-y-4">
				<div class="form-control">
					<label class="label" for="brandName">
						<span class="label-text">Brand Name</span>
					</label>
					<input
						id="brandName"
						type="text"
						placeholder="Awesome Casino"
						class="input input-bordered w-full"
						bind:value={brandName}
						required
					/>
				</div>

				<div class="form-control">
					<label class="label" for="slug">
						<span class="label-text">Brand URL</span>
					</label>
					<label class="input input-bordered flex items-center gap-0 w-full">
						<span class="text-base-content/50 text-sm">betchat.social/</span>
						<input
							id="slug"
							type="text"
							class="grow border-0 bg-transparent focus:outline-none"
							bind:value={slug}
							required
							pattern="[a-z0-9\-]+"
						/>
					</label>
				</div>

				<div class="form-control">
					<label class="label" for="category">
						<span class="label-text">Category</span>
					</label>
					<select id="category" class="select select-bordered w-full" bind:value={category} required>
						<option value="" disabled>Select a category</option>
						{#each categories as cat}
							<option value={cat}>{cat}</option>
						{/each}
					</select>
				</div>

				<div class="form-control">
					<label class="label" for="websiteUrl">
						<span class="label-text">Website URL <span class="text-base-content/40">(optional)</span></span>
					</label>
					<input
						id="websiteUrl"
						type="url"
						placeholder="https://yourbrand.com"
						class="input input-bordered w-full"
						bind:value={websiteUrl}
					/>
				</div>

				<div class="form-control">
					<label class="label" for="description">
						<span class="label-text">Short Description</span>
					</label>
					<textarea
						id="description"
						placeholder="Tell bettors what makes your brand special..."
						class="textarea textarea-bordered w-full"
						bind:value={description}
						rows="3"
					></textarea>
				</div>

				<button type="submit" class="btn btn-primary w-full" disabled={loading}>
					{#if loading}
						<span class="loading loading-spinner loading-sm"></span>
					{/if}
					Create Brand Page
				</button>
			</form>

			<p class="text-xs text-center text-base-content/40 mt-4">
				You can create multiple brands from your account.
				Brand pages are free — you can upgrade to Pro later for premium features.
			</p>
		</div>
	</div>
</div>
