<script lang="ts">
	import { supabase } from '$lib/supabase/client';
	import { onMount, tick } from 'svelte';

	let {
		value = $bindable(''),
		placeholder = 'Write a comment...',
		disabled = false,
		onSubmit,
		class: className = '',
		multiline = true
	} = $props<{
		value: string;
		placeholder?: string;
		disabled?: boolean;
		onSubmit?: () => void;
		class?: string;
		multiline?: boolean;
	}>();

	let textarea: HTMLTextAreaElement | null = $state(null);
	let input: HTMLInputElement | null = $state(null);
	let showMentionDropdown = $state(false);
	let mentionSearchResults = $state<Array<{ type: 'user' | 'brand'; id: string; name: string; slug: string; avatar?: string }>>([]);
	let selectedMentionIndex = $state(0);
	let mentionSearchQuery = $state('');
	let cursorPosition = $state(0);

	// Debounce timer
	let searchTimeout: number | null = null;

	async function searchMentions(query: string) {
		if (!query || query.length < 1) {
			mentionSearchResults = [];
			return;
		}

		// Search users
		const { data: users } = await supabase
			.from('profiles')
			.select('id, username, display_name, avatar_url')
			.or(`username.ilike.%${query}%,display_name.ilike.%${query}%`)
			.limit(5);

		// Search brands
		const { data: brands } = await supabase
			.from('brand_profiles')
			.select('id, slug, brand_name, logo_url')
			.ilike('brand_name', `%${query}%`)
			.limit(5);

		const results: typeof mentionSearchResults = [];

		if (users) {
			results.push(
				...users.map((u) => ({
					type: 'user' as const,
					id: u.id,
					name: u.display_name || u.username,
					slug: u.username,
					avatar: u.avatar_url
				}))
			);
		}

		if (brands) {
			results.push(
				...brands.map((b) => ({
					type: 'brand' as const,
					id: b.id,
					name: b.brand_name,
					slug: b.slug,
					avatar: b.logo_url
				}))
			);
		}

		mentionSearchResults = results;
		selectedMentionIndex = 0;
	}

	function handleInput(e: Event) {
		const target = e.target as HTMLTextAreaElement | HTMLInputElement;
		value = target.value;
		cursorPosition = target.selectionStart || 0;

		// Check if we're typing after an @ symbol (allow hyphens in usernames)
		const beforeCursor = value.slice(0, cursorPosition);
		const match = beforeCursor.match(/@([\w-]*)$/);

		if (match) {
			const query = match[1];
			mentionSearchQuery = query;
			showMentionDropdown = true;

			// Debounce search
			if (searchTimeout) clearTimeout(searchTimeout);
			searchTimeout = window.setTimeout(() => {
				searchMentions(query);
			}, 200);
		} else {
			showMentionDropdown = false;
			mentionSearchResults = [];
		}
	}

	function insertMention(mention: typeof mentionSearchResults[0]) {
		const beforeCursor = value.slice(0, cursorPosition);
		const afterCursor = value.slice(cursorPosition);

		// Find the @ symbol position (allow hyphens in usernames)
		const atSymbolMatch = beforeCursor.match(/@([\w-]*)$/);
		if (!atSymbolMatch) return;

		const atSymbolIndex = beforeCursor.lastIndexOf('@');
		const mentionText = `@${mention.slug}`;

		// Insert the mention
		value = value.slice(0, atSymbolIndex) + mentionText + ' ' + afterCursor;

		// Close dropdown
		showMentionDropdown = false;
		mentionSearchResults = [];

		// Refocus and set cursor position
		tick().then(() => {
			const newCursorPos = atSymbolIndex + mentionText.length + 1;
			if (textarea) {
				textarea.focus();
				textarea.setSelectionRange(newCursorPos, newCursorPos);
			} else if (input) {
				input.focus();
				input.setSelectionRange(newCursorPos, newCursorPos);
			}
		});
	}

	function handleKeyDown(e: KeyboardEvent) {
		if (showMentionDropdown && mentionSearchResults.length > 0) {
			if (e.key === 'ArrowDown') {
				e.preventDefault();
				selectedMentionIndex = (selectedMentionIndex + 1) % mentionSearchResults.length;
			} else if (e.key === 'ArrowUp') {
				e.preventDefault();
				selectedMentionIndex =
					selectedMentionIndex === 0
						? mentionSearchResults.length - 1
						: selectedMentionIndex - 1;
			} else if (e.key === 'Enter' || e.key === 'Tab') {
				e.preventDefault();
				insertMention(mentionSearchResults[selectedMentionIndex]);
			} else if (e.key === 'Escape') {
				e.preventDefault();
				showMentionDropdown = false;
			}
		} else if (multiline && e.key === 'Enter' && (e.metaKey || e.ctrlKey)) {
			e.preventDefault();
			onSubmit?.();
		} else if (!multiline && e.key === 'Enter') {
			e.preventDefault();
			onSubmit?.();
		}
	}
</script>

<div class="relative">
	{#if multiline}
		<textarea
			bind:this={textarea}
			{value}
			{placeholder}
			{disabled}
			class={className}
			oninput={handleInput}
			onkeydown={handleKeyDown}
		></textarea>
	{:else}
		<input
			bind:this={input}
			type="text"
			{value}
			{placeholder}
			{disabled}
			class={className}
			oninput={handleInput}
			onkeydown={handleKeyDown}
		/>
	{/if}

	<!-- Mention Dropdown -->
	{#if showMentionDropdown && mentionSearchResults.length > 0}
		<div
			class="absolute z-50 mt-1 w-full max-w-sm bg-base-100 border border-base-300 rounded-lg shadow-lg max-h-64 overflow-y-auto"
			style="bottom: 100%;"
		>
			{#each mentionSearchResults as mention, index}
				<button
					type="button"
					class="w-full flex items-center gap-3 p-3 hover:bg-base-200 transition-colors cursor-pointer {index ===
					selectedMentionIndex
						? 'bg-base-200'
						: ''}"
					onclick={() => insertMention(mention)}
					onmouseenter={() => (selectedMentionIndex = index)}
				>
					<div class="avatar">
						<div class="w-8 h-8 rounded-full">
							{#if mention.avatar}
								<img src={mention.avatar} alt={mention.name} class="object-cover" />
							{:else}
								<div
									class="w-full h-full bg-neutral text-neutral-content flex items-center justify-center"
								>
									<span class="text-xs font-semibold">{mention.name[0]?.toUpperCase()}</span>
								</div>
							{/if}
						</div>
					</div>
					<div class="flex-1 text-left">
						<div class="font-semibold text-sm">{mention.name}</div>
						<div class="text-xs opacity-60">
							@{mention.slug}
							{#if mention.type === 'brand'}
								<span class="ml-1 badge badge-xs badge-outline">Brand</span>
							{/if}
						</div>
					</div>
				</button>
			{/each}
		</div>
	{/if}
</div>
