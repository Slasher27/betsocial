<script lang="ts">
	import type { PageData } from './$types';
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { enhance } from '$app/forms';
	import { invalidateAll } from '$app/navigation';
	import { Pin, PinOff, TrendingUp } from 'lucide-svelte';
	import { CONTAINER_WIDTHS, SPACING, TYPOGRAPHY, BUTTON, SHADOW, BADGE } from '$lib/ui-constants';

	let { data } = $props<{ data: PageData }>();

	let showSuccess = $state(false);
	let successMessage = $state('');
	let pinningPostId = $state<string | null>(null);

	onMount(() => {
		const success = $page.url.searchParams.get('success');
		if (success) {
			successMessage = success;
			showSuccess = true;
			// Hide after 5 seconds
			setTimeout(() => {
				showSuccess = false;
			}, 5000);
		}
	});

	const statusColors: Record<string, string> = {
		published: 'badge-success',
		draft: 'badge-warning',
		archived: 'badge-error'
	};

	function isEdited(post: any): boolean {
		// Check if updated_at is significantly different from created_at (more than 1 second)
		const created = new Date(post.created_at).getTime();
		const updated = new Date(post.updated_at).getTime();
		return updated - created > 1000;
	}
</script>

<svelte:head>
	<title>Brand Dashboard | BetChat</title>
</svelte:head>

<div class="container mx-auto {SPACING.page.padding} {CONTAINER_WIDTHS.dashboard}">
	<!-- Success Message -->
	{#if showSuccess}
		<div class="alert alert-success mb-6">
			<svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
			</svg>
			<span>{successMessage}</span>
		</div>
	{/if}

	<!-- Dashboard Header with Brand Switcher -->
	<div class="mb-8">
		<div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-4">
			<h1 class="{TYPOGRAPHY.pageTitle}">
				{#if data.brand}
					Brand Dashboard
				{:else}
					My Dashboard
				{/if}
			</h1>

			<!-- Brand/Profile Switcher -->
			{#if data.brands && data.brands.length > 0}
				<div class="dropdown dropdown-end">
					<div role="button" tabindex="0" class="btn btn-outline gap-2">
						<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12M8 12h12m-12 5h12M4 7h.01M4 12h.01M4 17h.01" />
						</svg>
						{#if data.brand}
							{data.brand.brand_name}
						{:else}
							{data.profile?.display_name || data.profile?.username || 'Personal'}
						{/if}
						<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
						</svg>
					</div>
					<ul tabindex="0" class="dropdown-content z-[1] menu p-2 shadow-lg bg-base-200 rounded-box w-64 mt-2">
						<li class="menu-title">
							<span>Switch Context</span>
						</li>
						<li>
							<a href="/dashboard" class="{!data.brand ? 'active' : ''}">
								<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
								</svg>
								Personal ({data.profile?.username})
							</a>
						</li>
						<li class="menu-title">
							<span>Your Brands</span>
						</li>
						{#each data.brands as brand}
							<li>
								<a href="/dashboard?brand={brand.slug}" class="{data.brand?.id === brand.id ? 'active' : ''}">
									<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
									</svg>
									{brand.brand_name}
								</a>
							</li>
						{/each}
					</ul>
				</div>
			{/if}
		</div>

		{#if data.brand}
			<p class="text-lg opacity-70">Welcome back, {data.brand.brand_name}!</p>
		{:else if data.profile}
			<p class="text-lg opacity-70">Welcome back, {data.profile.display_name || data.profile.username}!</p>
		{/if}
	</div>

	<!-- Stats Overview -->
	<div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
		{#if data.brand}
			<div class="stat bg-base-200 rounded-lg">
				<div class="stat-title">Total Followers</div>
				<div class="stat-value text-primary">{data.brand.follower_count}</div>
			</div>
		{/if}

		<div class="stat bg-base-200 rounded-lg">
			<div class="stat-title">Total Posts</div>
			<div class="stat-value">{data.posts.length}</div>
		</div>

		<div class="stat bg-base-200 rounded-lg">
			<div class="stat-title">Published</div>
			<div class="stat-value text-success">
				{data.posts.filter((p: any) => p.status === 'published').length}
			</div>
		</div>

		<div class="stat bg-base-200 rounded-lg">
			<div class="stat-title">Drafts</div>
			<div class="stat-value text-warning">
				{data.posts.filter((p: any) => p.status === 'draft').length}
			</div>
		</div>
	</div>

	<!-- Quick Actions -->
	<div class="flex flex-wrap gap-2 sm:gap-4 mb-8">
		<a href="/dashboard/posts/new{data.brand ? `?brand=${data.brand.slug}` : ''}" class="btn btn-primary btn-sm sm:btn-md">
			<svg
				xmlns="http://www.w3.org/2000/svg"
				class="h-4 w-4 sm:h-5 sm:w-5"
				fill="none"
				viewBox="0 0 24 24"
				stroke="currentColor"
			>
				<path
					stroke-linecap="round"
					stroke-linejoin="round"
					stroke-width="2"
					d="M12 4v16m8-8H4"
				/>
			</svg>
			<span class="hidden sm:inline">New Post</span>
			<span class="sm:hidden">New</span>
		</a>
		<a href="/dashboard/analytics{data.brand ? `?brand=${data.brand.slug}` : ''}" class="btn btn-outline btn-sm sm:btn-md">
			<TrendingUp class="h-4 w-4 sm:h-5 sm:w-5" />
			Analytics
		</a>
		<a href="/settings{data.brand ? `?brand=${data.brand.slug}` : ''}" class="btn btn-outline btn-sm sm:btn-md">
			<svg
				xmlns="http://www.w3.org/2000/svg"
				class="h-4 w-4 sm:h-5 sm:w-5"
				fill="none"
				viewBox="0 0 24 24"
				stroke="currentColor"
			>
				<path
					stroke-linecap="round"
					stroke-linejoin="round"
					stroke-width="2"
					d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
				/>
				<path
					stroke-linecap="round"
					stroke-linejoin="round"
					stroke-width="2"
					d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
				/>
			</svg>
			Settings
		</a>
		{#if data.brand}
			<a href="/{data.brand.slug}" class="btn btn-ghost btn-sm sm:btn-md">
				<svg
					xmlns="http://www.w3.org/2000/svg"
					class="h-4 w-4 sm:h-5 sm:w-5"
					fill="none"
					viewBox="0 0 24 24"
					stroke="currentColor"
				>
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
					/>
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
					/>
				</svg>
				<span class="hidden sm:inline">View Public Page</span>
				<span class="sm:hidden">View</span>
			</a>
		{:else if data.profile}
			<a href="/u/{data.profile.username}" class="btn btn-ghost btn-sm sm:btn-md">
				<svg
					xmlns="http://www.w3.org/2000/svg"
					class="h-4 w-4 sm:h-5 sm:w-5"
					fill="none"
					viewBox="0 0 24 24"
					stroke="currentColor"
				>
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
					/>
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
					/>
				</svg>
				<span class="hidden sm:inline">View Public Profile</span>
				<span class="sm:hidden">View</span>
			</a>
		{/if}
	</div>

	<!-- Posts Table -->
	<div class="bg-base-200 rounded-lg p-6">
		<h2 class="text-2xl font-bold mb-4">Your Posts</h2>

		{#if data.posts.length > 0}
			<div class="overflow-x-auto">
				<table class="table w-full">
					<thead>
						<tr>
							<th>Title</th>
							<th>Status</th>
							<th>Published</th>
							<th>Last Updated</th>
							<th>Engagement</th>
							<th>Actions</th>
						</tr>
					</thead>
					<tbody>
						{#each data.posts as post}
							<tr class="hover">
								<td>
									<div class="flex flex-col">
										<span class="font-semibold">{post.title}</span>
										{#if post.excerpt}
											<span class="text-sm opacity-70 line-clamp-1">{post.excerpt}</span>
										{/if}
									</div>
								</td>
								<td>
									<div class="flex items-center gap-2">
										<span class="badge badge-sm {statusColors[post.status]}">{post.status.charAt(0).toUpperCase() + post.status.slice(1)}</span>
										{#if isEdited(post)}
											<span class="badge badge-sm badge-info">Updated</span>
										{/if}
									</div>
								</td>
								<td>
									{#if post.published_at}
										{new Date(post.published_at).toLocaleDateString()}
									{:else}
										-
									{/if}
								</td>
								<td>
									{#if isEdited(post)}
										<div class="flex flex-col">
											<span class="text-sm">{new Date(post.updated_at).toLocaleDateString()}</span>
											<span class="text-xs opacity-60">
												{new Date(post.updated_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
											</span>
										</div>
									{:else}
										-
									{/if}
								</td>
								<td>
									<div class="flex gap-3 text-sm">
										<span>{post.like_count} likes</span>
										<span>{post.comment_count} comments</span>
									</div>
								</td>
								<td>
									<div class="flex gap-2">
										<!-- Pin/Unpin Button -->
										{#if post.status === 'published'}
											<form method="POST" action="?/togglePin" use:enhance={() => {
												pinningPostId = post.id;
												return async ({ update }) => {
													await update();
													await invalidateAll();
													pinningPostId = null;
												};
											}}>
												<input type="hidden" name="postId" value={post.id} />
												<input type="hidden" name="isPinned" value={post.is_pinned} />
												<button
													type="submit"
													class="btn btn-sm btn-ghost"
													title={post.is_pinned ? 'Unpin post' : 'Pin to top'}
													disabled={pinningPostId === post.id}
													aria-label={post.is_pinned ? 'Unpin post' : 'Pin post to top'}
												>
													{#if pinningPostId === post.id}
														<span class="loading loading-spinner loading-xs"></span>
													{:else if post.is_pinned}
														<Pin class="h-4 w-4 text-primary" fill="currentColor" />
													{:else}
														<PinOff class="h-4 w-4" />
													{/if}
												</button>
											</form>
										{/if}

										<a href="/dashboard/posts/{post.id}/edit{data.brand ? `?brand=${data.brand.slug}` : ''}" class="btn btn-sm btn-ghost">
											Edit
										</a>
										{#if post.status === 'published'}
											{#if data.brand}
												<a
													href="/{data.brand.slug}/{post.slug}"
													class="btn btn-sm btn-ghost"
													target="_blank"
												>
													View
												</a>
											{:else if data.profile}
												<a
													href="/u/{data.profile.username}/{post.slug}"
													class="btn btn-sm btn-ghost"
													target="_blank"
												>
													View
												</a>
											{/if}
										{/if}
									</div>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		{:else}
			<div class="text-center py-12">
				<svg
					xmlns="http://www.w3.org/2000/svg"
					class="h-16 w-16 mx-auto mb-4 opacity-50"
					fill="none"
					viewBox="0 0 24 24"
					stroke="currentColor"
				>
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
					/>
				</svg>
				<h3 class="text-xl font-bold mb-2">No posts yet</h3>
				<p class="opacity-70 mb-4">Create your first post to start engaging with your followers!</p>
				<a href="/dashboard/posts/new" class="btn btn-primary">Create Your First Post</a>
			</div>
		{/if}
	</div>
</div>
