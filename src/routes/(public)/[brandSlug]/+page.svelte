<script lang="ts">
	import type { PageData } from './$types';
	import { supabase } from '$lib/supabase/client';
	import { goto, invalidateAll } from '$app/navigation';
	import { page } from '$app/stores';
	import { Pin } from 'lucide-svelte';

	let { data } = $props<{ data: PageData }>();

	let following = $state(false);
	let followerCount = $state(0);

	$effect(() => {
		following = data.isFollowing;
		followerCount = data.brand.follower_count;
	});
	let loading = $state(false);
	let error = $state<string | null>(null);

	async function toggleFollow() {
		if (!data.session) {
			goto('/auth/login');
			return;
		}

		loading = true;
		error = null;

		if (following) {
			// Unfollow
			const { error: unfollowError } = await supabase
				.from('follows')
				.delete()
				.eq('follower_id', data.session.user.id)
				.eq('brand_id', data.brand.id);

			if (unfollowError) {
				error = 'Failed to unfollow. Please try again.';
				loading = false;
				return;
			}

			following = false;
			followerCount--;
		} else {
			// Follow
			const { error: followError } = await supabase.from('follows').insert({
				follower_id: data.session.user.id,
				brand_id: data.brand.id
			});

			if (followError) {
				error = 'Failed to follow. Please try again.';
				loading = false;
				return;
			}

			following = true;
			followerCount++;
		}

		loading = false;
		await invalidateAll();
	}

	// Content filtering
	const postTypes = ['all', 'article', 'promotion', 'news', 'update', 'tip'] as const;
	type PostType = typeof postTypes[number];

	const postTypeLabels: Record<PostType, string> = {
		all: 'All Posts',
		article: 'Articles',
		promotion: 'Promos',
		news: 'News',
		update: 'Updates',
		tip: 'Tips'
	};

	let selectedType = $state<PostType>('all');

	let filteredPosts = $derived(
		selectedType === 'all'
			? data.posts
			: data.posts.filter(p => p.post_type === selectedType)
	);
</script>

<div class="min-h-screen bg-base-100">
	<!-- Error Alert -->
	{#if error}
		<div class="container mx-auto px-4 max-w-[680px] pt-4">
			<div class="alert alert-error">
				<svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
				</svg>
				<span>{error}</span>
				<button class="btn btn-sm btn-ghost" onclick={() => error = null}>✕</button>
			</div>
		</div>
	{/if}

	<!-- Profile Container -->
	<div class="container mx-auto px-4 max-w-[680px]">
		<!-- Banner Image -->
		<div class="relative w-full h-[240px] mt-12 mb-0 overflow-hidden rounded-lg">
			{#if data.brand.banner_url}
				<img
					src={data.brand.banner_url}
					alt="{data.brand.brand_name} banner"
					class="w-full h-full object-cover"
				/>
			{:else}
				<div class="w-full h-full bg-gradient-to-r from-primary/10 to-secondary/10"></div>
			{/if}
		</div>

		<!-- Brand Info Section -->
		<div class="pb-8 border-b border-base-300/60 md:px-2">
			<!-- Avatar - overlapping banner on right side -->
			<div class="flex justify-end -mt-12 mb-0 mr-4">
				<div class="avatar">
					<div class="w-24 h-24 rounded-full ring-4 ring-base-100 bg-base-100">
						{#if data.brand.logo_url}
							<img src={data.brand.logo_url} alt={data.brand.brand_name} class="object-cover rounded-full" />
						{:else}
							<div class="w-full h-full bg-neutral text-neutral-content flex items-center justify-center rounded-full">
								<span class="text-4xl font-bold">{data.brand.brand_name[0]}</span>
							</div>
						{/if}
					</div>
				</div>
			</div>

			<!-- Brand Name and Subscribe Button -->
			<div class="flex items-start justify-between mb-5">
				<div class="flex-1 min-w-0">
					<h1 class="text-2xl font-bold mb-2 tracking-tight">{data.brand.brand_name}</h1>
					<p class="text-base opacity-50">@{data.brand.slug}</p>
				</div>

				<button
					class="btn {following ? 'btn-outline' : 'btn-primary'} btn-sm ml-4 flex-shrink-0"
					onclick={toggleFollow}
					disabled={loading}
				>
					{#if loading}
						<span class="loading loading-spinner loading-xs"></span>
					{:else}
						{following ? 'Following' : 'Subscribe'}
					{/if}
				</button>
			</div>

			<!-- Description -->
			{#if data.brand.description}
				<p class="text-lg leading-relaxed mb-6 opacity-80">{data.brand.description}</p>
			{/if}

			<!-- Social Links & Website -->
			{#if data.brand.website_url || data.brand.twitter_url || data.brand.facebook_url || data.brand.instagram_url || data.brand.linkedin_url || data.brand.youtube_url || data.brand.tiktok_url || data.brand.substack_url}
				<div class="flex flex-wrap items-center gap-2 mb-5">
					{#if data.brand.website_url}
						<a
							href={data.brand.website_url}
							target="_blank"
							rel="noopener noreferrer"
							class="badge badge-lg gap-1.5 bg-base-300 hover:bg-base-content hover:text-base-100 transition-all border-0"
						>
							<svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9" />
							</svg>
							<span class="text-xs font-medium">Website</span>
						</a>
					{/if}
					{#if data.brand.twitter_url}
						<a
							href={data.brand.twitter_url}
							target="_blank"
							rel="noopener noreferrer"
							class="badge badge-lg bg-base-300 hover:bg-base-content hover:text-base-100 transition-all border-0"
							title="X (Twitter)"
						>
							<svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="currentColor" viewBox="0 0 24 24">
								<path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
							</svg>
						</a>
					{/if}
					{#if data.brand.facebook_url}
						<a
							href={data.brand.facebook_url}
							target="_blank"
							rel="noopener noreferrer"
							class="badge badge-lg gap-1.5 bg-base-300 hover:bg-base-content hover:text-base-100 transition-all border-0"
						>
							<svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="currentColor" viewBox="0 0 24 24">
								<path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
							</svg>
							<span class="text-xs font-medium">Facebook</span>
						</a>
					{/if}
					{#if data.brand.instagram_url}
						<a
							href={data.brand.instagram_url}
							target="_blank"
							rel="noopener noreferrer"
							class="badge badge-lg gap-1.5 bg-base-300 hover:bg-base-content hover:text-base-100 transition-all border-0"
						>
							<svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="currentColor" viewBox="0 0 24 24">
								<path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/>
							</svg>
							<span class="text-xs font-medium">Instagram</span>
						</a>
					{/if}
					{#if data.brand.linkedin_url}
						<a
							href={data.brand.linkedin_url}
							target="_blank"
							rel="noopener noreferrer"
							class="badge badge-lg gap-1.5 bg-base-300 hover:bg-base-content hover:text-base-100 transition-all border-0"
						>
							<svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="currentColor" viewBox="0 0 24 24">
								<path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
							</svg>
							<span class="text-xs font-medium">LinkedIn</span>
						</a>
					{/if}
					{#if data.brand.youtube_url}
						<a
							href={data.brand.youtube_url}
							target="_blank"
							rel="noopener noreferrer"
							class="badge badge-lg gap-1.5 bg-base-300 hover:bg-base-content hover:text-base-100 transition-all border-0"
						>
							<svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="currentColor" viewBox="0 0 24 24">
								<path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
							</svg>
							<span class="text-xs font-medium">YouTube</span>
						</a>
					{/if}
					{#if data.brand.tiktok_url}
						<a
							href={data.brand.tiktok_url}
							target="_blank"
							rel="noopener noreferrer"
							class="badge badge-lg gap-1.5 bg-base-300 hover:bg-base-content hover:text-base-100 transition-all border-0"
						>
							<svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="currentColor" viewBox="0 0 24 24">
								<path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z"/>
							</svg>
							<span class="text-xs font-medium">TikTok</span>
						</a>
					{/if}
					{#if data.brand.substack_url}
						<a
							href={data.brand.substack_url}
							target="_blank"
							rel="noopener noreferrer"
							class="badge badge-lg gap-1.5 bg-base-300 hover:bg-base-content hover:text-base-100 transition-all border-0"
						>
							<svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="currentColor" viewBox="0 0 24 24">
								<path d="M22.539 8.242H1.46V5.406h21.08v2.836zM1.46 10.812V24L12 18.11 22.54 24V10.812H1.46zM22.54 0H1.46v2.836h21.08V0z"/>
							</svg>
							<span class="text-xs font-medium">Substack</span>
						</a>
					{/if}
				</div>
			{/if}

			<!-- Stats and Categories -->
			<div class="flex items-center gap-3 text-sm opacity-50 flex-wrap">
				<span><span class="font-semibold text-base-content opacity-100">{followerCount.toLocaleString()}</span> subscribers</span>
				{#if data.brand.categories && data.brand.categories.length > 0}
					<span>·</span>
					{#each data.brand.categories.slice(0, 2) as category}
						<span class="badge badge-sm badge-ghost opacity-70">{category}</span>
					{/each}
				{/if}
			</div>
		</div>

		<!-- Tabbed Navigation -->
		<!-- Content Type Filter Tabs -->
		<div class="border-b border-base-300/60 mb-10 mt-8 md:px-2">
			<div role="tablist" class="tabs tabs-bordered flex-wrap">
				{#each postTypes as type}
					<button
						role="tab"
						class="tab {selectedType === type ? 'tab-active' : ''}"
						onclick={() => selectedType = type}
					>
						{postTypeLabels[type]}
						{#if type === 'all'}
							({data.posts.length})
						{:else}
							({data.posts.filter(p => p.post_type === type).length})
						{/if}
					</button>
				{/each}
			</div>
		</div>

		<!-- Posts Section -->
		{#if filteredPosts && filteredPosts.length > 0}
			<div class="space-y-12 md:px-2">
				{#each filteredPosts as post}
					<article class="border-b border-base-300/50 pb-10 last:border-0">
						<!-- Pinned Badge -->
						{#if post.is_pinned}
							<div class="mb-3">
								<span class="badge badge-primary gap-1">
									<Pin class="h-3 w-3" />
									Pinned Post
								</span>
							</div>
						{/if}

						<!-- Post Preview (Substack style) -->
						<div class="grid grid-cols-1 md:grid-cols-[1fr_auto] gap-6 mb-4">
							<a href="/{data.brand.slug}/{post.slug}" class="block group">
								<h2 class="text-2xl font-bold mb-3 leading-tight group-hover:text-primary transition-colors">
									{post.title}
								</h2>
								{#if post.excerpt}
									<p class="text-base opacity-60 line-clamp-3 leading-relaxed">
										{post.excerpt}
									</p>
								{/if}
							</a>

							<!-- Thumbnail (if available) -->
							{#if post.cover_image_url}
								<div class="w-full md:w-40 h-40 flex-shrink-0">
									<a href="/{data.brand.slug}/{post.slug}" class="block h-full group">
										<img
											src={post.cover_image_url}
											alt={post.title}
											class="w-full h-full object-cover rounded-md group-hover:opacity-90 transition-opacity"
										/>
									</a>
								</div>
							{/if}
						</div>

						<!-- Post Meta -->
						<div class="flex items-center gap-3 text-sm opacity-50">
							<time datetime={post.published_at}>
								{new Date(post.published_at).toLocaleDateString('en-US', {
									month: 'short',
									day: 'numeric',
									year: 'numeric'
								})}
							</time>
							<span>·</span>
							<span>{post.like_count} likes</span>
							<span>·</span>
							<span>{post.comment_count} comments</span>
						</div>
					</article>
				{/each}
			</div>
		{:else}
			<div class="text-center py-24 md:px-2">
				<svg
					xmlns="http://www.w3.org/2000/svg"
					class="h-20 w-20 mx-auto mb-6 opacity-30"
					fill="none"
					viewBox="0 0 24 24"
					stroke="currentColor"
				>
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="1.5"
						d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z"
					/>
				</svg>
				<h3 class="text-2xl font-bold mb-2 opacity-70">
					{#if data.posts && data.posts.length > 0 && selectedType !== 'all'}
						No {postTypeLabels[selectedType].toLowerCase()} found
					{:else}
						No posts yet
					{/if}
				</h3>
				<p class="opacity-50 text-base">
					{#if data.posts && data.posts.length > 0 && selectedType !== 'all'}
						Try selecting a different content type.
					{:else}
						This brand hasn't published any posts yet. Check back soon!
					{/if}
				</p>
			</div>
		{/if}
	</div>
</div>
