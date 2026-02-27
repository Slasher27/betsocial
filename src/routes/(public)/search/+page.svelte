<script lang="ts">
	import type { PageData } from './$types';
	import { goto } from '$app/navigation';

	let { data } = $props<{ data: PageData }>();

	function formatDate(dateString: string) {
		const date = new Date(dateString);
		return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
	}

	function highlightText(text: string, query: string) {
		if (!query.trim() || !text) return text;
		const regex = new RegExp(`(${query.split(' ').join('|')})`, 'gi');
		return text.replace(regex, '<mark class="bg-yellow-400 text-black px-1">$1</mark>');
	}

	function changeFilter(newFilter: string) {
		const url = new URL(window.location.href);
		url.searchParams.set('filter', newFilter);
		goto(url.pathname + url.search, { replaceState: true });
	}
</script>

<svelte:head>
	<title>Search: {data.query || 'BetChat'}</title>
</svelte:head>

<div class="container mx-auto px-4 py-8 max-w-4xl">
	<!-- Search Header -->
	<div class="mb-8">
		<h1 class="text-3xl font-bold mb-2">Search Results</h1>
		{#if data.query}
			<p class="text-lg opacity-80">
				Found <span class="font-semibold">{data.totalResults}</span> results for
				<span class="font-semibold">"{data.query}"</span>
			</p>
		{:else}
			<p class="text-lg opacity-80">Enter a search query to find posts, brands, and users</p>
		{/if}
	</div>

	{#if data.query}
		<!-- Filter Tabs -->
		<div class="tabs tabs-boxed mb-6 bg-base-200">
			<button
				class="tab {data.filter === 'all' ? 'tab-active' : ''}"
				onclick={() => changeFilter('all')}
			>
				All ({data.posts.length + data.brands.length + data.users.length})
			</button>
			<button
				class="tab {data.filter === 'posts' ? 'tab-active' : ''}"
				onclick={() => changeFilter('posts')}
			>
				Posts ({data.posts.length})
			</button>
			<button
				class="tab {data.filter === 'brands' ? 'tab-active' : ''}"
				onclick={() => changeFilter('brands')}
			>
				Brands ({data.brands.length})
			</button>
			<button
				class="tab {data.filter === 'users' ? 'tab-active' : ''}"
				onclick={() => changeFilter('users')}
			>
				Users ({data.users.length})
			</button>
		</div>

		<!-- Results -->
		<div class="space-y-8">
			<!-- Posts Section -->
			{#if (data.filter === 'all' || data.filter === 'posts') && data.posts.length > 0}
				<section>
					{#if data.filter === 'all'}
						<h2 class="text-2xl font-bold mb-4">Posts</h2>
					{/if}
					<div class="space-y-4">
						{#each data.posts as post}
							{@const postUrl = post.brand_id
								? `/${post.brand.slug}/${post.slug}`
								: `/u/${post.author.username}/${post.slug}`}
							<a
								href={postUrl}
								class="block bg-base-200 hover:bg-base-300 rounded-lg p-4 transition-colors"
							>
								<div class="flex items-start gap-3">
									<!-- Author/Brand Avatar -->
									<div class="avatar">
										<div class="w-12 h-12 rounded-full">
											{#if post.brand_id && post.brand?.logo_url}
												<img src={post.brand.logo_url} alt={post.brand.brand_name} />
											{:else if post.author?.avatar_url}
												<img src={post.author.avatar_url} alt={post.author.username} />
											{:else}
												<div class="bg-neutral text-neutral-content flex items-center justify-center w-full h-full">
													<span class="text-lg font-semibold">
														{post.brand_id ? post.brand?.brand_name?.[0] : post.author?.username?.[0]?.toUpperCase()}
													</span>
												</div>
											{/if}
										</div>
									</div>

									<!-- Post Content -->
									<div class="flex-1 min-w-0">
										<h3 class="text-xl font-bold mb-1">
											{@html highlightText(post.title, data.query)}
										</h3>
										<div class="flex items-center gap-2 text-sm opacity-70 mb-2">
											<span>
												{post.brand_id ? post.brand?.brand_name : post.author?.display_name || post.author?.username}
											</span>
											<span>•</span>
											<time datetime={post.published_at}>
												{formatDate(post.published_at)}
											</time>
										</div>
										{#if post.excerpt}
											<p class="opacity-80 line-clamp-2">
												{@html highlightText(post.excerpt, data.query)}
											</p>
										{/if}
									</div>
								</div>
							</a>
						{/each}
					</div>
				</section>
			{/if}

			<!-- Brands Section -->
			{#if (data.filter === 'all' || data.filter === 'brands') && data.brands.length > 0}
				<section>
					{#if data.filter === 'all'}
						<h2 class="text-2xl font-bold mb-4">Brands</h2>
					{/if}
					<div class="grid md:grid-cols-2 gap-4">
						{#each data.brands as brand}
							<a
								href="/{brand.slug}"
								class="block bg-base-200 hover:bg-base-300 rounded-lg p-4 transition-colors"
							>
								<div class="flex items-start gap-3">
									<div class="avatar">
										<div class="w-16 h-16 rounded-lg">
											{#if brand.logo_url}
												<img src={brand.logo_url} alt={brand.brand_name} />
											{:else}
												<div class="bg-neutral text-neutral-content flex items-center justify-center w-full h-full">
													<span class="text-2xl font-semibold">{brand.brand_name[0]}</span>
												</div>
											{/if}
										</div>
									</div>
									<div class="flex-1 min-w-0">
										<h3 class="text-lg font-bold mb-1">
											{@html highlightText(brand.brand_name, data.query)}
										</h3>
										<p class="text-sm opacity-70 mb-2">
											{brand.follower_count} followers
										</p>
										{#if brand.description}
											<p class="text-sm opacity-80 line-clamp-2">
												{@html highlightText(brand.description, data.query)}
											</p>
										{/if}
									</div>
								</div>
							</a>
						{/each}
					</div>
				</section>
			{/if}

			<!-- Users Section -->
			{#if (data.filter === 'all' || data.filter === 'users') && data.users.length > 0}
				<section>
					{#if data.filter === 'all'}
						<h2 class="text-2xl font-bold mb-4">Users</h2>
					{/if}
					<div class="grid md:grid-cols-2 gap-4">
						{#each data.users as user}
							<a
								href="/u/{user.username}"
								class="block bg-base-200 hover:bg-base-300 rounded-lg p-4 transition-colors"
							>
								<div class="flex items-start gap-3">
									<div class="avatar">
										<div class="w-12 h-12 rounded-full">
											{#if user.avatar_url}
												<img src={user.avatar_url} alt={user.username} />
											{:else}
												<div class="bg-neutral text-neutral-content flex items-center justify-center w-full h-full">
													<span class="text-lg font-semibold">
														{user.username[0]?.toUpperCase()}
													</span>
												</div>
											{/if}
										</div>
									</div>
									<div class="flex-1 min-w-0">
										<h3 class="font-bold">
											{@html highlightText(user.display_name || user.username, data.query)}
										</h3>
										<p class="text-sm opacity-70">@{user.username}</p>
										{#if user.bio}
											<p class="text-sm opacity-80 mt-1 line-clamp-2">
												{@html highlightText(user.bio, data.query)}
											</p>
										{/if}
									</div>
								</div>
							</a>
						{/each}
					</div>
				</section>
			{/if}

			<!-- No Results -->
			{#if data.totalResults === 0}
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
							d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
						/>
					</svg>
					<p class="text-xl opacity-70 mb-2">No results found</p>
					<p class="opacity-60">Try different keywords or check your spelling</p>
				</div>
			{/if}
		</div>
	{:else}
		<!-- Empty State -->
		<div class="text-center py-16">
			<svg
				xmlns="http://www.w3.org/2000/svg"
				class="h-20 w-20 mx-auto mb-4 opacity-50"
				fill="none"
				viewBox="0 0 24 24"
				stroke="currentColor"
			>
				<path
					stroke-linecap="round"
					stroke-linejoin="round"
					stroke-width="2"
					d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
				/>
			</svg>
			<p class="text-xl opacity-70">Start searching for posts, brands, and users</p>
		</div>
	{/if}
</div>
