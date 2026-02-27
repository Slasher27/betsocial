<script lang="ts">
	import { supabase } from '$lib/supabase/client';
	import { invalidateAll } from '$app/navigation';
	import { goto } from '$app/navigation';

	let {
		targetType,
		targetId,
		currentUserId,
		likeCount = 0
	} = $props<{
		targetType: 'post' | 'comment';
		targetId: string;
		currentUserId?: string;
		likeCount?: number;
	}>();

	type ReactionType = 'like' | 'fire' | 'money' | 'trophy';

	let selectedReaction = $state<ReactionType | null>(null);
	let loading = $state(false);

	async function handleReaction(reactionType: ReactionType) {
		if (!currentUserId) {
			goto('/auth/login');
			return;
		}

		loading = true;

		// Check if user already has this reaction
		if (selectedReaction === reactionType) {
			// Remove the reaction
			const { error } = await supabase
				.from('reactions')
				.delete()
				.eq('user_id', currentUserId)
				.eq('target_type', targetType)
				.eq('target_id', targetId);

			if (!error) {
				selectedReaction = null;
				await invalidateAll();
			}
		} else {
			// Upsert the reaction (will replace if exists)
			const { error } = await supabase
				.from('reactions')
				.upsert({
					user_id: currentUserId,
					target_type: targetType,
					target_id: targetId,
					reaction_type: reactionType
				}, {
					onConflict: 'user_id,target_type,target_id'
				});

			if (!error) {
				selectedReaction = reactionType;
				await invalidateAll();
			}
		}

		loading = false;
	}

	const reactions: { type: ReactionType; icon: string; label: string; hoverColor: string }[] = [
		{ type: 'like', icon: '❤️', label: 'Like', hoverColor: 'hover:text-error' },
		{ type: 'fire', icon: '🔥', label: 'Fire', hoverColor: 'hover:text-orange-500' },
		{ type: 'money', icon: '💰', label: 'Money', hoverColor: 'hover:text-success' },
		{ type: 'trophy', icon: '🏆', label: 'Trophy', hoverColor: 'hover:text-warning' }
	];
</script>

<div class="flex items-center gap-2">
	{#each reactions as reaction}
		<button
			onclick={() => handleReaction(reaction.type)}
			disabled={loading}
			class="flex items-center gap-1 transition-all cursor-pointer {reaction.hoverColor} {selectedReaction === reaction.type ? 'scale-110' : 'opacity-60 hover:opacity-100'}"
			title={reaction.label}
		>
			<span class="text-lg">{reaction.icon}</span>
			{#if reaction.type === 'like'}
				<span class="text-sm">{likeCount}</span>
			{/if}
		</button>
	{/each}
</div>
