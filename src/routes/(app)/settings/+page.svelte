<script lang="ts">
	import type { PageData, ActionData } from './$types';
	import { enhance } from '$app/forms';
	import { supabase } from '$lib/supabase/client';
	import { invalidateAll } from '$app/navigation';
	import imageCompression from 'browser-image-compression';
	import { CONTAINER_WIDTHS, SPACING, TYPOGRAPHY, BUTTON, SHADOW } from '$lib/ui-constants';

	let { data, form } = $props<{ data: PageData; form: ActionData }>();

	let username = $state('');
	let userBio = $state('');
	let websiteUrl = $state('');
	let twitterUrl = $state('');
	let facebookUrl = $state('');
	let instagramUrl = $state('');
	let linkedinUrl = $state('');
	let youtubeUrl = $state('');
	let tiktokUrl = $state('');
	let substackUrl = $state('');

	const currentBrand = data.brand;
	let brandName = $state('');
	let brandDescription = $state('');
	let brandWebsiteUrl = $state('');
	let categories = $state('');

	$effect(() => {
		username = data.profile?.username || '';
		userBio = data.profile?.bio || '';
		websiteUrl = data.profile?.website_url || '';
		twitterUrl = data.profile?.twitter_url || '';
		facebookUrl = data.profile?.facebook_url || '';
		instagramUrl = data.profile?.instagram_url || '';
		linkedinUrl = data.profile?.linkedin_url || '';
		youtubeUrl = data.profile?.youtube_url || '';
		tiktokUrl = data.profile?.tiktok_url || '';
		substackUrl = data.profile?.substack_url || '';

		if (currentBrand) {
			brandName = (currentBrand as any)?.brand_name || '';
			brandDescription = (currentBrand as any)?.description || '';
			brandWebsiteUrl = (currentBrand as any)?.website_url || '';
			categories = (currentBrand as any)?.categories?.join(', ') || '';
		}

		notificationPrefs = {
			new_post: data.profile?.notification_preferences?.new_post ?? true,
			comment_reply: data.profile?.notification_preferences?.comment_reply ?? true,
			new_follower: data.profile?.notification_preferences?.new_follower ?? true,
			mention: data.profile?.notification_preferences?.mention ?? true,
			promotion: data.profile?.notification_preferences?.promotion ?? false
		};
	});

	let loading = $state(false);
	// Default tab based on context: 'brand' for brand context, 'profile' for personal
	let activeTab = $state<'profile' | 'brand' | 'stats' | 'account' | 'following' | 'team'>(data.brand ? 'brand' : 'profile');
	let unfollowingBrandId = $state<string | null>(null);
	let unfollowError = $state<string | null>(null);

	// Team management states
	let newMemberUsername = $state('');
	let newMemberRole = $state<'admin' | 'editor' | 'viewer'>('editor');
	let managingMemberId = $state<string | null>(null);

	const hasBrands = data.brands && data.brands.length > 0;

	let notificationPrefs = $state({
		new_post: true,
		comment_reply: true,
		new_follower: true,
		mention: true,
		promotion: false
	});

	// Image preview states
	let avatarPreview = $state<string | null>(null);
	let bannerPreview = $state<string | null>(null);
	let brandLogoPreview = $state<string | null>(null);
	let brandBannerPreview = $state<string | null>(null);

	// Drag and drop states
	let avatarDragOver = $state(false);
	let bannerDragOver = $state(false);
	let brandLogoDragOver = $state(false);
	let brandBannerDragOver = $state(false);

	// Image compression helper functions
	async function compressAvatar(file: File): Promise<File> {
		const options = {
			maxSizeMB: 1, // 1MB max (increased for better quality)
			maxWidthOrHeight: 800, // 800x800 max dimension (increased for sharper small displays)
			useWebWorker: true,
			initialQuality: 0.9, // Higher quality
		};

		try {
			const compressedBlob = await imageCompression(file, options);
			// Convert blob to File with original filename
			return new File([compressedBlob], file.name, {
				type: compressedBlob.type,
				lastModified: Date.now(),
			});
		} catch (error) {
			console.error('Error compressing avatar:', error);
			return file; // Return original if compression fails
		}
	}

	async function compressBanner(file: File): Promise<File> {
		const options = {
			maxSizeMB: 1.5, // 1.5MB max (increased for better quality)
			maxWidthOrHeight: 1600, // 1600px max width (increased for sharper displays)
			useWebWorker: true,
			initialQuality: 0.9, // Higher quality
		};

		try {
			const compressedBlob = await imageCompression(file, options);
			// Convert blob to File with original filename
			return new File([compressedBlob], file.name, {
				type: compressedBlob.type,
				lastModified: Date.now(),
			});
		} catch (error) {
			console.error('Error compressing banner:', error);
			return file; // Return original if compression fails
		}
	}

	// Validate image dimensions
	function validateImageDimensions(file: File, minWidth: number, minHeight: number): Promise<boolean> {
		return new Promise((resolve) => {
			const img = new Image();
			img.onload = () => {
				URL.revokeObjectURL(img.src);
				resolve(img.width >= minWidth && img.height >= minHeight);
			};
			img.onerror = () => {
				URL.revokeObjectURL(img.src);
				resolve(false);
			};
			img.src = URL.createObjectURL(file);
		});
	}

	// Create image preview
	function createPreview(file: File): string {
		return URL.createObjectURL(file);
	}

	// Handle image upload with validation and preview
	async function handleImageUpload(
		file: File,
		type: 'avatar' | 'banner' | 'brand-logo' | 'brand-banner',
		form: HTMLFormElement
	) {
		loading = true;

		// Validate file type
		if (!file.type.startsWith('image/')) {
			alert('Please select an image file');
			loading = false;
			return;
		}

		// Validate dimensions based on type
		let minWidth = 0;
		let minHeight = 0;
		if (type === 'avatar' || type === 'brand-logo') {
			minWidth = 200;
			minHeight = 200;
		} else {
			minWidth = 800;
			minHeight = 200;
		}

		const validDimensions = await validateImageDimensions(file, minWidth, minHeight);
		if (!validDimensions) {
			alert(`Image must be at least ${minWidth}x${minHeight} pixels`);
			loading = false;
			return;
		}

		// Create preview
		const preview = createPreview(file);
		if (type === 'avatar') avatarPreview = preview;
		else if (type === 'banner') bannerPreview = preview;
		else if (type === 'brand-logo') brandLogoPreview = preview;
		else if (type === 'brand-banner') brandBannerPreview = preview;

		// Compress and submit
		try {
			const compressedFile = type === 'banner' || type === 'brand-banner'
				? await compressBanner(file)
				: await compressAvatar(file);

			// Create a new DataTransfer to replace the file input's files
			const input = form.querySelector('input[type="file"]') as HTMLInputElement;
			if (input) {
				const dataTransfer = new DataTransfer();
				dataTransfer.items.add(compressedFile);
				input.files = dataTransfer.files;
				form.requestSubmit();
			}
		} catch (error) {
			console.error('Error processing image:', error);
			loading = false;
		}
	}

	// Handle drag and drop
	function handleDragOver(e: DragEvent, type: 'avatar' | 'banner' | 'brand-logo' | 'brand-banner') {
		e.preventDefault();
		if (type === 'avatar') avatarDragOver = true;
		else if (type === 'banner') bannerDragOver = true;
		else if (type === 'brand-logo') brandLogoDragOver = true;
		else if (type === 'brand-banner') brandBannerDragOver = true;
	}

	function handleDragLeave(type: 'avatar' | 'banner' | 'brand-logo' | 'brand-banner') {
		if (type === 'avatar') avatarDragOver = false;
		else if (type === 'banner') bannerDragOver = false;
		else if (type === 'brand-logo') brandLogoDragOver = false;
		else if (type === 'brand-banner') brandBannerDragOver = false;
	}

	function handleDrop(
		e: DragEvent,
		type: 'avatar' | 'banner' | 'brand-logo' | 'brand-banner',
		form: HTMLFormElement
	) {
		e.preventDefault();
		handleDragLeave(type);

		const file = e.dataTransfer?.files[0];
		if (file) {
			handleImageUpload(file, type, form);
		}
	}

	// Delete image
	async function deleteImage(type: 'avatar' | 'banner' | 'brand-logo' | 'brand-banner') {
		if (!confirm('Are you sure you want to remove this image?')) return;

		loading = true;
		let updateData: any = {};
		let tableName = '';
		let id = '';

		if (type === 'avatar') {
			updateData = { avatar_url: null };
			tableName = 'profiles';
			id = data.session?.user.id || '';
		} else if (type === 'banner') {
			updateData = { banner_url: null };
			tableName = 'profiles';
			id = data.session?.user.id || '';
		} else if (type === 'brand-logo') {
			updateData = { logo_url: null };
			tableName = 'brand_profiles';
			id = (currentBrand as any)?.id || '';
		} else if (type === 'brand-banner') {
			updateData = { banner_url: null };
			tableName = 'brand_profiles';
			id = (currentBrand as any)?.id || '';
		}

		const { error } = await supabase
			.from(tableName)
			.update(updateData)
			.eq('id', id);

		if (error) {
			alert('Failed to remove image');
		} else {
			await invalidateAll();
		}

		loading = false;
	}

	async function handleUnfollow(brandId: string) {
		if (!data.session) return;

		unfollowingBrandId = brandId;
		unfollowError = null;

		const { error } = await supabase
			.from('follows')
			.delete()
			.eq('follower_id', data.session.user.id)
			.eq('brand_id', brandId);

		if (error) {
			unfollowError = 'Failed to unfollow. Please try again.';
			unfollowingBrandId = null;
			return;
		}

		unfollowingBrandId = null;
		await invalidateAll();
	}
</script>

<svelte:head>
	<title>{data.brand ? `${data.brand.brand_name} Settings` : 'Settings'} | BetChat</title>
</svelte:head>

<div class="container mx-auto {SPACING.page.padding} {CONTAINER_WIDTHS.forms}">
	<div class="mb-8">
		<h1 class="{TYPOGRAPHY.pageTitle}">
			{#if data.brand}
				{data.brand.brand_name} Settings
			{:else}
				Settings
			{/if}
		</h1>
	</div>

	{#if form?.success}
		<div class="alert alert-success mb-6">
			<svg
				xmlns="http://www.w3.org/2000/svg"
				class="stroke-current shrink-0 h-6 w-6"
				fill="none"
				viewBox="0 0 24 24"
			>
				<path
					stroke-linecap="round"
					stroke-linejoin="round"
					stroke-width="2"
					d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
				/>
			</svg>
			<span>{form.message}</span>
		</div>
	{/if}

	<!-- Tabs - Context Aware -->
	<div class="tabs tabs-boxed mb-6">
		{#if data.brand}
			<!-- Brand Context: Show only brand-related tabs -->
			<button
				class="tab {activeTab === 'brand' ? 'tab-active' : ''}"
				onclick={() => (activeTab = 'brand')}
			>
				Brand Profile
			</button>
			<button
				class="tab {activeTab === 'following' ? 'tab-active' : ''}"
				onclick={() => (activeTab = 'following')}
			>
				Followers
			</button>
			<button
				class="tab {activeTab === 'team' ? 'tab-active' : ''}"
				onclick={() => (activeTab = 'team')}
			>
				Team
			</button>
			<button
				class="tab {activeTab === 'stats' ? 'tab-active' : ''}"
				onclick={() => (activeTab = 'stats')}
			>
				Stats
			</button>
		{:else}
			<!-- Personal Context: Show only personal tabs -->
			<button
				class="tab {activeTab === 'profile' ? 'tab-active' : ''}"
				onclick={() => (activeTab = 'profile')}
			>
				Profile
			</button>
			<button
				class="tab {activeTab === 'account' ? 'tab-active' : ''}"
				onclick={() => (activeTab = 'account')}
			>
				Account
			</button>
			<button
				class="tab {activeTab === 'following' ? 'tab-active' : ''}"
				onclick={() => (activeTab = 'following')}
			>
				Following
			</button>
			<button
				class="tab {activeTab === 'stats' ? 'tab-active' : ''}"
				onclick={() => (activeTab = 'stats')}
			>
				Stats
			</button>
		{/if}
	</div>

	<!-- Profile Tab -->
	{#if activeTab === 'profile'}
		<div class="bg-base-200 rounded-lg p-6">
			<h2 class="text-2xl font-bold mb-4">Profile Information</h2>

			<!-- Avatar Upload -->
			<div class="mb-6">
				<h3 class="text-lg font-semibold mb-3">Profile Picture</h3>

				{#if form?.error}
					<div class="alert alert-error mb-4">
						<svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
						</svg>
						<span>{form.error}</span>
					</div>
				{/if}

				<div class="flex flex-col md:flex-row items-start md:items-center gap-6">
					<!-- Avatar Preview with Drag & Drop -->
					<div
						class="relative group"
						role="button"
						tabindex="0"
						ondragover={(e) => handleDragOver(e, 'avatar')}
						ondragleave={() => handleDragLeave('avatar')}
						ondrop={(e) => {
							const form = document.querySelector('form[action="?/uploadAvatar"]') as HTMLFormElement;
							if (form) handleDrop(e, 'avatar', form);
						}}
					>
						<div class="avatar">
							<div class="w-32 h-32 rounded-full bg-base-300 {avatarDragOver ? 'ring-4 ring-primary' : ''}">
								{#if avatarPreview}
									<img src={avatarPreview} alt="Preview" class="object-cover" />
								{:else if data.profile?.avatar_url}
									<img src={data.profile.avatar_url} alt={data.profile.username} class="object-cover" />
								{:else}
									<div class="w-full h-full flex items-center justify-center text-4xl font-bold">
										{username[0]?.toUpperCase() || '?'}
									</div>
								{/if}
							</div>
						</div>
						{#if data.profile?.avatar_url}
							<button
								type="button"
								onclick={() => deleteImage('avatar')}
								class="absolute -top-2 -right-2 btn btn-circle btn-xs btn-error opacity-0 group-hover:opacity-100 transition-opacity"
								disabled={loading}
								aria-label="Remove avatar"
							>
								<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
								</svg>
							</button>
						{/if}
					</div>

					<!-- Upload Controls -->
					<div class="flex-1">
						<form
							method="POST"
							action="?/uploadAvatar"
							enctype="multipart/form-data"
							use:enhance={() => {
								loading = true;
								return async ({ result, update }) => {
									await update();
									loading = false;
									avatarPreview = null;
								};
							}}
						>
							<input
								type="file"
								id="avatar-input"
								name="avatar"
								accept="image/*"
								class="hidden"
								onchange={async (e) => {
									const input = e.currentTarget;
									const form = input.closest('form');
									if (form && input.files?.length) {
										await handleImageUpload(input.files[0], 'avatar', form);
									}
								}}
							/>
						</form>
						<label for="avatar-input" class="btn btn-primary btn-sm mb-2 {loading ? 'loading' : ''}">
							{#if loading}
								<span class="loading loading-spinner loading-xs"></span>
								Uploading...
							{:else}
								<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
								</svg>
								Change Picture
							{/if}
						</label>
						<p class="text-xs opacity-70">Min 200×200px. JPG, PNG or GIF. Max 2MB.</p>
						<p class="text-xs opacity-70 mt-1">Drag and drop an image or click to browse</p>
					</div>
				</div>
			</div>

			<!-- Cover Image Upload for Users -->
			<div class="mb-6">
				<h3 class="text-lg font-semibold mb-3">Cover Image</h3>
				<div class="space-y-4">
					<!-- Banner Preview with Drag & Drop -->
					<div
						class="relative group w-full h-48 rounded-lg overflow-hidden bg-base-300 {bannerDragOver ? 'ring-4 ring-primary' : ''}"
						role="button"
						tabindex="0"
						ondragover={(e) => handleDragOver(e, 'banner')}
						ondragleave={() => handleDragLeave('banner')}
						ondrop={(e) => {
							const form = document.querySelector('form[action="?/uploadUserBanner"]') as HTMLFormElement;
							if (form) handleDrop(e, 'banner', form);
						}}
					>
						{#if bannerPreview}
							<img src={bannerPreview} alt="Preview" class="w-full h-full object-cover" />
						{:else if data.profile?.banner_url}
							<img src={data.profile.banner_url} alt="{username} cover" class="w-full h-full object-cover" />
						{:else}
							<div class="w-full h-full flex flex-col items-center justify-center opacity-50">
								<svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
								</svg>
								<span>No cover image</span>
								<span class="text-xs mt-1">Drag and drop or click below to upload</span>
							</div>
						{/if}
						{#if data.profile?.banner_url}
							<button
								type="button"
								onclick={() => deleteImage('banner')}
								class="absolute top-4 right-4 btn btn-sm btn-error opacity-0 group-hover:opacity-100 transition-opacity"
								disabled={loading}
							>
								<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
								</svg>
								Remove
							</button>
						{/if}
					</div>

					<!-- Upload Controls -->
					<div>
						<form
							method="POST"
							action="?/uploadUserBanner"
							enctype="multipart/form-data"
							use:enhance={() => {
								loading = true;
								return async ({ update }) => {
									await update();
									loading = false;
									bannerPreview = null;
								};
							}}
						>
							<input
								type="file"
								id="banner-input"
								name="banner"
								accept="image/*"
								class="hidden"
								onchange={async (e) => {
									const input = e.currentTarget;
									const form = input.closest('form');
									if (form && input.files?.length) {
										await handleImageUpload(input.files[0], 'banner', form);
									}
								}}
							/>
						</form>
						<button type="button" onclick={() => document.getElementById('banner-input')?.click()} class="btn btn-primary btn-sm {loading ? 'loading' : ''}">
							{#if loading}
								<span class="loading loading-spinner loading-xs"></span>
								Uploading...
							{:else}
								<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
								</svg>
								Change Cover Image
							{/if}
						</button>
						<p class="text-xs opacity-70 mt-2">Min 800×200px. Recommended: 1200×400px. JPG or PNG. Max 5MB.</p>
					</div>
				</div>
			</div>

			<div class="divider"></div>

			<form
				method="POST"
				action="?/updateProfile"
				use:enhance={() => {
					loading = true;
					return async ({ update }) => {
						loading = false;
						await update();
					};
				}}
			>
				<div class="form-control mb-4 w-full">
					<label for="username" class="label">
						<span class="label-text">Username</span>
					</label>
					<input
						type="text"
						id="username"
						name="username"
						bind:value={username}
						class="input input-bordered w-full"
						required
						pattern="[a-zA-Z0-9_]+"
						minlength="3"
						maxlength="30"
					/>
					<div class="label">
						<span class="label-text-alt">Letters, numbers, and underscores only</span>
					</div>
				</div>

				<div class="form-control mb-4 w-full">
					<label for="user-bio" class="label">
						<span class="label-text">Bio</span>
					</label>
					<textarea
						id="user-bio"
						name="bio"
						bind:value={userBio}
						class="textarea textarea-bordered h-24 w-full"
						maxlength="500"
						placeholder="Tell us about yourself..."
					></textarea>
					<div class="label">
						<span class="label-text-alt">{userBio.length}/500 characters</span>
					</div>
				</div>

				<div class="divider mt-6 mb-4">Social Links & Website</div>

				<div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
					<div class="form-control w-full">
						<label for="website" class="label">
							<span class="label-text">Website</span>
						</label>
						<input
							type="url"
							id="website"
							name="website_url"
							bind:value={websiteUrl}
							class="input input-bordered w-full"
							placeholder="https://example.com"
						/>
					</div>

					<div class="form-control w-full">
						<label for="twitter" class="label">
							<span class="label-text">X (Twitter)</span>
						</label>
						<input
							type="url"
							id="twitter"
							name="twitter_url"
							bind:value={twitterUrl}
							class="input input-bordered w-full"
							placeholder="https://x.com/username"
						/>
					</div>

					<div class="form-control w-full">
						<label for="facebook" class="label">
							<span class="label-text">Facebook</span>
						</label>
						<input
							type="url"
							id="facebook"
							name="facebook_url"
							bind:value={facebookUrl}
							class="input input-bordered w-full"
							placeholder="https://facebook.com/username"
						/>
					</div>

					<div class="form-control w-full">
						<label for="instagram" class="label">
							<span class="label-text">Instagram</span>
						</label>
						<input
							type="url"
							id="instagram"
							name="instagram_url"
							bind:value={instagramUrl}
							class="input input-bordered w-full"
							placeholder="https://instagram.com/username"
						/>
					</div>

					<div class="form-control w-full">
						<label for="linkedin" class="label">
							<span class="label-text">LinkedIn</span>
						</label>
						<input
							type="url"
							id="linkedin"
							name="linkedin_url"
							bind:value={linkedinUrl}
							class="input input-bordered w-full"
							placeholder="https://linkedin.com/in/username"
						/>
					</div>

					<div class="form-control w-full">
						<label for="youtube" class="label">
							<span class="label-text">YouTube</span>
						</label>
						<input
							type="url"
							id="youtube"
							name="youtube_url"
							bind:value={youtubeUrl}
							class="input input-bordered w-full"
							placeholder="https://youtube.com/@username"
						/>
					</div>

					<div class="form-control w-full">
						<label for="tiktok" class="label">
							<span class="label-text">TikTok</span>
						</label>
						<input
							type="url"
							id="tiktok"
							name="tiktok_url"
							bind:value={tiktokUrl}
							class="input input-bordered w-full"
							placeholder="https://tiktok.com/@username"
						/>
					</div>

					<div class="form-control w-full">
						<label for="substack" class="label">
							<span class="label-text">Substack</span>
						</label>
						<input
							type="url"
							id="substack"
							name="substack_url"
							bind:value={substackUrl}
							class="input input-bordered w-full"
							placeholder="https://username.substack.com"
						/>
					</div>
				</div>

				<div class="flex gap-4">
					<button type="submit" class="btn btn-primary" disabled={loading}>
						{#if loading}
							<span class="loading loading-spinner loading-sm"></span>
						{/if}
						Save Profile
					</button>
				</div>
			</form>

			<div class="divider"></div>

			<h3 class="text-xl font-bold mb-4">Account Details</h3>
			<div class="space-y-2">
				<div>
					<p class="text-sm opacity-70">Account Type</p>
					<p class="font-semibold capitalize">{data.profile?.account_type}</p>
				</div>
				<div>
					<p class="text-sm opacity-70">Member Since</p>
					<p>
						{data.profile?.created_at
							? new Date(data.profile.created_at).toLocaleDateString('en-US', {
									year: 'numeric',
									month: 'long',
									day: 'numeric'
								})
							: 'Unknown'}
					</p>
				</div>
			</div>
		</div>
	{/if}

	<!-- Account Tab -->
	{#if activeTab === 'account'}
		<div class="bg-base-200 rounded-lg p-6">
			<h2 class="text-2xl font-bold mb-4">Account Settings</h2>

			<div class="space-y-6">
				<!-- Email Address -->
				<div>
					<h3 class="text-lg font-semibold mb-2">Email Address</h3>
					<p class="text-sm opacity-70 mb-2">Your account email address</p>
					<div class="form-control">
						<input
							type="email"
							value={data.session?.user?.email || ''}
							class="input input-bordered"
							disabled
						/>
						<label class="label">
							<span class="label-text-alt">Email cannot be changed here. Contact support to update.</span>
						</label>
					</div>
				</div>

				<div class="divider"></div>

				<!-- Notifications -->
				<div>
					<h3 class="text-lg font-semibold mb-2">Notification Preferences</h3>
					<p class="text-sm opacity-70 mb-4">Choose what you want to be notified about</p>
					<form
						method="POST"
						action="?/updateNotificationPreferences"
						use:enhance={() => {
							loading = true;
							return async ({ update }) => {
								loading = false;
								await update();
							};
						}}
					>
						<div class="form-control">
							<label class="label cursor-pointer justify-start gap-4">
								<input type="checkbox" name="new_post" class="checkbox" bind:checked={notificationPrefs.new_post} />
								<div>
									<div class="font-medium">New Posts</div>
									<div class="text-sm opacity-70">Get notified when users/brands you follow post</div>
								</div>
							</label>
						</div>
						<div class="form-control">
							<label class="label cursor-pointer justify-start gap-4">
								<input type="checkbox" name="comment_reply" class="checkbox" bind:checked={notificationPrefs.comment_reply} />
								<div>
									<div class="font-medium">Comments & Replies</div>
									<div class="text-sm opacity-70">Get notified when someone replies to your posts or comments</div>
								</div>
							</label>
						</div>
						<div class="form-control">
							<label class="label cursor-pointer justify-start gap-4">
								<input type="checkbox" name="new_follower" class="checkbox" bind:checked={notificationPrefs.new_follower} />
								<div>
									<div class="font-medium">New Followers</div>
									<div class="text-sm opacity-70">Get notified when someone follows you</div>
								</div>
							</label>
						</div>
						<div class="form-control">
							<label class="label cursor-pointer justify-start gap-4">
								<input type="checkbox" name="mention" class="checkbox" bind:checked={notificationPrefs.mention} />
								<div>
									<div class="font-medium">Mentions</div>
									<div class="text-sm opacity-70">Get notified when someone mentions you with @</div>
								</div>
							</label>
						</div>
						<div class="form-control">
							<label class="label cursor-pointer justify-start gap-4">
								<input type="checkbox" name="promotion" class="checkbox" bind:checked={notificationPrefs.promotion} />
								<div>
									<div class="font-medium">Promotions</div>
									<div class="text-sm opacity-70">Get notified about special promotions and offers</div>
								</div>
							</label>
						</div>

						<div class="mt-4">
							<button type="submit" class="btn btn-primary" disabled={loading}>
								{#if loading}
									<span class="loading loading-spinner loading-sm"></span>
								{/if}
								Save Preferences
							</button>
						</div>
					</form>
				</div>

				<div class="divider"></div>

				<!-- Privacy -->
				<div>
					<h3 class="text-lg font-semibold mb-2">Privacy</h3>
					<div class="form-control">
						<label class="label cursor-pointer justify-start gap-4">
							<input type="checkbox" class="checkbox" />
							<div>
								<div class="font-medium">Private Account</div>
								<div class="text-sm opacity-70">Only approved followers can see your posts</div>
							</div>
						</label>
					</div>
				</div>
			</div>
		</div>
	{/if}

	<!-- Brand Tab -->
	{#if activeTab === 'brand' && currentBrand}
		<div class="bg-base-200 rounded-lg p-6">
			<h2 class="text-2xl font-bold mb-4">Brand Settings</h2>

			<!-- Brand Logo Upload -->
			<div class="mb-6">
				<h3 class="text-lg font-semibold mb-3">Brand Logo</h3>
				<div class="flex flex-col md:flex-row items-start md:items-center gap-6">
					<!-- Brand Logo Preview with Drag & Drop -->
					<div
						class="relative group"
						role="button"
						tabindex="0"
						ondragover={(e) => handleDragOver(e, 'brand-logo')}
						ondragleave={() => handleDragLeave('brand-logo')}
						ondrop={(e) => {
							const form = document.querySelector('form[action="?/uploadLogo"]') as HTMLFormElement;
							if (form) handleDrop(e, 'brand-logo', form);
						}}
					>
						<div class="avatar">
							<div class="w-32 h-32 rounded-full bg-base-300 {brandLogoDragOver ? 'ring-4 ring-primary' : ''}">
								{#if brandLogoPreview}
									<img src={brandLogoPreview} alt="Preview" class="object-cover" />
								{:else if (currentBrand as any)?.logo_url}
									<img src={(currentBrand as any).logo_url} alt={brandName} class="object-cover" />
								{:else}
									<div class="w-full h-full flex items-center justify-center text-4xl font-bold">
										{brandName[0]?.toUpperCase() || '?'}
									</div>
								{/if}
							</div>
						</div>
						{#if (currentBrand as any)?.logo_url}
							<button
								type="button"
								onclick={() => deleteImage('brand-logo')}
								class="absolute -top-2 -right-2 btn btn-circle btn-xs btn-error opacity-0 group-hover:opacity-100 transition-opacity"
								disabled={loading}
								aria-label="Remove logo"
							>
								<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
								</svg>
							</button>
						{/if}
					</div>

					<!-- Upload Controls -->
					<div class="flex-1">
						<form
							method="POST"
							action="?/uploadLogo"
							enctype="multipart/form-data"
							use:enhance={() => {
								loading = true;
								return async ({ update }) => {
									await update();
									loading = false;
									brandLogoPreview = null;
								};
							}}
						>
							<input type="hidden" name="brand_id" value={(currentBrand as any)?.id} />
							<input
								type="file"
								id="brand-logo-input"
								name="logo"
								accept="image/*"
								class="hidden"
								onchange={async (e) => {
									const input = e.currentTarget;
									const form = input.closest('form');
									if (form && input.files?.length) {
										await handleImageUpload(input.files[0], 'brand-logo', form);
									}
								}}
							/>
						</form>
						<label for="brand-logo-input" class="btn btn-primary btn-sm mb-2 {loading ? 'loading' : ''}">
							{#if loading}
								<span class="loading loading-spinner loading-xs"></span>
								Uploading...
							{:else}
								<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
								</svg>
								Change Logo
							{/if}
						</label>
						<p class="text-xs opacity-70">Min 200×200px. JPG, PNG or GIF. Max 2MB.</p>
						<p class="text-xs opacity-70 mt-1">Drag and drop an image or click to browse</p>
					</div>
				</div>
			</div>

			<!-- Brand Banner Upload -->
			<div class="mb-6">
				<h3 class="text-lg font-semibold mb-3">Cover Image</h3>
				<div class="space-y-4">
					<!-- Brand Banner Preview with Drag & Drop -->
					<div
						class="relative group w-full h-48 rounded-lg overflow-hidden bg-base-300 {brandBannerDragOver ? 'ring-4 ring-primary' : ''}"
						role="button"
						tabindex="0"
						ondragover={(e) => handleDragOver(e, 'brand-banner')}
						ondragleave={() => handleDragLeave('brand-banner')}
						ondrop={(e) => {
							const form = document.querySelector('form[action="?/uploadBrandBanner"]') as HTMLFormElement;
							if (form) handleDrop(e, 'brand-banner', form);
						}}
					>
						{#if brandBannerPreview}
							<img src={brandBannerPreview} alt="Preview" class="w-full h-full object-cover" />
						{:else if (currentBrand as any)?.banner_url}
							<img src={(currentBrand as any).banner_url} alt="{brandName} banner" class="w-full h-full object-cover" />
						{:else}
							<div class="w-full h-full flex flex-col items-center justify-center opacity-50">
								<svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
								</svg>
								<span>No cover image</span>
								<span class="text-xs mt-1">Drag and drop or click below to upload</span>
							</div>
						{/if}
						{#if (currentBrand as any)?.banner_url}
							<button
								type="button"
								onclick={() => deleteImage('brand-banner')}
								class="absolute top-4 right-4 btn btn-sm btn-error opacity-0 group-hover:opacity-100 transition-opacity"
								disabled={loading}
							>
								<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
								</svg>
								Remove
							</button>
						{/if}
					</div>

					<!-- Upload Controls -->
					<div>
						<form
							method="POST"
							action="?/uploadBrandBanner"
							enctype="multipart/form-data"
							use:enhance={() => {
								loading = true;
								return async ({ update }) => {
									await update();
									loading = false;
									brandBannerPreview = null;
								};
							}}
						>
							<input type="hidden" name="brand_id" value={(currentBrand as any)?.id} />
							<input
								type="file"
								id="brand-banner-input"
								name="banner"
								accept="image/*"
								class="hidden"
								onchange={async (e) => {
									const input = e.currentTarget;
									const form = input.closest('form');
									if (form && input.files?.length) {
										await handleImageUpload(input.files[0], 'brand-banner', form);
									}
								}}
							/>
						</form>
						<button type="button" onclick={() => document.getElementById('brand-banner-input')?.click()} class="btn btn-primary btn-sm {loading ? 'loading' : ''}">
							{#if loading}
								<span class="loading loading-spinner loading-xs"></span>
								Uploading...
							{:else}
								<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
								</svg>
								Change Cover Image
							{/if}
						</button>
						<p class="text-xs opacity-70 mt-2">Min 800×200px. Recommended: 1200×400px. JPG or PNG. Max 5MB.</p>
					</div>
				</div>
			</div>

			<div class="divider"></div>

			<form
				method="POST"
				action="?/updateBrand"
				use:enhance={() => {
					loading = true;
					return async ({ update }) => {
						loading = false;
						await update();
					};
				}}
			>
				<input type="hidden" name="brand_id" value={(currentBrand as any)?.id} />

				<div class="form-control mb-4">
					<label class="label" for="brand_name">
						<span class="label-text">Brand Name</span>
					</label>
					<input
						type="text"
						id="brand_name"
						name="brand_name"
						bind:value={brandName}
						class="input input-bordered"
						required
						maxlength="100"
					/>
				</div>

				<div class="form-control mb-4">
					<label class="label" for="brand-description">
						<span class="label-text">Brand Description</span>
					</label>
					<textarea
						id="brand-description"
						name="description"
						bind:value={brandDescription}
						class="textarea textarea-bordered h-24"
						maxlength="500"
						placeholder="Tell people about your brand..."
					></textarea>
					<label class="label">
						<span class="label-text-alt">{brandDescription.length}/500 characters</span>
					</label>
				</div>

				<div class="form-control mb-4">
					<label class="label" for="brand-website">
						<span class="label-text">Website</span>
					</label>
					<input
						type="url"
						id="brand-website"
						name="website_url"
						bind:value={brandWebsiteUrl}
						class="input input-bordered"
						placeholder="https://example.com"
					/>
				</div>

				<div class="form-control mb-4">
					<div class="label">
						<span class="label-text">Categories</span>
					</div>
					<input
						type="text"
						id="categories"
						name="categories"
						bind:value={categories}
						class="input input-bordered"
						placeholder="Sports, Gaming, Entertainment"
					/>
					<label class="label">
						<span class="label-text-alt">Separate categories with commas</span>
					</label>
				</div>

				<div class="flex gap-4">
					<button type="submit" class="btn btn-primary" disabled={loading}>
						{#if loading}
							<span class="loading loading-spinner loading-sm"></span>
						{/if}
						Save Brand Settings
					</button>
				</div>
			</form>

			<div class="divider"></div>

			<h3 class="text-xl font-bold mb-4">Brand Information</h3>
			<div class="space-y-2">
				<div>
					<p class="text-sm opacity-70">Brand Slug</p>
					<p class="font-semibold">/{(currentBrand as any)?.slug}</p>
				</div>
				<div>
					<p class="text-sm opacity-70">Created</p>
					<p>
						{(currentBrand as any)?.created_at
							? new Date((currentBrand as any).created_at).toLocaleDateString('en-US', {
									year: 'numeric',
									month: 'long',
									day: 'numeric'
								})
							: 'Unknown'}
					</p>
				</div>
			</div>
		</div>
	{/if}

	<!-- Team Tab -->
	{#if activeTab === 'team' && currentBrand}
		<div class="bg-base-200 rounded-lg p-6">
			<h2 class="text-2xl font-bold mb-4">Team Management</h2>
			<p class="text-sm opacity-70 mb-6">Manage who can access and edit {data.brand?.brand_name}</p>

			<!-- Add New Member Form -->
			<div class="bg-base-300 rounded-lg p-4 mb-6">
				<h3 class="text-lg font-semibold mb-3">Add Team Member</h3>
				<form
					method="POST"
					action="?/addBrandMember"
					use:enhance={() => {
						loading = true;
						return async ({ result, update }) => {
							loading = false;
							if (result.type === 'success') {
								newMemberUsername = '';
								newMemberRole = 'editor';
							}
							await update();
						};
					}}
				>
					<input type="hidden" name="brand_id" value={(currentBrand as any)?.id} />
					<div class="flex flex-col sm:flex-row gap-3">
						<div class="form-control flex-1">
							<input
								type="text"
								name="username"
								bind:value={newMemberUsername}
								placeholder="Enter username"
								class="input input-bordered"
								required
								disabled={loading}
							/>
						</div>
						<div class="form-control w-full sm:w-40">
							<select name="role" bind:value={newMemberRole} class="select select-bordered" disabled={loading}>
								<option value="admin">Admin</option>
								<option value="editor">Editor</option>
								<option value="viewer">Viewer</option>
							</select>
						</div>
						<button type="submit" class="btn btn-primary" disabled={loading || !newMemberUsername.trim()}>
							{#if loading}
								<span class="loading loading-spinner loading-xs"></span>
							{/if}
							Add Member
						</button>
					</div>
				</form>
			</div>

			<!-- Current Team Members -->
			<div class="space-y-2">
				<h3 class="text-lg font-semibold mb-3">Current Members ({data.brandMembers?.length || 0})</h3>
				{#if data.brandMembers && data.brandMembers.length > 0}
					{#each data.brandMembers as member}
						<div class="bg-base-300 rounded-lg p-4">
							<div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
								<!-- Member Info -->
								<div class="flex items-center gap-3">
									<div class="avatar placeholder">
										<div class="bg-neutral text-neutral-content rounded-full w-12">
											{#if member.user?.avatar_url}
												<img src={member.user.avatar_url} alt={member.user.username} class="object-cover" />
											{:else}
												<span class="text-lg">{member.user?.username?.[0]?.toUpperCase() || '?'}</span>
											{/if}
										</div>
									</div>
									<div class="flex-1">
										<a href="/u/{member.user?.username}" class="font-semibold hover:text-primary" target="_blank">
											{member.user?.display_name || member.user?.username}
										</a>
										<p class="text-sm opacity-70">@{member.user?.username}</p>
										<p class="text-xs opacity-60 mt-1">
											Joined {new Date(member.created_at).toLocaleDateString()}
										</p>
									</div>
								</div>

								<!-- Role & Actions -->
								<div class="flex items-center gap-2">
									{#if member.role === 'owner'}
										<div class="badge badge-primary badge-lg">Owner</div>
									{:else}
										<form
											method="POST"
											action="?/updateBrandMemberRole"
											use:enhance={() => {
												managingMemberId = member.user?.id || null;
												return async ({ update }) => {
													managingMemberId = null;
													await update();
												};
											}}
										>
											<input type="hidden" name="brand_id" value={(currentBrand as any)?.id} />
											<input type="hidden" name="user_id" value={member.user?.id} />
											<select
												name="role"
												value={member.role}
												class="select select-bordered select-sm"
												onchange={(e) => e.currentTarget.form?.requestSubmit()}
												disabled={managingMemberId === member.user?.id}
											>
												<option value="admin">Admin</option>
												<option value="editor">Editor</option>
												<option value="viewer">Viewer</option>
											</select>
										</form>

										<form
											method="POST"
											action="?/removeBrandMember"
											use:enhance={() => {
												if (!confirm(`Remove ${member.user?.username} from the team?`)) {
													return ({ cancel }) => cancel();
												}
												managingMemberId = member.user?.id || null;
												return async ({ update }) => {
													managingMemberId = null;
													await update();
												};
											}}
										>
											<input type="hidden" name="brand_id" value={(currentBrand as any)?.id} />
											<input type="hidden" name="user_id" value={member.user?.id} />
											<button
												type="submit"
												class="btn btn-sm btn-error btn-outline"
												disabled={managingMemberId === member.user?.id}
											>
												{#if managingMemberId === member.user?.id}
													<span class="loading loading-spinner loading-xs"></span>
												{:else}
													Remove
												{/if}
											</button>
										</form>
									{/if}
								</div>
							</div>

							<!-- Role Permissions Info -->
							<div class="mt-3 text-xs opacity-70">
								{#if member.role === 'owner'}
									<p>Full access to all brand settings and content</p>
								{:else if member.role === 'admin'}
									<p>Can manage posts, edit brand settings, and manage team members</p>
								{:else if member.role === 'editor'}
									<p>Can create, edit, and publish posts</p>
								{:else if member.role === 'viewer'}
									<p>Can view draft posts and analytics</p>
								{/if}
							</div>
						</div>
					{/each}
				{:else}
					<div class="text-center py-8 opacity-70">
						<p>No team members yet. Add your first member above!</p>
					</div>
				{/if}
			</div>
		</div>
	{/if}

	<!-- Following/Followers Tab - Context Aware -->
	{#if activeTab === 'following'}
		<div class="bg-base-200 rounded-lg p-6">
			{#if data.brand}
				<!-- Brand Context: Show Followers -->
				<h2 class="text-2xl font-bold mb-4">{data.brand.brand_name} Followers</h2>

				{#if data.followers && data.followers.length > 0}
					<div class="space-y-2">
						{#each data.followers as { follower }}
							<div class="flex items-center gap-3 p-3 bg-base-300 rounded-lg">
								<div class="avatar placeholder">
									<div class="bg-neutral text-neutral-content rounded-full w-10">
										{#if follower?.avatar_url}
											<img src={follower.avatar_url} alt={follower.username} class="object-cover" />
										{:else}
											<span class="text-lg">{follower?.username?.[0]?.toUpperCase() || '?'}</span>
										{/if}
									</div>
								</div>
								<div>
									<a href="/u/{follower?.username}" class="font-semibold hover:text-primary">
										{follower?.display_name || follower?.username}
									</a>
									<p class="text-sm opacity-70">@{follower?.username}</p>
								</div>
							</div>
						{/each}
					</div>
					<p class="text-sm opacity-70 mt-4 text-center">Total: {data.followersCount} followers</p>
				{:else}
					<div class="text-center py-8 opacity-70">
						<p>No one is following {data.brand.brand_name} yet.</p>
						<p class="text-sm mt-2">Share your brand to get followers!</p>
					</div>
				{/if}
			{:else}
				<!-- Personal Context: Show Following -->
				<h2 class="text-2xl font-bold mb-4">Following</h2>

				{#if unfollowError}
					<div class="alert alert-error mb-4">
						<svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
						</svg>
						<span>{unfollowError}</span>
						<button class="btn btn-sm btn-ghost" onclick={() => unfollowError = null}>✕</button>
					</div>
				{/if}

				{#if data.following && data.following.length > 0}
					<div class="space-y-2">
						{#each data.following as follow}
							<div class="flex items-center justify-between p-3 bg-base-300 rounded-lg">
								<div class="flex items-center gap-3">
									<div class="avatar placeholder">
										<div class="bg-neutral text-neutral-content rounded-full w-10">
											{#if follow.brand?.logo_url}
												<img src={follow.brand.logo_url} alt={follow.brand.brand_name} class="object-cover" />
											{:else}
												<span class="text-lg">{follow.brand?.brand_name?.[0] || '?'}</span>
											{/if}
										</div>
									</div>
									<div>
										<a href="/{follow.brand?.slug}" class="font-semibold hover:text-primary">
											{follow.brand?.brand_name || 'Unknown'}
										</a>
										<p class="text-sm opacity-70">{follow.brand?.follower_count || 0} followers</p>
									</div>
								</div>
								<button
									class="btn btn-sm btn-outline"
									onclick={() => handleUnfollow(follow.brand?.id)}
									disabled={unfollowingBrandId === follow.brand?.id}
								>
									{#if unfollowingBrandId === follow.brand?.id}
										<span class="loading loading-spinner loading-xs"></span>
									{:else}
										Unfollow
									{/if}
								</button>
							</div>
						{/each}
					</div>
					<p class="text-sm opacity-70 mt-4 text-center">Following {data.followingCount} brands</p>
				{:else}
					<div class="text-center py-8 opacity-70">
						<p>You're not following any brands yet.</p>
						<a href="/explore" class="btn btn-primary btn-sm mt-4">Explore Brands</a>
					</div>
				{/if}
			{/if}
		</div>
	{/if}

	<!-- Stats Tab - Context Aware -->
	{#if activeTab === 'stats'}
		<div class="bg-base-200 rounded-lg p-6">
			{#if data.brand}
				<!-- Brand Context Stats -->
				<h2 class="text-2xl font-bold mb-4">{data.brand.brand_name} Stats</h2>

				<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
					<div class="stat bg-base-300 rounded-lg">
						<div class="stat-title">Followers</div>
						<div class="stat-value text-primary">{data.followersCount || 0}</div>
						<div class="stat-desc">People following this brand</div>
					</div>

					<div class="stat bg-base-300 rounded-lg">
						<div class="stat-title">Created</div>
						<div class="stat-value text-sm">
							{data.brand.created_at
								? new Date(data.brand.created_at).toLocaleDateString('en-US', {
										year: 'numeric',
										month: 'short'
									})
								: 'Unknown'}
						</div>
						<div class="stat-desc">Brand creation date</div>
					</div>

					<div class="stat bg-base-300 rounded-lg">
						<div class="stat-title">Brand Slug</div>
						<div class="stat-value text-sm">/{data.brand.slug}</div>
						<div class="stat-desc">Your brand URL</div>
					</div>

					<div class="stat bg-base-300 rounded-lg">
						<div class="stat-title">Categories</div>
						<div class="stat-value text-sm">
							{data.brand.categories?.length || 0}
						</div>
						<div class="stat-desc">Topic categories</div>
					</div>
				</div>

				<div class="divider"></div>
				<div class="flex gap-4">
					<a href="/{data.brand.slug}" class="btn btn-outline">
						<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
						</svg>
						View Public Brand Page
					</a>
				</div>
			{:else}
				<!-- Personal Context Stats -->
				<h2 class="text-2xl font-bold mb-4">Stats</h2>

				<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
					<div class="stat bg-base-300 rounded-lg">
						<div class="stat-title">Following</div>
						<div class="stat-value text-primary">{data.followingCount}</div>
						<div class="stat-desc">Brands you follow</div>
					</div>

					<div class="stat bg-base-300 rounded-lg">
						<div class="stat-title">Brands Owned</div>
						<div class="stat-value text-secondary">{data.brands?.length || 0}</div>
						<div class="stat-desc">Your brands</div>
					</div>

					<div class="stat bg-base-300 rounded-lg">
						<div class="stat-title">Account Type</div>
						<div class="stat-value text-sm capitalize">{data.profile?.account_type}</div>
						<div class="stat-desc">Your account level</div>
					</div>

					<div class="stat bg-base-300 rounded-lg">
						<div class="stat-title">Member Since</div>
						<div class="stat-value text-sm">
							{data.profile?.created_at
								? new Date(data.profile.created_at).toLocaleDateString('en-US', {
										year: 'numeric',
										month: 'short'
									})
								: 'Unknown'}
						</div>
						<div class="stat-desc">Join date</div>
					</div>
				</div>

				<div class="divider"></div>
				<div class="flex gap-4">
					<a href="/u/{data.profile?.username}" class="btn btn-outline">
						<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
						</svg>
						View Public Profile
					</a>
				</div>
			{/if}
		</div>
	{/if}
</div>
