<script lang="ts">
	import type { PageData } from './$types';
	import { TrendingUp, Heart, MessageCircle, Share2 } from 'lucide-svelte';
	import { CONTAINER_WIDTHS, SPACING, TYPOGRAPHY } from '$lib/ui-constants';

	let { data } = $props<{ data: PageData }>();

	const totalLikes = $derived(data.posts.reduce((sum, p) => sum + (p.like_count || 0), 0));
	const totalComments = $derived(data.posts.reduce((sum, p) => sum + (p.comment_count || 0), 0));
	const totalShares = $derived(data.posts.reduce((sum, p) => sum + (p.share_count || 0), 0));
	const totalEngagement = $derived(totalLikes + totalComments + totalShares);
	const avgEngagementPerPost = $derived(
		data.posts.length > 0 ? Math.round(totalEngagement / data.posts.length) : 0
	);

	const topPosts = $derived(
		[...data.posts]
			.sort((a, b) => {
				const aTotal = (a.like_count || 0) + (a.comment_count || 0) + (a.share_count || 0);
				const bTotal = (b.like_count || 0) + (b.comment_count || 0) + (b.share_count || 0);
				return bTotal - aTotal;
			})
			.slice(0, 5)
	);

	function groupFollowersByMonth() {
		if (!data.followersOverTime || data.followersOverTime.length === 0) return [];

		const grouped = new Map<string, number>();

		data.followersOverTime.forEach((f) => {
			const date = new Date(f.created_at);
			const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
			grouped.set(monthKey, (grouped.get(monthKey) || 0) + 1);
		});

		return Array.from(grouped.entries())
			.map(([month, count]) => ({ month, count }))
			.sort((a, b) => a.month.localeCompare(b.month));
	}

	const followerGrowth = $derived(groupFollowersByMonth());
</script>

<svelte:head>
	<title>Analytics | BetChat</title>
</svelte:head>

<div class="container mx-auto {SPACING.page.padding} {CONTAINER_WIDTHS.dashboard}">
	<div class="mb-8">
		<div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
			<div>
				<h1 class="{TYPOGRAPHY.pageTitle} mb-2">Analytics</h1>
				<p class="opacity-70">
					{#if data.brand}
						Performance insights for {data.brand.brand_name}
					{:else}
						Performance insights for your posts
					{/if}
				</p>
			</div>

			{#if data.brands && data.brands.length > 0}
				<div class="dropdown dropdown-end">
					<div role="button" tabindex="0" class="btn btn-outline gap-2">
						<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12M8 12h12m-12 5h12M4 7h.01M4 12h.01M4 17h.01" />
						</svg>
						{#if data.brand}
							{data.brand.brand_name}
						{:else}
							Personal
						{/if}
						<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
						</svg>
					</div>
					<ul class="dropdown-content z-[1] menu p-2 shadow-lg bg-base-200 rounded-box w-64 mt-2">
						<li>
							<a href="/dashboard/analytics" class="{!data.brand ? 'active' : ''}">
								Personal ({data.profile?.username})
							</a>
						</li>
						{#each data.brands as brand}
							<li>
								<a href="/dashboard/analytics?brand={brand.slug}" class="{data.brand?.id === brand.id ? 'active' : ''}">
									{brand.brand_name}
								</a>
							</li>
						{/each}
					</ul>
				</div>
			{/if}
		</div>
	</div>

	{#if data.posts.length === 0}
		<div class="bg-base-200 rounded-lg p-12 text-center">
			<TrendingUp class="h-16 w-16 mx-auto mb-4 opacity-50" />
			<h3 class="text-xl font-bold mb-2">No published posts yet</h3>
			<p class="opacity-70 mb-4">Publish your first post to start tracking analytics</p>
			<a href="/dashboard/posts/new{data.brand ? `?brand=${data.brand.slug}` : ''}" class="btn btn-primary">
				Create Post
			</a>
		</div>
	{:else}
		<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
			<div class="stat bg-base-200 rounded-lg">
				<div class="stat-figure text-primary">
					<Heart class="h-8 w-8" />
				</div>
				<div class="stat-title">Total Likes</div>
				<div class="stat-value text-primary">{totalLikes}</div>
			</div>

			<div class="stat bg-base-200 rounded-lg">
				<div class="stat-figure text-secondary">
					<MessageCircle class="h-8 w-8" />
				</div>
				<div class="stat-title">Total Comments</div>
				<div class="stat-value text-secondary">{totalComments}</div>
			</div>

			<div class="stat bg-base-200 rounded-lg">
				<div class="stat-figure text-accent">
					<Share2 class="h-8 w-8" />
				</div>
				<div class="stat-title">Total Shares</div>
				<div class="stat-value text-accent">{totalShares}</div>
			</div>

			<div class="stat bg-base-200 rounded-lg">
				<div class="stat-figure text-info">
					<TrendingUp class="h-8 w-8" />
				</div>
				<div class="stat-title">Avg Engagement</div>
				<div class="stat-value text-info">{avgEngagementPerPost}</div>
				<div class="stat-desc">per post</div>
			</div>
		</div>

		{#if data.brand && followerGrowth.length > 0}
			<div class="bg-base-200 rounded-lg p-6 mb-8">
				<h2 class="text-xl font-bold mb-4">Follower Growth</h2>
				<div class="overflow-x-auto">
					<table class="table w-full">
						<thead>
							<tr>
								<th>Month</th>
								<th>New Followers</th>
							</tr>
						</thead>
						<tbody>
							{#each followerGrowth as item}
								<tr>
									<td>{item.month}</td>
									<td class="font-semibold">{item.count}</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			</div>
		{/if}

		<div class="bg-base-200 rounded-lg p-6">
			<h2 class="text-xl font-bold mb-4">Top Performing Posts</h2>
			{#if topPosts.length > 0}
				<div class="overflow-x-auto">
					<table class="table w-full">
						<thead>
							<tr>
								<th>Title</th>
								<th>Published</th>
								<th>Likes</th>
								<th>Comments</th>
								<th>Shares</th>
								<th>Total</th>
							</tr>
						</thead>
						<tbody>
							{#each topPosts as post}
								<tr class="hover">
									<td>
										<a
											href={data.brand ? `/${data.brand.slug}/${post.slug}` : `/u/${data.profile?.username}/${post.slug}`}
											class="font-semibold hover:underline"
											target="_blank"
										>
											{post.title}
										</a>
									</td>
									<td>
										{new Date(post.published_at).toLocaleDateString()}
									</td>
									<td>{post.like_count || 0}</td>
									<td>{post.comment_count || 0}</td>
									<td>{post.share_count || 0}</td>
									<td class="font-bold">
										{(post.like_count || 0) + (post.comment_count || 0) + (post.share_count || 0)}
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			{/if}
		</div>
	{/if}
</div>
