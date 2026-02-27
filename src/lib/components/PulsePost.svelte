<script lang="ts">
	import { supabase } from '$lib/supabase/client';
	import { invalidateAll } from '$app/navigation';
	import { goto } from '$app/navigation';
	import { toast } from '$lib/stores/toast';

	let { pulse, currentUserId, currentBrandId } = $props<{
		pulse: any;
		currentUserId?: string;
		currentBrandId?: string;
	}>();

	let showComments = $state(false);
	let commentText = $state('');
	let loading = $state(false);
	let replyingTo = $state<string | null>(null);
	let replyText = $state('');
	let replyLoading = $state(false);

	// Track if current user has liked this pulse
	let userHasLiked = $state(false);
	let likeCount = $state(0);
	let likeLoading = $state(false);

	$effect(() => {
		// Check if current user has liked this pulse
		userHasLiked = pulse.user_reactions?.some((r: any) => r.user_id === currentUserId && r.reaction_type === 'like') || false;
		likeCount = pulse.like_count || 0;
	});

	function formatTimeAgo(dateString: string) {
		const date = new Date(dateString);
		const now = new Date();
		const seconds = Math.floor((now.getTime() - date.getTime()) / 1000);

		if (seconds < 60) return `${seconds}s`;
		if (seconds < 3600) return `${Math.floor(seconds / 60)}m`;
		if (seconds < 86400) return `${Math.floor(seconds / 3600)}h`;
		if (seconds < 604800) return `${Math.floor(seconds / 86400)}d`;
		return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
	}

	async function handleLike() {
		if (!currentUserId || likeLoading) return;

		likeLoading = true;

		if (userHasLiked) {
			// Unlike: Remove the reaction
			const { error } = await supabase
				.from('pulse_reactions')
				.delete()
				.eq('pulse_id', pulse.id)
				.eq('user_id', currentUserId)
				.eq('reaction_type', 'like');

			if (error) {
				toast.error('Failed to unlike pulse');
			} else {
				userHasLiked = false;
				likeCount = Math.max(0, likeCount - 1);
			}
		} else {
			// Like: Add the reaction
			const { error } = await supabase
				.from('pulse_reactions')
				.insert({
					pulse_id: pulse.id,
					user_id: currentUserId,
					reaction_type: 'like'
				});

			if (error) {
				toast.error('Failed to like pulse');
			} else {
				userHasLiked = true;
				likeCount = likeCount + 1;
			}
		}

		likeLoading = false;
		await invalidateAll();
	}

	async function handleComment() {
		if (!currentUserId) {
			goto('/auth/login');
			return;
		}

		if (!commentText.trim()) return;

		loading = true;
		const { error } = await supabase
			.from('pulse_comments')
			.insert({
				pulse_id: pulse.id,
				author_id: currentUserId,
				brand_id: currentBrandId || null,
				content: commentText.trim()
			});

		if (error) {
			toast.error('Failed to post comment');
		} else {
			commentText = '';
			toast.success('Comment posted!');
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
		const { error} = await supabase.from('pulse_comments').insert({
			pulse_id: pulse.id,
			author_id: currentUserId,
			brand_id: currentBrandId || null,
			parent_id: parentId,
			content: replyText.trim()
		});

		if (error) {
			toast.error('Failed to post reply');
		} else {
			replyText = '';
			replyingTo = null;
			toast.success('Reply posted!');
			await invalidateAll();
		}
		replyLoading = false;
	}

	// Organize comments into parent-child structure
	let organizedComments = $derived(() => {
		const comments = pulse.comments || [];
		const topLevel = comments.filter((c: any) => !c.parent_id);
		const replies = comments.filter((c: any) => c.parent_id);

		return topLevel.map((comment: any) => ({
			...comment,
			replies: replies.filter((r: any) => r.parent_id === comment.id)
		}));
	});
</script>

<div class="card bg-base-200 shadow-md">
	<div class="card-body p-4">
		<!-- Header -->
		<div class="flex items-start gap-3">
			<!-- Avatar -->
			<div class="avatar">
				<div class="w-10 h-10 rounded-full">
					{#if pulse.brand}
						{#if pulse.brand.logo_url}
							<img src={pulse.brand.logo_url} alt={pulse.brand.brand_name} class="object-cover" />
						{:else}
							<div class="w-full h-full bg-neutral text-neutral-content flex items-center justify-center">
								<span class="text-sm font-semibold">
									{pulse.brand.brand_name[0].toUpperCase()}
								</span>
							</div>
						{/if}
					{:else if pulse.author?.avatar_url}
						<img src={pulse.author.avatar_url} alt={pulse.author.username} class="object-cover" />
					{:else}
						<div class="w-full h-full bg-neutral text-neutral-content flex items-center justify-center">
							<span class="text-sm font-semibold">
								{pulse.author?.username[0].toUpperCase()}
							</span>
						</div>
					{/if}
				</div>
			</div>

			<!-- Content -->
			<div class="flex-1 min-w-0">
				<div class="flex items-center gap-2 mb-1">
					{#if pulse.brand}
						<a href="/{pulse.brand.slug}" class="font-semibold hover:underline">
							{pulse.brand.brand_name}
						</a>
						<span class="opacity-60">@{pulse.brand.slug}</span>
					{:else}
						<a href="/u/{pulse.author?.username}" class="font-semibold hover:underline">
							{pulse.author?.display_name || pulse.author?.username}
						</a>
						<span class="opacity-60">@{pulse.author?.username}</span>
					{/if}
					<span class="opacity-60">·</span>
					<time class="opacity-60 text-sm" datetime={pulse.created_at}>
						{formatTimeAgo(pulse.created_at)}
					</time>
				</div>

				<p class="whitespace-pre-wrap break-words">{pulse.content}</p>

				<!-- Image (if present) -->
				{#if pulse.image_url}
					<div class="mt-3">
						<img
							src={pulse.image_url}
							alt="Posted content"
							class="rounded-lg max-h-96 w-full object-cover border border-base-300"
						/>
					</div>
				{/if}

				<!-- Actions -->
				<div class="flex items-center gap-6 mt-3" role="group" aria-label="Pulse actions">
					<button
						type="button"
						onclick={() => (showComments = !showComments)}
						class="flex items-center gap-1 hover:text-primary transition-colors cursor-pointer"
						aria-label="{showComments ? 'Hide' : 'Show'} comments ({pulse.comment_count || 0})"
						aria-expanded={showComments}
					>
						<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
						</svg>
						<span class="text-sm" aria-hidden="true">{pulse.comment_count || 0}</span>
					</button>

					<button
						type="button"
						onclick={handleLike}
						disabled={!currentUserId || likeLoading}
						class="flex items-center gap-1 transition-colors {userHasLiked ? 'text-error' : 'hover:text-error'} {currentUserId ? 'cursor-pointer' : 'cursor-not-allowed'}"
						aria-label="{currentUserId ? (userHasLiked ? 'Unlike' : 'Like') : 'Sign in to like'} ({likeCount} likes)"
						aria-pressed={userHasLiked}
						title={currentUserId ? (userHasLiked ? 'Unlike this pulse' : 'Like this pulse') : 'Sign in to like pulses'}
					>
						{#if likeLoading}
							<span class="loading loading-spinner loading-xs" aria-hidden="true"></span>
						{:else}
							<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill={userHasLiked ? 'currentColor' : 'none'} viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
							</svg>
						{/if}
						<span class="text-sm" aria-hidden="true">{likeCount}</span>
					</button>

					<button
						type="button"
						class="flex items-center gap-1 hover:text-success transition-colors cursor-not-allowed"
						disabled
						aria-label="Repost ({pulse.repost_count || 0} reposts) - Coming soon"
						title="Repost feature coming soon"
					>
						<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
						</svg>
						<span class="text-sm" aria-hidden="true">{pulse.repost_count || 0}</span>
					</button>
				</div>

				<!-- Comments Section (shown when clicked) -->
				{#if showComments}
					<div class="mt-4 space-y-3">
						<!-- Comment Input -->
						{#if currentUserId}
							<div class="flex gap-2">
								<label for="pulse-comment-input-{pulse.id}" class="sr-only">Write a comment on this pulse</label>
								<input
									id="pulse-comment-input-{pulse.id}"
									type="text"
									bind:value={commentText}
									placeholder="Write a comment..."
									class="input input-sm input-bordered flex-1"
									disabled={loading}
									aria-label="Comment text"
									onkeydown={(e) => {
										if (e.key === 'Enter') handleComment();
									}}
								/>
								<button
									type="button"
									onclick={handleComment}
									disabled={loading || !commentText.trim()}
									class="btn btn-sm btn-primary"
									aria-label="Post comment"
								>
									{#if loading}
										<span class="loading loading-spinner loading-xs" aria-hidden="true"></span>
										<span class="sr-only">Posting comment...</span>
									{:else}
										Comment
									{/if}
								</button>
							</div>
						{:else}
							<div class="text-center py-2 text-sm opacity-70">
								<a href="/auth/login" class="link">Sign in</a> to comment
							</div>
						{/if}

						<!-- Display Comments -->
						{#if organizedComments().length > 0}
							<div class="space-y-3 max-h-96 overflow-y-auto">
								{#each organizedComments() as comment}
									<div class="bg-base-300 rounded-lg p-3">
										<!-- Comment Header -->
										<div class="flex items-start gap-2">
											<div class="avatar">
												<div class="w-7 h-7 rounded-full">
													{#if comment.brand}
														{#if comment.brand.logo_url}
															<img
																src={comment.brand.logo_url}
																alt={comment.brand.brand_name}
																class="object-cover"
															/>
														{:else}
															<div class="w-full h-full bg-neutral text-neutral-content flex items-center justify-center">
																<span class="text-xs font-semibold">
																	{comment.brand.brand_name[0].toUpperCase()}
																</span>
															</div>
														{/if}
													{:else if comment.author?.avatar_url}
														<img
															src={comment.author.avatar_url}
															alt={comment.author.username}
															class="object-cover"
														/>
													{:else}
														<div class="w-full h-full bg-neutral text-neutral-content flex items-center justify-center">
															<span class="text-xs font-semibold">
																{comment.author?.username?.[0]?.toUpperCase() || '?'}
															</span>
														</div>
													{/if}
												</div>
											</div>

											<div class="flex-1 min-w-0">
												<div class="flex items-center gap-1.5 mb-1">
													{#if comment.brand}
														<a href="/{comment.brand.slug}" class="font-semibold text-sm hover:underline">
															{comment.brand.brand_name}
														</a>
														<span class="opacity-60 text-xs">@{comment.brand.slug}</span>
													{:else}
														<a href="/u/{comment.author?.username}" class="font-semibold text-sm hover:underline">
															{comment.author?.display_name || comment.author?.username}
														</a>
														<span class="opacity-60 text-xs">@{comment.author?.username}</span>
													{/if}
													<span class="opacity-60">·</span>
													<time class="opacity-60 text-xs" datetime={comment.created_at}>
														{formatTimeAgo(comment.created_at)}
													</time>
												</div>

												<p class="whitespace-pre-wrap break-words text-sm mb-2">{comment.content}</p>

												<!-- Comment Actions -->
												<div class="flex items-center gap-3 text-xs">
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
												</div>

												<!-- Reply Input -->
												{#if replyingTo === comment.id && currentUserId}
													<div class="mt-2 flex gap-2">
														<input
															type="text"
															bind:value={replyText}
															placeholder="Write a reply..."
															class="input input-xs input-bordered flex-1"
															disabled={replyLoading}
															onkeydown={(e) => {
																if (e.key === 'Enter') handleReply(comment.id);
															}}
														/>
														<button
															onclick={() => handleReply(comment.id)}
															disabled={replyLoading || !replyText.trim()}
															class="btn btn-xs btn-primary"
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
															class="btn btn-xs btn-ghost"
														>
															Cancel
														</button>
													</div>
												{/if}

												<!-- Nested Replies -->
												{#if comment.replies && comment.replies.length > 0}
													<div class="mt-3 space-y-2 ml-3 pl-3 border-l-2 border-base-content/10">
														{#each comment.replies as reply}
															<div class="flex items-start gap-2">
																<div class="avatar">
																	<div class="w-6 h-6 rounded-full">
																		{#if reply.brand}
																			{#if reply.brand.logo_url}
																				<img
																					src={reply.brand.logo_url}
																					alt={reply.brand.brand_name}
																					class="object-cover"
																				/>
																			{:else}
																				<div class="w-full h-full bg-neutral text-neutral-content flex items-center justify-center">
																					<span class="text-xs font-semibold">
																						{reply.brand.brand_name[0].toUpperCase()}
																					</span>
																				</div>
																			{/if}
																		{:else if reply.author?.avatar_url}
																			<img
																				src={reply.author.avatar_url}
																				alt={reply.author.username}
																				class="object-cover"
																			/>
																		{:else}
																			<div class="w-full h-full bg-neutral text-neutral-content flex items-center justify-center">
																				<span class="text-xs font-semibold">
																					{reply.author?.username?.[0]?.toUpperCase() || '?'}
																				</span>
																			</div>
																		{/if}
																	</div>
																</div>

																<div class="flex-1 min-w-0">
																	<div class="flex items-center gap-1.5 mb-1">
																		{#if reply.brand}
																			<a href="/{reply.brand.slug}" class="font-semibold text-xs hover:underline">
																				{reply.brand.brand_name}
																			</a>
																			<span class="opacity-60 text-xs">@{reply.brand.slug}</span>
																		{:else}
																			<a href="/u/{reply.author?.username}" class="font-semibold text-xs hover:underline">
																				{reply.author?.display_name || reply.author?.username}
																			</a>
																			<span class="opacity-60 text-xs">@{reply.author?.username}</span>
																		{/if}
																		<span class="opacity-60">·</span>
																		<time class="opacity-60 text-xs" datetime={reply.created_at}>
																			{formatTimeAgo(reply.created_at)}
																		</time>
																	</div>

																	<p class="whitespace-pre-wrap break-words text-xs">
																		{reply.content}
																	</p>
																</div>
															</div>
														{/each}
													</div>
												{/if}
											</div>
										</div>
									</div>
								{/each}
							</div>
						{/if}
					</div>
				{/if}
			</div>
		</div>
	</div>
</div>
