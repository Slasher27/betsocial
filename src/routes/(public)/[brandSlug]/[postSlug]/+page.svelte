<script lang="ts">
	import type { PageData } from './$types';
	import { supabase } from '$lib/supabase/client';
	import { goto, invalidateAll } from '$app/navigation';
	import { ArrowLeft } from 'lucide-svelte';
	import TipTapRenderer from '$lib/components/TipTapRenderer.svelte';
	import PostComments from '$lib/components/PostComments.svelte';
	import Reactions from '$lib/components/Reactions.svelte';
	import ShareMenu from '$lib/components/ShareMenu.svelte';
	import BackToTop from '$lib/components/BackToTop.svelte';

	let { data } = $props<{ data: PageData }>();

	let bookmarked = $state(false);
	let loading = $state(false);

	$effect(() => {
		bookmarked = data.isBookmarked;
	});

	function isEdited(): boolean {
		// Check if updated_at is significantly different from created_at (more than 1 second)
		const created = new Date(data.post.created_at).getTime();
		const updated = new Date(data.post.updated_at).getTime();
		return updated - created > 1000;
	}

	function scrollToComments() {
		const commentsSection = document.getElementById('comments');
		if (commentsSection) {
			commentsSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
		}
	}

	async function toggleBookmark() {
		if (!data.session) {
			goto('/auth/login');
			return;
		}

		loading = true;

		if (bookmarked) {
			// Remove bookmark
			const { error } = await supabase
				.from('bookmarks')
				.delete()
				.eq('user_id', data.session.user.id)
				.eq('post_id', data.post.id);

			if (!error) {
				bookmarked = false;
			}
		} else {
			// Add bookmark
			const { error } = await supabase.from('bookmarks').insert({
				user_id: data.session.user.id,
				post_id: data.post.id
			});

			if (!error) {
				bookmarked = true;
			}
		}

		loading = false;
		await invalidateAll();
	}

</script>

<svelte:head>
	<title>{data.post.title} - {data.brand.brand_name} | BetChat</title>
</svelte:head>

<div class="min-h-screen bg-base-100">
	<!-- Post Content -->
	<article class="container mx-auto px-4 py-16 max-w-2xl">
		<!-- Back Button -->
		<button
			onclick={() => window.history.back()}
			class="btn btn-circle btn-ghost mb-8 -ml-2"
			aria-label="Go back"
		>
			<ArrowLeft class="h-6 w-6" />
		</button>

		<!-- Post Header -->
		<header class="mb-12">
			<h1 class="text-5xl md:text-6xl font-bold mb-6 leading-tight">{data.post.title}</h1>

			{#if data.post.excerpt}
				<p class="text-2xl opacity-70 mb-8 leading-relaxed font-light">
					{data.post.excerpt}
				</p>
			{/if}

			<!-- Brand Info & Meta -->
			<div class="flex items-center gap-4 mb-8">
				<a href="/{data.brand.slug}" class="flex items-center gap-3 group">
					<div class="avatar">
						<div class="w-12 h-12 rounded-full">
							{#if data.brand.logo_url}
								<img src={data.brand.logo_url} alt={data.brand.brand_name} class="object-cover" />
							{:else}
								<div class="w-full h-full bg-neutral text-neutral-content flex items-center justify-center">
									<span class="font-semibold">{data.brand.brand_name[0]}</span>
								</div>
							{/if}
						</div>
					</div>
					<div>
						<div class="font-semibold group-hover:underline">{data.brand.brand_name}</div>
						<div class="text-sm opacity-60">
							{new Date(data.post.published_at).toLocaleDateString('en-US', {
								year: 'numeric',
								month: 'long',
								day: 'numeric'
							})}
							{#if isEdited()}
								<span class="ml-2">· Updated {new Date(data.post.updated_at).toLocaleDateString('en-US', {
									month: 'short',
									day: 'numeric'
								})}</span>
							{/if}
						</div>
					</div>
				</a>
			</div>

			<!-- Post Actions Bar -->
			<div class="flex items-center gap-6 py-4 border-y border-base-300 text-sm">
				<Reactions
					targetType="post"
					targetId={data.post.id}
					currentUserId={data.session?.user?.id}
					likeCount={data.post.like_count}
				/>

				<div class="flex items-center gap-2">
					<button
						onclick={scrollToComments}
						class="hover:text-primary transition-colors cursor-pointer"
						aria-label="Go to comments"
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
								d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
							/>
						</svg>
					</button>
					<span class="opacity-70">{data.post.comment_count}</span>
				</div>

				<button
					class="hover:text-primary transition-colors cursor-pointer {bookmarked ? 'text-primary' : ''}"
					onclick={toggleBookmark}
					disabled={loading}
					aria-label="Bookmark"
				>
					{#if loading}
						<span class="loading loading-spinner loading-xs"></span>
					{:else}
						<svg
							xmlns="http://www.w3.org/2000/svg"
							class="h-5 w-5"
							fill={bookmarked ? 'currentColor' : 'none'}
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

				<ShareMenu
					url={typeof window !== 'undefined' ? window.location.href : `https://betchat.social/${data.brand.slug}/${data.post.slug}`}
					title={data.post.title}
				/>
			</div>

			{#if data.post.cover_image_url}
				<img
					src={data.post.cover_image_url}
					alt={data.post.title}
					class="w-full mt-8 rounded"
				/>
			{/if}
		</header>

		<!-- Post Content -->
		<div class="prose prose-lg max-w-none mb-12 post-content">
			{#if data.post.content}
				<TipTapRenderer content={data.post.content} />
			{:else}
				<p class="opacity-70">No content available</p>
			{/if}
		</div>

		<!-- Categories/Tags -->
		{#if data.post.categories && data.post.categories.length > 0}
			<div class="mt-12 pt-8 border-t border-base-300">
				<div class="flex gap-2 flex-wrap">
					{#each data.post.categories as category}
						<span class="px-3 py-1 bg-base-200 rounded-full text-sm opacity-70 hover:opacity-100 transition-opacity cursor-pointer">
							{category}
						</span>
					{/each}
				</div>
			</div>
		{/if}

		<!-- Comments Section -->
		<PostComments
			postId={data.post.id}
			currentUserId={data.session?.user?.id}
			initialComments={data.comments}
		/>
	</article>

	<!-- Back to Top Button -->
	<BackToTop />
</div>

<style>
	:global(.post-content) {
		font-size: 1.125rem;
		line-height: 1.8;
	}

	:global(.post-content h1) {
		font-size: 2.25rem;
		margin-top: 2.5rem;
		margin-bottom: 1.5rem;
		font-weight: 700;
		line-height: 1.2;
	}

	:global(.post-content h2) {
		font-size: 1.875rem;
		margin-top: 2rem;
		margin-bottom: 1.25rem;
		font-weight: 700;
		line-height: 1.3;
	}

	:global(.post-content h3) {
		font-size: 1.5rem;
		margin-top: 1.75rem;
		margin-bottom: 1rem;
		font-weight: 700;
		line-height: 1.4;
	}

	:global(.post-content p) {
		margin-bottom: 1.5rem;
	}

	:global(.post-content a) {
		color: oklch(0.7 0.2 270);
		text-decoration: underline;
	}

	:global(.post-content a:hover) {
		opacity: 0.8;
	}

	:global(.post-content blockquote) {
		border-left: 3px solid oklch(0.7 0.2 270);
		padding-left: 1.5rem;
		font-style: italic;
		margin: 2rem 0;
		opacity: 0.9;
	}

	:global(.post-content img) {
		margin: 2rem 0;
		border-radius: 0.25rem;
	}

	:global(.post-content ul),
	:global(.post-content ol) {
		margin-bottom: 1.5rem;
		padding-left: 1.5rem;
	}

	:global(.post-content li) {
		margin-bottom: 0.5rem;
	}
</style>
