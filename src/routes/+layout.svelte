<script lang="ts">
	import './layout.css';
	import favicon from '$lib/assets/favicon.svg';
	import { invalidate } from '$app/navigation';
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase/client';
	import { goto } from '$app/navigation';
	import NotificationBell from '$lib/components/NotificationBell.svelte';
	import Toast from '$lib/components/Toast.svelte';

	let { children, data } = $props();

	let searchQuery = $state('');

	function handleSearch(e?: Event) {
		e?.preventDefault();
		if (searchQuery.trim()) {
			goto(`/search?q=${encodeURIComponent(searchQuery.trim())}`);
		}
	}

	onMount(() => {
		const {
			data: { subscription }
		} = supabase.auth.onAuthStateChange(() => {
			invalidate('supabase:auth');
		});

		return () => {
			subscription.unsubscribe();
		};
	});
</script>

<svelte:head><link rel="icon" href={favicon} /></svelte:head>

<div class="min-h-screen bg-base-100">
	{#if data?.session}
		<nav class="navbar bg-base-200 border-b border-base-300">
			<div class="navbar-start">
				<!-- Hamburger Menu Button (Mobile) -->
				<div class="dropdown lg:hidden">
					<button
						tabindex="0"
						class="btn btn-ghost btn-circle"
						aria-label="Menu"
					>
						<svg
							xmlns="http://www.w3.org/2000/svg"
							class="h-5 w-5"
							fill="none"
							viewBox="0 0 24 24"
							stroke="currentColor"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M4 6h16M4 12h16M4 18h16"
							/>
						</svg>
					</button>
					<ul
						class="menu dropdown-content mt-3 z-[1] p-2 shadow bg-base-200 rounded-box w-56"
					>
						<li>
							<a href="/feed{data.currentBrand ? `?brand=${data.currentBrand.slug}` : ''}" class="py-3">
								<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
								</svg>
								Home
							</a>
						</li>
						<li>
							<a href="/search" class="py-3">
								<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
								</svg>
								Search
							</a>
						</li>
						{#if data.profileUrl}
							<li>
								<a href={data.profileUrl} class="py-3">
									<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
									</svg>
									View Profile
								</a>
							</li>
							<div class="divider my-1"></div>
						{/if}
						<li>
							<a href="/dashboard{data.currentBrand ? `?brand=${data.currentBrand.slug}` : ''}" class="py-3">
								<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
								</svg>
								Dashboard
							</a>
						</li>
						<li>
							<a href="/explore" class="py-3">
								<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
								</svg>
								Explore
							</a>
						</li>
						<li>
							<a href="/dashboard/posts/new" class="py-3">
								<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
								</svg>
								New Post
							</a>
						</li>
						<div class="divider my-1"></div>
						<li>
							<a href="/settings{data.currentBrand ? `?brand=${data.currentBrand.slug}` : ''}" class="py-3">
								<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
								</svg>
								Settings
							</a>
						</li>
						<li>
							<a href="/bookmarks" class="py-3">
								<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
								</svg>
								Bookmarks
							</a>
						</li>
						<div class="divider my-1"></div>
						<li>
							<a href="/brands/create" class="py-3 text-primary">
								<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
								</svg>
								Create Brand
							</a>
						</li>
						<li>
							<form method="POST" action="/auth/logout">
								<button type="submit" class="w-full text-left py-3 flex items-center gap-3">
									<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
									</svg>
									Logout
								</button>
							</form>
						</li>
					</ul>
				</div>

				<a href="/feed{data.currentBrand ? `?brand=${data.currentBrand.slug}` : ''}" class="btn btn-ghost text-xl text-primary">BetChat</a>
			</div>
			<div class="navbar-center hidden lg:flex gap-4">
				<ul class="menu menu-horizontal px-1">
					<li>
						<a href="/feed{data.currentBrand ? `?brand=${data.currentBrand.slug}` : ''}">
							<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
							</svg>
							Home
						</a>
					</li>
					<li>
						<a href="/dashboard{data.currentBrand ? `?brand=${data.currentBrand.slug}` : ''}">
							<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
							</svg>
							Dashboard
						</a>
					</li>
					<li>
						<a href="/explore">
							<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
							</svg>
							Explore
						</a>
					</li>
				</ul>

				<!-- Search Bar (Desktop) -->
				<form onsubmit={handleSearch} class="form-control">
					<div class="input-group">
						<input
							type="text"
							bind:value={searchQuery}
							placeholder="Search..."
							class="input input-bordered input-sm w-64"
						/>
						<button type="submit" class="btn btn-square btn-sm" aria-label="Search">
							<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
							</svg>
						</button>
					</div>
				</form>
			</div>
			<div class="navbar-end gap-2">
				<!-- Search Icon (Mobile) -->
				<a href="/search" class="btn btn-ghost btn-circle lg:hidden" aria-label="Search">
					<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
					</svg>
				</a>
				<a href="/dashboard/posts/new{data.currentBrand ? `?brand=${data.currentBrand.slug}` : ''}" class="btn btn-primary btn-sm hidden sm:flex">
					<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
					</svg>
					New Post
				</a>
				<NotificationBell
					userId={data.session.user.id}
					initialUnreadCount={data.unreadCount}
				/>
				<div class="dropdown dropdown-end">
					<button tabindex="0" class="btn btn-ghost btn-circle avatar" aria-label="User menu">
						<div class="w-10 h-10 rounded-full">
							{#if data.currentBrand}
								<!-- In brand context -->
								{#if data.currentBrand.logo_url}
									<img
										src={data.currentBrand.logo_url}
										alt={data.currentBrand.brand_name}
										class="w-full h-full object-cover rounded-full"
									/>
								{:else}
									<div class="w-full h-full bg-neutral text-neutral-content flex items-center justify-center rounded-full">
										<span class="text-sm font-semibold">
											{data.currentBrand.brand_name[0].toUpperCase()}
										</span>
									</div>
								{/if}
							{:else if data.profile?.avatar_url}
								<!-- In personal context with avatar -->
								<img
									src={data.profile.avatar_url}
									alt={data.profile.username}
									class="w-full h-full object-cover rounded-full"
								/>
							{:else}
								<!-- In personal context without avatar -->
								<div class="w-full h-full bg-neutral text-neutral-content flex items-center justify-center rounded-full">
									<span class="text-sm font-semibold">
										{data.profile?.username?.[0]?.toUpperCase() || 'U'}
									</span>
								</div>
							{/if}
						</div>
					</button>
					<ul
						role="menu"
						class="menu dropdown-content mt-3 z-50 p-2 shadow bg-base-200 rounded-box w-56 border border-base-300"
					>
						<!-- Context Switching Section -->
						{#if data.currentBrand}
							<!-- Currently in brand context, show personal account + all other brands -->
							<!-- Personal Account -->
							<li>
								<a href="/dashboard" class="py-2 gap-3">
									<div class="avatar">
										<div class="w-8 h-8 rounded-full">
											{#if data.profile?.avatar_url}
												<img src={data.profile.avatar_url} alt={data.profile.username} class="object-cover" />
											{:else}
												<div class="w-full h-full bg-neutral text-neutral-content flex items-center justify-center text-xs font-semibold">
													{data.profile?.username?.[0]?.toUpperCase() || 'U'}
												</div>
											{/if}
										</div>
									</div>
									<div class="flex-1">
										<div class="font-medium">{data.profile?.display_name || data.profile?.username}</div>
										<div class="text-xs opacity-60">Switch to personal</div>
									</div>
								</a>
							</li>

							<!-- Other Brands (exclude current brand) -->
							{#if data.brands && data.brands.length > 0}
								{#each data.brands as brand}
									{#if brand.id !== data.currentBrand.id}
										<li>
											<a href="/dashboard?brand={brand.slug}" class="py-2 gap-3">
												<div class="avatar">
													<div class="w-8 h-8 rounded-full">
														{#if brand.logo_url}
															<img src={brand.logo_url} alt={brand.brand_name} class="object-cover" />
														{:else}
															<div class="w-full h-full bg-neutral text-neutral-content flex items-center justify-center text-xs font-semibold">
																{brand.brand_name[0].toUpperCase()}
															</div>
														{/if}
													</div>
												</div>
												<div class="flex-1">
													<div class="font-medium">{brand.brand_name}</div>
													<div class="text-xs opacity-60">Switch to brand</div>
												</div>
											</a>
										</li>
									{/if}
								{/each}
							{/if}
						{:else if data.brands && data.brands.length > 0}
							<!-- Currently in personal context, show all brands -->
							{#each data.brands as brand}
								<li>
									<a href="/dashboard?brand={brand.slug}" class="py-2 gap-3">
										<div class="avatar">
											<div class="w-8 h-8 rounded-full">
												{#if brand.logo_url}
													<img src={brand.logo_url} alt={brand.brand_name} class="object-cover" />
												{:else}
													<div class="w-full h-full bg-neutral text-neutral-content flex items-center justify-center text-xs font-semibold">
														{brand.brand_name[0].toUpperCase()}
													</div>
												{/if}
											</div>
										</div>
										<div class="flex-1">
											<div class="font-medium">{brand.brand_name}</div>
											<div class="text-xs opacity-60">Switch to brand</div>
										</div>
									</a>
								</li>
							{/each}
						{/if}

						{#if (data.currentBrand || (data.brands && data.brands.length > 0))}
							<div class="divider my-1"></div>
						{/if}

						<!-- View Profile -->
						{#if data.profileUrl}
							<li>
								<a href={data.profileUrl} class="py-3">
									<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
									</svg>
									View Profile
								</a>
							</li>
							<div class="divider my-1"></div>
						{/if}
						<li>
							<a href="/settings{data.currentBrand ? `?brand=${data.currentBrand.slug}` : ''}" class="py-3">
								<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
								</svg>
								Settings
							</a>
						</li>
						<li>
							<a href="/bookmarks" class="py-3">
								<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
								</svg>
								Bookmarks
							</a>
						</li>
						<div class="divider my-1"></div>
						<li>
							<a href="/brands/create" class="py-3 text-primary">
								<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
								</svg>
								Create Brand
							</a>
						</li>
						<li>
							<form method="POST" action="/auth/logout">
								<button type="submit" class="w-full text-left py-3 flex items-center gap-3">
									<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
									</svg>
									Logout
								</button>
							</form>
						</li>
					</ul>
				</div>
			</div>
		</nav>
	{:else}
		<nav class="navbar bg-base-200 border-b border-base-300">
			<div class="navbar-start">
				<a href="/" class="btn btn-ghost text-xl text-primary">BetChat</a>
			</div>
			<div class="navbar-center hidden md:flex">
				<!-- Search Bar (Public) -->
				<form onsubmit={handleSearch} class="form-control">
					<div class="input-group">
						<input
							type="text"
							bind:value={searchQuery}
							placeholder="Search..."
							class="input input-bordered input-sm w-64"
						/>
						<button type="submit" class="btn btn-square btn-sm" aria-label="Search">
							<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
							</svg>
						</button>
					</div>
				</form>
			</div>
			<div class="navbar-end gap-2">
				<a href="/search" class="btn btn-ghost btn-circle md:hidden" aria-label="Search">
					<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
					</svg>
				</a>
				<a href="/auth/login" class="btn btn-ghost">Login</a>
				<a href="/auth/signup" class="btn btn-primary">Sign Up</a>
			</div>
		</nav>
	{/if}

	<main>
		{@render children()}
	</main>

	<!-- Toast Notifications -->
	<Toast />
</div>
