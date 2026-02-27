<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { supabase } from '$lib/supabase/client';
	import { goto } from '$app/navigation';

	let { userId, initialUnreadCount = 0 } = $props<{
		userId: string;
		initialUnreadCount?: number;
	}>();

	type Notification = {
		id: string;
		type: 'new_post' | 'comment_reply' | 'new_follower' | 'promotion' | 'mention';
		data: Record<string, any>;
		is_read: boolean;
		created_at: string;
		actor?: { username: string; display_name: string | null; avatar_url: string | null } | null;
	};

	let open = $state(false);
	let unreadCount = $state(0);

	$effect(() => {
		unreadCount = initialUnreadCount;
	});
	let notifications = $state<Notification[]>([]);
	let loading = $state(false);
	let fetched = $state(false);

	let realtimeChannel: ReturnType<typeof supabase.channel> | null = null;

	// Fetch recent notifications when dropdown opens (lazy load)
	async function fetchNotifications() {
		if (fetched) return;
		loading = true;

		const { data } = await supabase
			.from('notifications')
			.select('id, type, data, is_read, created_at')
			.eq('user_id', userId)
			.order('created_at', { ascending: false })
			.limit(15);

		// Enrich with actor profile for comment/follower types
		const enriched: Notification[] = await Promise.all(
			(data || []).map(async (n: any) => {
				let actor = null;
				const actorId = n.data?.commenter_id || n.data?.follower_id;
				if (actorId) {
					const { data: profile } = await supabase
						.from('profiles')
						.select('username, display_name, avatar_url')
						.eq('id', actorId)
						.single();
					actor = profile;
				}
				return { ...n, actor };
			})
		);

		notifications = enriched;
		fetched = true;
		loading = false;
	}

	async function toggleOpen() {
		open = !open;
		if (open) {
			await fetchNotifications();
		}
	}

	async function markAllRead() {
		await supabase
			.from('notifications')
			.update({ is_read: true })
			.eq('user_id', userId)
			.eq('is_read', false);

		notifications = notifications.map((n) => ({ ...n, is_read: true }));
		unreadCount = 0;
	}

	async function handleNotificationClick(n: Notification) {
		// Mark as read
		if (!n.is_read) {
			await supabase.from('notifications').update({ is_read: true }).eq('id', n.id);
			notifications = notifications.map((item) =>
				item.id === n.id ? { ...item, is_read: true } : item
			);
			unreadCount = Math.max(0, unreadCount - 1);
		}

		open = false;

		// Navigate to relevant content
		const url = getNotificationUrl(n);
		if (url) goto(url);
	}

	function getNotificationUrl(n: Notification): string | null {
		switch (n.type) {
			case 'new_post':
				// We need the brand slug — stored in data.brand_id, but we need the slug.
				// Fall back to /feed if we don't have enough info.
				return n.data?.post_slug && n.data?.brand_id ? null : '/feed';
			case 'comment_reply':
				if (n.data?.brand_id && n.data?.post_slug) {
					// Need brand slug — we'll link to feed for now; improved in full page
					return '/notifications';
				}
				return '/notifications';
			case 'new_follower':
				return n.data?.brand_slug ? `/${n.data.brand_slug}` : '/notifications';
			default:
				return '/notifications';
		}
	}

	function getNotificationText(n: Notification): string {
		const actorName = n.actor?.display_name || n.actor?.username || 'Someone';
		switch (n.type) {
			case 'new_post':
				return `New post: "${n.data?.post_title || 'Untitled'}"`;
			case 'comment_reply':
				return n.data?.parent_id
					? `${actorName} replied to your comment on "${n.data?.post_title}"`
					: `${actorName} commented on "${n.data?.post_title}"`;
			case 'new_follower':
				return `${actorName} started following ${n.data?.brand_name || 'your brand'}`;
			case 'promotion':
				return n.data?.message || 'New promotion available';
			case 'mention':
				return `${actorName} mentioned you`;
			default:
				return 'New notification';
		}
	}

	function getNotificationIcon(type: string): string {
		switch (type) {
			case 'new_post':      return '📝';
			case 'comment_reply': return '💬';
			case 'new_follower':  return '👤';
			case 'promotion':     return '🎁';
			case 'mention':       return '@';
			default:              return '🔔';
		}
	}

	function formatTime(dateStr: string): string {
		const diff = Date.now() - new Date(dateStr).getTime();
		const mins = Math.floor(diff / 60000);
		if (mins < 1)  return 'just now';
		if (mins < 60) return `${mins}m ago`;
		const hrs = Math.floor(mins / 60);
		if (hrs < 24)  return `${hrs}h ago`;
		const days = Math.floor(hrs / 24);
		if (days < 7)  return `${days}d ago`;
		return new Date(dateStr).toLocaleDateString();
	}

	function handleClickOutside(e: MouseEvent) {
		const target = e.target as HTMLElement;
		if (!target.closest('[data-notification-bell]')) {
			open = false;
		}
	}

	onMount(() => {
		// Subscribe to realtime inserts on notifications for this user
		realtimeChannel = supabase
			.channel(`notifications:${userId}`)
			.on(
				'postgres_changes',
				{
					event: 'INSERT',
					schema: 'public',
					table: 'notifications',
					filter: `user_id=eq.${userId}`
				},
				(payload) => {
					unreadCount += 1;
					// Prepend to list if already fetched
					if (fetched) {
						notifications = [{ ...(payload.new as Notification), actor: null }, ...notifications];
					}
				}
			)
			.subscribe();
	});

	onDestroy(() => {
		realtimeChannel?.unsubscribe();
	});
</script>

<svelte:window onclick={handleClickOutside} />

<div class="relative" data-notification-bell>
	<button
		class="btn btn-ghost btn-circle relative"
		aria-label="Notifications"
		aria-expanded={open}
		onclick={toggleOpen}
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
				d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"
			/>
		</svg>

		{#if unreadCount > 0}
			<span class="absolute top-1 right-1 flex h-4 w-4 items-center justify-center rounded-full bg-error text-error-content text-[10px] font-bold leading-none">
				{unreadCount > 9 ? '9+' : unreadCount}
			</span>
		{/if}
	</button>

	{#if open}
		<div class="absolute right-0 top-12 z-50 w-80 card bg-base-200 shadow-xl border border-base-300">
			<!-- Header -->
			<div class="flex items-center justify-between px-4 py-3 border-b border-base-300">
				<span class="font-semibold">Notifications</span>
				<div class="flex items-center gap-2">
					{#if unreadCount > 0}
						<button
							class="text-xs text-primary hover:underline cursor-pointer"
							onclick={markAllRead}
						>
							Mark all read
						</button>
					{/if}
					<a href="/notifications" class="text-xs opacity-60 hover:opacity-100" onclick={() => (open = false)}>
						See all
					</a>
				</div>
			</div>

			<!-- Body -->
			<div class="max-h-96 overflow-y-auto">
				{#if loading}
					<div class="flex justify-center py-8">
						<span class="loading loading-spinner loading-sm"></span>
					</div>
				{:else if notifications.length === 0}
					<div class="text-center py-8 opacity-60 text-sm">
						No notifications yet
					</div>
				{:else}
					{#each notifications as n (n.id)}
						<button
							class="w-full text-left flex items-start gap-3 px-4 py-3 hover:bg-base-300 transition-colors border-b border-base-300/50 last:border-0 {!n.is_read ? 'bg-base-300/40' : ''}"
							onclick={() => handleNotificationClick(n)}
						>
							<!-- Icon / Avatar -->
							<div class="flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-full bg-base-300 text-sm">
								{#if n.actor?.avatar_url}
									<img src={n.actor.avatar_url} alt={n.actor.username} class="w-full h-full rounded-full object-cover" />
								{:else}
									{getNotificationIcon(n.type)}
								{/if}
							</div>

							<!-- Text -->
							<div class="flex-1 min-w-0">
								<p class="text-sm leading-snug {!n.is_read ? 'font-medium' : ''}">
									{getNotificationText(n)}
								</p>
								<p class="text-xs opacity-50 mt-0.5">{formatTime(n.created_at)}</p>
							</div>

							<!-- Unread dot -->
							{#if !n.is_read}
								<div class="flex-shrink-0 w-2 h-2 rounded-full bg-primary mt-1.5"></div>
							{/if}
						</button>
					{/each}
				{/if}
			</div>
		</div>
	{/if}
</div>
