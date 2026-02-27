<script lang="ts">
	import { supabase } from '$lib/supabase/client';
	import { invalidateAll } from '$app/navigation';
	import { goto } from '$app/navigation';
	import MentionInput from '$lib/components/MentionInput.svelte';
	import { parseMentions, createMentions, renderMentions } from '$lib/utils/mentions';

	let { postId, currentUserId, initialComments = [] } = $props<{
		postId: string;
		currentUserId?: string;
		initialComments?: any[];
	}>();

	let commentText = $state('');
	let loading = $state(false);
	let replyingTo = $state<string | null>(null);
	let replyText = $state('');
	let replyLoading = $state(false);

	function formatTimeAgo(dateString: string) {
		const date = new Date(dateString);
		const now = new Date();
		const seconds = Math.floor((now.getTime() - date.getTime()) / 1000);

		if (seconds < 60) return `${seconds}s ago`;
		if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
		if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
		if (seconds < 604800) return `${Math.floor(seconds / 86400)}d ago`;
		return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
	}

	async function handleComment() {
		if (!currentUserId) {
			goto('/auth/login');
			return;
		}

		if (!commentText.trim()) return;

		loading = true;

		// Create the comment
		const { data: comment, error } = await supabase
			.from('comments')
			.insert({
				post_id: postId,
				author_id: currentUserId,
				content: commentText.trim()
			})
			.select()
			.single();

		if (!error && comment) {
			// Parse and create mentions
			const mentions = await parseMentions(commentText.trim(), supabase);
			await createMentions(comment.id, mentions, supabase);

			commentText = '';
			await invalidateAll();
		}
		loading = false;
	}

	async function handleReply(parentId: string) {
		if (!currentUserId) {
			goto('/auth/login');
			return;
		}

		if (!replyText.trim()) return;

		replyLoading = true;

		// Create the reply
		const { data: reply, error } = await supabase
			.from('comments')
			.insert({
				post_id: postId,
				author_id: currentUserId,
				parent_id: parentId,
				content: replyText.trim()
			})
			.select()
			.single();

		if (!error && reply) {
			// Parse and create mentions
			const mentions = await parseMentions(replyText.trim(), supabase);
			await createMentions(reply.id, mentions, supabase);

			replyText = '';
			replyingTo = null;
			await invalidateAll();
		}
		replyLoading = false;
	}

	// Helper to convert database mentions to ParsedMention format
	function convertMentions(dbMentions: any[]) {
		if (!dbMentions || !Array.isArray(dbMentions)) {
			return [];
		}
		return dbMentions.map((m: any) => ({
			username: m.mentioned_user?.username || m.mentioned_brand?.slug || '',
			type: (m.mentioned_user_id ? 'user' : 'brand') as 'user' | 'brand',
			id: m.mentioned_user_id || m.mentioned_brand_id
		}));
	}

	// Organize comments into parent-child structure
	let organizedComments = $derived(() => {
		const topLevel = initialComments.filter((c) => !c.parent_id);
		const replies = initialComments.filter((c) => c.parent_id);

		return topLevel.map((comment) => ({
			...comment,
			parsedMentions: convertMentions(comment.mentions),
			replies: replies.filter((r) => r.parent_id === comment.id).map((reply) => ({
				...reply,
				parsedMentions: convertMentions(reply.mentions)
			}))
		}));
	});
</script>

<div id="comments" class="mt-16 pt-8 border-t border-base-300 scroll-mt-20">
	<h2 class="text-2xl font-bold mb-6">
		Comments ({initialComments.length})
	</h2>

	<!-- Comment Input -->
	{#if currentUserId}
		<div class="mb-8">
			<MentionInput
				bind:value={commentText}
				placeholder="Write a comment... (use @ to mention users or brands)"
				class="textarea textarea-bordered w-full min-h-24"
				disabled={loading}
				onSubmit={handleComment}
				multiline={true}
			/>
			<div class="flex justify-end mt-2">
				<button
					onclick={handleComment}
					disabled={loading || !commentText.trim()}
					class="btn btn-primary btn-sm"
				>
					{#if loading}
						<span class="loading loading-spinner loading-xs"></span>
					{:else}
						Post Comment
					{/if}
				</button>
			</div>
		</div>
	{:else}
		<div class="mb-8 p-4 bg-base-200 rounded-lg text-center">
			<p class="opacity-70 mb-2">Sign in to join the conversation</p>
			<a href="/auth/login" class="btn btn-primary btn-sm">Sign In</a>
		</div>
	{/if}

	<!-- Comments List -->
	<div class="space-y-6">
		{#each organizedComments() as comment}
			<div class="bg-base-200 rounded-lg p-4">
				<!-- Comment Header -->
				<div class="flex items-start gap-3 mb-3">
					<div class="avatar">
						<div class="w-10 h-10 rounded-full">
							{#if comment.author?.avatar_url}
								<img
									src={comment.author.avatar_url}
									alt={comment.author.username}
									class="object-cover"
								/>
							{:else}
								<div
									class="w-full h-full bg-neutral text-neutral-content flex items-center justify-center"
								>
									<span class="text-sm font-semibold">
										{comment.author?.username?.[0]?.toUpperCase() || '?'}
									</span>
								</div>
							{/if}
						</div>
					</div>

					<div class="flex-1 min-w-0">
						<div class="flex items-center gap-2 mb-1">
							<a
								href="/u/{comment.author?.username}"
								class="font-semibold hover:underline"
							>
								{comment.author?.display_name || comment.author?.username}
							</a>
							<span class="opacity-60 text-sm">@{comment.author?.username}</span>
							<span class="opacity-60">·</span>
							<time class="opacity-60 text-sm" datetime={comment.created_at}>
								{formatTimeAgo(comment.created_at)}
							</time>
						</div>

						<p class="whitespace-pre-wrap break-words mb-3">
							{@html renderMentions(comment.content, comment.parsedMentions)}
						</p>

						<!-- Comment Actions -->
						<div class="flex items-center gap-4 text-sm">
							<button
								onclick={() => {
									if (replyingTo === comment.id) {
										replyingTo = null;
									} else {
										replyingTo = comment.id;
										replyText = '';
									}
								}}
								class="hover:text-primary transition-colors cursor-pointer"
							>
								Reply
							</button>
							<button class="flex items-center gap-1 hover:text-error transition-colors cursor-pointer">
								<svg
									xmlns="http://www.w3.org/2000/svg"
									class="h-4 w-4"
									fill="none"
									viewBox="0 0 24 24"
									stroke="currentColor"
								>
									<path
										stroke-linecap="round"
										stroke-linejoin="round"
										stroke-width="2"
										d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
									/>
								</svg>
								<span>{comment.like_count || 0}</span>
							</button>
						</div>

						<!-- Reply Input -->
						{#if replyingTo === comment.id && currentUserId}
							<div class="mt-3 flex gap-2">
								<MentionInput
									bind:value={replyText}
									placeholder="Write a reply... (use @ to mention)"
									class="input input-sm input-bordered flex-1"
									disabled={replyLoading}
									onSubmit={() => handleReply(comment.id)}
									multiline={false}
								/>
								<button
									onclick={() => handleReply(comment.id)}
									disabled={replyLoading || !replyText.trim()}
									class="btn btn-sm btn-primary"
								>
									{#if replyLoading}
										<span class="loading loading-spinner loading-xs"></span>
									{:else}
										Reply
									{/if}
								</button>
								<button
									onclick={() => {
										replyingTo = null;
										replyText = '';
									}}
									class="btn btn-sm btn-ghost"
								>
									Cancel
								</button>
							</div>
						{/if}

						<!-- Nested Replies -->
						{#if comment.replies && comment.replies.length > 0}
							<div class="mt-4 space-y-3 ml-4 pl-4 border-l-2 border-base-300">
								{#each comment.replies as reply}
									<div class="flex items-start gap-2">
										<div class="avatar">
											<div class="w-8 h-8 rounded-full">
												{#if reply.author?.avatar_url}
													<img
														src={reply.author.avatar_url}
														alt={reply.author.username}
														class="object-cover"
													/>
												{:else}
													<div
														class="w-full h-full bg-neutral text-neutral-content flex items-center justify-center"
													>
														<span class="text-xs font-semibold">
															{reply.author?.username?.[0]?.toUpperCase() || '?'}
														</span>
													</div>
												{/if}
											</div>
										</div>

										<div class="flex-1 min-w-0">
											<div class="flex items-center gap-2 mb-1">
												<a
													href="/u/{reply.author?.username}"
													class="font-semibold text-sm hover:underline"
												>
													{reply.author?.display_name || reply.author?.username}
												</a>
												<span class="opacity-60 text-xs">@{reply.author?.username}</span>
												<span class="opacity-60">·</span>
												<time class="opacity-60 text-xs" datetime={reply.created_at}>
													{formatTimeAgo(reply.created_at)}
												</time>
											</div>

											<p class="whitespace-pre-wrap break-words text-sm mb-2">
												{@html renderMentions(reply.content, reply.parsedMentions)}
											</p>

											<div class="flex items-center gap-4 text-xs">
												<button class="flex items-center gap-1 hover:text-error transition-colors cursor-pointer">
													<svg
														xmlns="http://www.w3.org/2000/svg"
														class="h-3 w-3"
														fill="none"
														viewBox="0 0 24 24"
														stroke="currentColor"
													>
														<path
															stroke-linecap="round"
															stroke-linejoin="round"
															stroke-width="2"
															d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
														/>
													</svg>
													<span>{reply.like_count || 0}</span>
												</button>
											</div>
										</div>
									</div>
								{/each}
							</div>
						{/if}
					</div>
				</div>
			</div>
		{/each}

		{#if initialComments.length === 0}
			<div class="text-center py-12 opacity-70">
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
						d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
					/>
				</svg>
				<p class="text-lg">No comments yet</p>
				<p class="text-sm mt-1">Be the first to share your thoughts!</p>
			</div>
		{/if}
	</div>
</div>
