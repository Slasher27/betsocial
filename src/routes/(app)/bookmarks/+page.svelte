<script lang="ts">
	import type { PageData } from './$types';
	import { supabase } from '$lib/supabase/client';

	let { data } = $props<{ data: PageData }>();

	// Local reactive copy so removals reflect instantly without a page reload
	let bookmarks = $state([...(data.bookmarks as any[])]);
	let removing = $state<Set<string>>(new Set());

	async function removeBookmark(postId: string) {
		if (!data.session) return;

		removing = new Set([...removing, postId]);

		const { error } = await supabase
			.from('bookmarks')
			.delete()
			.eq('user_id', data.session.user.id)
			.eq('post_id', postId);

		if (!error) {
			bookmarks = bookmarks.filter((b: any) => b.post_id !== postId);
		}

		removing = new Set([...removing].filter((id) => id !== postId));
	}
</script>

<svelte:head>
	<title>Bookmarks | BetChat</title>
</svelte:head>

<div class="container mx-auto px-4 py-8 max-w-7xl">
	<h1 class="text-3xl font-bold mb-8">Bookmarked Posts</h1>

	{#if bookmarks.length > 0}
		<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
			{#each bookmarks as bookmark (bookmark.post_id)}
				{@const post = (bookmark as any).post}
				{@const brand = (post as any)?.brand}
				{#if post && brand}
					<div class="card bg-base-200 shadow-lg hover:shadow-xl transition-shadow">
						{#if post.cover_image_url}
							<figure>
								<img
									src={post.cover_image_url}
									alt={post.title}
									class="w-full h-48 object-cover"
								/>
							</figure>
						{/if}

						<div class="card-body">
							<!-- Brand Info -->
							<div class="flex items-center justify-between mb-2">
								<div class="flex items-center gap-2">
									<div class="avatar placeholder">
										<div class="bg-neutral text-neutral-content rounded-full w-8">
											{#if brand.logo_url}
												<img src={brand.logo_url} alt={brand.brand_name} />
											{:else}
												<span class="text-xs">{brand.brand_name[0]}</span>
											{/if}
										</div>
									</div>
									<a href="/{brand.slug}" class="text-sm font-semibold hover:text-primary">
										{brand.brand_name}
									</a>
								</div>

								<!-- Remove bookmark button -->
								<button
									class="btn btn-ghost btn-xs text-error hover:bg-error hover:text-error-content"
									onclick={() => removeBookmark(post.id)}
									disabled={removing.has(post.id)}
									aria-label="Remove bookmark"
									title="Remove bookmark"
								>
									{#if removing.has(post.id)}
										<span class="loading loading-spinner loading-xs"></span>
									{:else}
										<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24" stroke="currentColor">
											<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
										</svg>
									{/if}
								</button>
							</div>

							<!-- Post Title -->
							<h2 class="card-title">
								<a href="/{brand.slug}/{post.slug}" class="hover:text-primary">
									{post.title}
								</a>
							</h2>

							<!-- Excerpt -->
							{#if post.excerpt}
								<p class="text-sm opacity-70 line-clamp-2">{post.excerpt}</p>
							{/if}

							<!-- Metadata -->
							<div class="flex items-center gap-4 text-sm opacity-70 mt-2">
								<span>{post.like_count} likes</span>
								<span>{post.comment_count} comments</span>
							</div>

							<!-- Date bookmarked -->
							<div class="text-xs opacity-50 mt-2">
								Bookmarked {new Date(bookmark.created_at).toLocaleDateString()}
							</div>

							<div class="card-actions justify-end mt-4">
								<a href="/{brand.slug}/{post.slug}" class="btn btn-primary btn-sm">
									Read Post
								</a>
							</div>
						</div>
					</div>
				{/if}
			{/each}
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
					d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"
				/>
			</svg>
			<h3 class="text-xl font-bold mb-2">No bookmarks yet</h3>
			<p class="opacity-70 mb-4">Start bookmarking posts to save them for later!</p>
			<a href="/explore" class="btn btn-primary">Explore Posts</a>
		</div>
	{/if}
</div>
