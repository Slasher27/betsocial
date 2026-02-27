<script lang="ts">
	import type { PageData } from './$types';
	import { TrendingUp, Users, Flame } from 'lucide-svelte';

	let { data } = $props<{ data: PageData }>();

	const categories = [
		'All',
		'Sports Betting',
		'Online Casino',
		'Poker',
		'Esports',
		'Horse Racing',
		'Fantasy Sports',
		'Crypto Gambling',
		'Other'
	];

	let selectedCategory = $state('All');
	let activeTab = $state<'trending' | 'brands' | 'leaderboard'>('trending');

	let filteredBrands = $derived(
		selectedCategory === 'All'
			? data.brands
			: data.brands.filter((b: any) => b.categories && b.categories.includes(selectedCategory))
	);

	function formatTimeAgo(dateString: string) {
		const date = new Date(dateString);
		const now = new Date();
		const days = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24));

		if (days === 0) return 'Today';
		if (days === 1) return 'Yesterday';
		if (days < 7) return `${days}d ago`;
		return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
	}
</script>

<div class="container mx-auto px-4 py-8 max-w-7xl">
	<!-- Header -->
	<div class="mb-8">
		<h1 class="text-3xl font-bold mb-2">Explore</h1>
		<p class="text-lg opacity-80">Discover trending posts, brands, and top content</p>
	</div>

	<!-- Main Tabs -->
	<div class="tabs tabs-boxed mb-8 bg-base-200 p-1">
		<button
			class="tab {activeTab === 'trending' ? 'tab-active' : ''}"
			onclick={() => activeTab = 'trending'}
		>
			<TrendingUp class="h-4 w-4 mr-2" />
			Trending Posts
		</button>
		<button
			class="tab {activeTab === 'brands' ? 'tab-active' : ''}"
			onclick={() => activeTab = 'brands'}
		>
			<Flame class="h-4 w-4 mr-2" />
			Browse Brands
		</button>
		<button
			class="tab {activeTab === 'leaderboard' ? 'tab-active' : ''}"
			onclick={() => activeTab = 'leaderboard'}
		>
			<Users class="h-4 w-4 mr-2" />
			Leaderboard
		</button>
	</div>

	<!-- Trending Posts Tab -->
	{#if activeTab === 'trending'}
		<div class="space-y-6">
			<h2 class="text-2xl font-bold">🔥 Trending This Week</h2>

			{#if data.trendingPosts && data.trendingPosts.length > 0}
				<div class="grid gap-6">
					{#each data.trendingPosts as post, index}
						{@const postUrl = post.brand_id
							? `/${post.brand.slug}/${post.slug}`
							: `/u/${post.author.username}/${post.slug}`}
						<div class="card bg-base-200 hover:bg-base-300 transition-colors">
							<div class="card-body">
								<div class="flex gap-4">
									<!-- Rank Badge -->
									<div class="flex-shrink-0">
										<div class="badge badge-lg {index < 3 ? 'badge-primary' : 'badge-outline'}">
											#{index + 1}
										</div>
									</div>

									<!-- Post Content -->
									<div class="flex-1 min-w-0">
										<a href={postUrl} class="block group">
											<h3 class="text-xl font-bold mb-2 group-hover:text-primary transition-colors">
												{post.title}
											</h3>
											{#if post.excerpt}
												<p class="text-sm opacity-70 line-clamp-2 mb-3">
													{post.excerpt}
												</p>
											{/if}
										</a>

										<!-- Author/Brand Info -->
										<div class="flex items-center gap-2 text-sm opacity-70 mb-2">
											<div class="avatar">
												<div class="w-6 h-6 rounded-full">
													{#if post.brand_id && post.brand?.logo_url}
														<img src={post.brand.logo_url} alt={post.brand.brand_name} />
													{:else if post.author?.avatar_url}
														<img src={post.author.avatar_url} alt={post.author.username} />
													{:else}
														<div class="bg-neutral text-neutral-content flex items-center justify-center w-full h-full text-xs">
															{post.brand_id ? post.brand?.brand_name?.[0] : post.author?.username?.[0]?.toUpperCase()}
														</div>
													{/if}
												</div>
											</div>
											<span>
												{post.brand_id ? post.brand?.brand_name : post.author?.display_name || post.author?.username}
											</span>
											<span>•</span>
											<span>{formatTimeAgo(post.published_at)}</span>
										</div>

										<!-- Engagement Stats -->
										<div class="flex gap-4 text-sm">
											<span class="flex items-center gap-1">
												<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
													<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
												</svg>
												{post.like_count}
											</span>
											<span class="flex items-center gap-1">
												<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
													<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
												</svg>
												{post.comment_count}
											</span>
										</div>
									</div>

									<!-- Cover Image -->
									{#if post.cover_image_url}
										<div class="flex-shrink-0 w-32 h-32">
											<a href={postUrl}>
												<img
													src={post.cover_image_url}
													alt={post.title}
													class="w-full h-full object-cover rounded-lg"
												/>
											</a>
										</div>
									{/if}
								</div>
							</div>
						</div>
					{/each}
				</div>
			{:else}
				<div class="text-center py-16">
					<TrendingUp class="h-16 w-16 mx-auto mb-4 opacity-50" />
					<p class="text-xl opacity-70">No trending posts this week</p>
					<p class="text-sm opacity-60 mt-2">Check back soon for hot content!</p>
				</div>
			{/if}
		</div>
	{/if}

	<!-- Browse Brands Tab -->
	{#if activeTab === 'brands'}
		<div>
			<h2 class="text-2xl font-bold mb-6">Browse by Category</h2>

			<!-- Category Filter -->
			<div class="flex gap-2 mb-8 overflow-x-auto pb-2">
				{#each categories as category}
					<button
						class="btn btn-sm {selectedCategory === category ? 'btn-primary' : 'btn-outline'}"
						onclick={() => (selectedCategory = category)}
					>
						{category}
					</button>
				{/each}
			</div>

			<!-- Brands Grid -->
			{#if filteredBrands && filteredBrands.length > 0}
				<div class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
					{#each filteredBrands as brand}
						<div class="card bg-base-200 shadow-lg hover:shadow-xl transition-shadow">
							<div class="card-body">
								<div class="flex items-start gap-4">
									<div class="avatar placeholder">
										<div class="bg-neutral text-neutral-content rounded-lg w-16 h-16">
											{#if brand.logo_url}
												<img src={brand.logo_url} alt={brand.brand_name} />
											{:else}
												<span class="text-2xl">{brand.brand_name[0]}</span>
											{/if}
										</div>
									</div>
									<div class="flex-1">
										<h2 class="card-title text-lg">
											<a href="/{brand.slug}" class="hover:text-primary">
												{brand.brand_name}
											</a>
										</h2>
										{#if brand.categories && brand.categories.length > 0}
											<span class="badge badge-sm badge-outline">{brand.categories[0]}</span>
										{/if}
									</div>
								</div>

								{#if brand.description}
									<p class="text-sm opacity-80 mt-2 line-clamp-2">{brand.description}</p>
								{/if}

								<div class="flex items-center justify-between mt-4">
									<span class="text-sm opacity-70">{brand.follower_count} followers</span>
									<a href="/{brand.slug}" class="btn btn-primary btn-sm">View</a>
								</div>
							</div>
						</div>
					{/each}
				</div>
			{:else}
				<div class="text-center py-16">
					<p class="text-xl opacity-70">No brands found in this category</p>
				</div>
			{/if}
		</div>
	{/if}

	<!-- Leaderboard Tab -->
	{#if activeTab === 'leaderboard'}
		<div class="space-y-6">
			<h2 class="text-2xl font-bold">🏆 Top Brands</h2>

			{#if data.topBrandsByFollowers && data.topBrandsByFollowers.length > 0}
				<div class="overflow-x-auto">
					<table class="table w-full">
						<thead>
							<tr>
								<th class="w-16">Rank</th>
								<th>Brand</th>
								<th>Followers</th>
								<th></th>
							</tr>
						</thead>
						<tbody>
							{#each data.topBrandsByFollowers as brand, index}
								<tr class="hover">
									<td>
										<div class="badge {index < 3 ? 'badge-primary' : 'badge-outline'} badge-lg">
											#{index + 1}
										</div>
									</td>
									<td>
										<div class="flex items-center gap-3">
											<div class="avatar">
												<div class="w-12 h-12 rounded-lg">
													{#if brand.logo_url}
														<img src={brand.logo_url} alt={brand.brand_name} />
													{:else}
														<div class="bg-neutral text-neutral-content flex items-center justify-center w-full h-full">
															<span class="font-semibold">{brand.brand_name[0]}</span>
														</div>
													{/if}
												</div>
											</div>
											<div>
												<div class="font-bold">{brand.brand_name}</div>
												{#if brand.description}
													<div class="text-sm opacity-70 line-clamp-1">{brand.description}</div>
												{/if}
											</div>
										</div>
									</td>
									<td>
										<span class="font-semibold">{brand.follower_count.toLocaleString()}</span>
									</td>
									<td>
										<a href="/{brand.slug}" class="btn btn-ghost btn-sm">View</a>
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			{:else}
				<div class="text-center py-16">
					<Users class="h-16 w-16 mx-auto mb-4 opacity-50" />
					<p class="text-xl opacity-70">No brands to show yet</p>
				</div>
			{/if}
		</div>
	{/if}
</div>
