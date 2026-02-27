<script lang="ts">
	import type { PageData } from './$types';
	import PulseInput from '$lib/components/PulseInput.svelte';
	import PulsePost from '$lib/components/PulsePost.svelte';
	import PulseSkeleton from '$lib/components/skeletons/PulseSkeleton.svelte';
	import PostSkeleton from '$lib/components/skeletons/PostSkeleton.svelte';
	import { supabase } from '$lib/supabase/client';
	import { CONTAINER_WIDTHS, SPACING, TYPOGRAPHY } from '$lib/ui-constants';

	let { data } = $props<{ data: PageData }>();

	let loading = $state(false);

	// Reactive set of bookmarked post IDs for instant UI feedback
	let bookmarkedIds = $state(new Set<string>());

	$effect(() => {
		bookmarkedIds = new Set<string>(data.bookmarkedPostIds ?? []);
	});
	let bookmarkLoading = $state(new Set<string>());

	async function toggleBookmark(postId: string) {
		if (!data.session) return;

		bookmarkLoading = new Set([...bookmarkLoading, postId]);

		if (bookmarkedIds.has(postId)) {
			const { error } = await supabase
				.from('bookmarks')
				.delete()
				.eq('user_id', data.session.user.id)
				.eq('post_id', postId);

			if (!error) {
				bookmarkedIds = new Set([...bookmarkedIds].filter((id) => id !== postId));
			}
		} else {
			const { error } = await supabase
				.from('bookmarks')
				.insert({ user_id: data.session.user.id, post_id: postId });

			if (!error) {
				bookmarkedIds = new Set([...bookmarkedIds, postId]);
			}
		}

		bookmarkLoading = new Set([...bookmarkLoading].filter((id) => id !== postId));
	}

	function formatDate(dateString: string) {
		const date = new Date(dateString);
		return date.toLocaleDateString('en-US', {
			month: 'short',
			day: 'numeric',
			year: 'numeric'
		});
	}

	function getReadTime(excerpt: string | null) {
		// Rough estimate: 200 words per minute
		if (!excerpt) return '5 min read';
		const words = excerpt.split(' ').length;
		const minutes = Math.ceil(words / 200);
		return `${minutes} min read`;
	}
</script>

<div class="min-h-screen bg-base-100">
	<div class="container mx-auto {SPACING.page.padding} {CONTAINER_WIDTHS.content}">
		<!-- Pulse Input -->
		{#if data.profile}
			<div class="mb-6">
				<PulseInput
					userId={data.profile.id}
					userAvatar={data.brand ? data.brand.logo_url : data.profile.avatar_url}
					username={data.brand ? data.brand.brand_name : data.profile.username}
					brandId={data.brand?.id}
				/>
			</div>
		{/if}

		<!-- Pulse Posts Feed -->
		{#if loading}
			<div class="mb-8">
				<h2 class="text-lg font-semibold mb-4 px-2">Recent Pulse</h2>
				<div class="space-y-4">
					{#each Array(3) as _, i}
						<PulseSkeleton />
					{/each}
				</div>
			</div>
		{:else if data.pulsePosts && data.pulsePosts.length > 0}
			<div class="mb-8">
				<h2 class="text-lg font-semibold mb-4 px-2">Recent Pulse</h2>
				<div class="space-y-4">
					{#each data.pulsePosts as pulse}
						<PulsePost
							pulse={pulse}
							currentUserId={data.session?.user.id}
							currentBrandId={data.brand?.id}
						/>
					{/each}
				</div>
			</div>
		{/if}

		<!-- Long-form Posts -->
		<h2 class="text-lg font-semibold mb-4 px-2">Articles & Posts</h2>
		{#if loading}
			<div class="space-y-8">
				{#each Array(5) as _, i}
					<PostSkeleton />
				{/each}
			</div>
		{:else if data.posts && data.posts.length > 0}
			<div class="space-y-8">
				{#each data.posts as post}
					<article class="border-b border-base-300 pb-8 last:border-0">
						<!-- Top Row: Author/Brand + Date -->
						<div class="flex items-center justify-between mb-3">
							<div class="flex items-center gap-2">
								<div class="avatar">
									<div class="w-6 h-6 rounded-full">
										{#if post.brand}
											{#if post.brand.logo_url}
												<img src={post.brand.logo_url} alt={post.brand.brand_name} class="object-cover" />
											{:else}
												<div class="w-full h-full bg-neutral text-neutral-content flex items-center justify-center">
													<span class="text-xs font-semibold">{post.brand.brand_name[0]}</span>
												</div>
											{/if}
										{:else if post.author}
											{#if post.author.avatar_url}
												<img src={post.author.avatar_url} alt={post.author.username} class="object-cover" />
											{:else}
												<div class="w-full h-full bg-neutral text-neutral-content flex items-center justify-center">
													<span class="text-xs font-semibold">{post.author.username[0].toUpperCase()}</span>
												</div>
											{/if}
										{/if}
									</div>
								</div>
								<div class="text-sm font-medium">
									{#if post.brand}
										<a href="/{post.brand.slug}" class="hover:underline">
											{post.brand.brand_name}
										</a>
									{:else if post.author}
										<a href="/u/{post.author.username}" class="hover:underline">
											{post.author.display_name || post.author.username}
										</a>
									{/if}
								</div>
							</div>
							<time datetime={post.published_at} class="text-sm opacity-60">
								{formatDate(post.published_at)}
							</time>
						</div>

						<!-- Middle Row: Content + Thumbnail -->
						<div class="grid grid-cols-1 md:grid-cols-[1fr_auto] gap-4 mb-3">
							{#if post.brand}
								<a href="/{post.brand.slug}/{post.slug}{data.brand ? `?brand=${data.brand.slug}` : ''}" class="block group">
									<h2 class="text-xl font-bold mb-2 leading-snug group-hover:opacity-80 transition-opacity">
										{post.title}
									</h2>
									{#if post.excerpt}
										<p class="text-base opacity-70 line-clamp-2 leading-relaxed">
											{post.excerpt}
										</p>
									{/if}
								</a>
							{:else if post.author}
								<a href="/u/{post.author.username}/{post.slug}{data.brand ? `?brand=${data.brand.slug}` : ''}" class="block group">
									<h2 class="text-xl font-bold mb-2 leading-snug group-hover:opacity-80 transition-opacity">
										{post.title}
									</h2>
									{#if post.excerpt}
										<p class="text-base opacity-70 line-clamp-2 leading-relaxed">
											{post.excerpt}
										</p>
									{/if}
								</a>
							{/if}

							<!-- Thumbnail (if available) -->
							{#if post.cover_image_url}
								<div class="w-full md:w-32 h-32 flex-shrink-0">
									{#if post.brand}
										<a href="/{post.brand.slug}/{post.slug}{data.brand ? `?brand=${data.brand.slug}` : ''}">
											<img
												src={post.cover_image_url}
												alt={post.title}
												class="w-full h-full object-cover rounded"
											/>
										</a>
									{:else if post.author}
										<a href="/u/{post.author.username}/{post.slug}{data.brand ? `?brand=${data.brand.slug}` : ''}">
											<img
												src={post.cover_image_url}
												alt={post.title}
												class="w-full h-full object-cover rounded"
											/>
										</a>
									{/if}
								</div>
							{/if}
						</div>

						<!-- Bottom Row: Badges + Metadata + Bookmark -->
						<div class="flex items-center justify-between text-sm opacity-60">
							<div class="flex items-center gap-2">
								<span class="badge badge-sm badge-ghost">FREE</span>
								<span>·</span>
								{#if post.brand}
									<span>{post.brand.brand_name}</span>
								{:else if post.author}
									<span>{post.author.display_name || post.author.username}</span>
								{/if}
								<span>·</span>
								<span>{getReadTime(post.excerpt)}</span>
							</div>

							<!-- Bookmark toggle -->
							<button
								class="hover:opacity-100 transition-opacity cursor-pointer {bookmarkedIds.has(post.id) ? 'opacity-100 text-primary' : ''}"
								onclick={() => toggleBookmark(post.id)}
								disabled={bookmarkLoading.has(post.id)}
								aria-label={bookmarkedIds.has(post.id) ? 'Remove bookmark' : 'Bookmark'}
								title={bookmarkedIds.has(post.id) ? 'Remove bookmark' : 'Save for later'}
							>
								{#if bookmarkLoading.has(post.id)}
									<span class="loading loading-spinner loading-xs"></span>
								{:else}
									<svg
										xmlns="http://www.w3.org/2000/svg"
										class="h-4 w-4"
										fill={bookmarkedIds.has(post.id) ? 'currentColor' : 'none'}
										viewBox="0 0 24 24"
										stroke="currentColor"
									>
										<path
											stroke-linecap="round"
											stroke-linejoin="round"
											stroke-width="2"
											d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"
										/>
									</svg>
								{/if}
							</button>
						</div>
					</article>
				{/each}
			</div>
		{:else}
			<div class="text-center py-16">
				<div class="max-w-md mx-auto">
					<svg
						xmlns="http://www.w3.org/2000/svg"
						class="h-24 w-24 mx-auto mb-4 opacity-50"
						fill="none"
						viewBox="0 0 24 24"
						stroke="currentColor"
					>
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z"
						/>
					</svg>
					<h2 class="text-2xl font-bold mb-4">Your feed is empty</h2>
					<p class="mb-6 opacity-80">
						Follow some brands to see their posts in your feed. Discover brands you love on the
						Explore page!
					</p>
					<a href="/explore" class="btn btn-primary">Explore Brands</a>
				</div>
			</div>
		{/if}
	</div>
</div>
