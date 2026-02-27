<script lang="ts">
	import type { PageData } from './$types';
	import { supabase } from '$lib/supabase/client';
	import { invalidateAll } from '$app/navigation';
	import { goto } from '$app/navigation';

	let { data } = $props<{ data: PageData }>();

	let notifications = $state([...(data.notifications as any[])]);
	let markingAll = $state(false);

	function getNotificationText(n: any): string {
		const actorName = n.actor?.display_name || n.actor?.username || 'Someone';
		switch (n.type) {
			case 'new_post':
				return `New post published: "${n.data?.post_title || 'Untitled'}"`;
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

	function getNotificationUrl(n: any): string {
		switch (n.type) {
			case 'new_post':
				if (n.brand?.slug && n.data?.post_slug) return `/${n.brand.slug}/${n.data.post_slug}`;
				return '/feed';
			case 'comment_reply':
				if (n.brand?.slug && n.data?.post_slug) return `/${n.brand.slug}/${n.data.post_slug}`;
				return '/feed';
			case 'new_follower':
				return n.data?.brand_slug ? `/${n.data.brand_slug}` : '/';
			default:
				return '/feed';
		}
	}

	function formatDate(dateStr: string): string {
		return new Date(dateStr).toLocaleDateString('en-US', {
			month: 'short',
			day: 'numeric',
			year: 'numeric',
			hour: '2-digit',
			minute: '2-digit'
		});
	}

	async function markAsRead(id: string) {
		await supabase.from('notifications').update({ is_read: true }).eq('id', id);
		notifications = notifications.map((n: any) =>
			n.id === id ? { ...n, is_read: true } : n
		);
	}

	async function handleClick(n: any) {
		if (!n.is_read) await markAsRead(n.id);
		goto(getNotificationUrl(n));
	}

	async function markAllRead() {
		markingAll = true;
		await supabase
			.from('notifications')
			.update({ is_read: true })
			.eq('user_id', data.session.user.id)
			.eq('is_read', false);

		notifications = notifications.map((n: any) => ({ ...n, is_read: true }));
		markingAll = false;
		await invalidateAll(); // Refresh layout unread count
	}

	const unreadCount = $derived(notifications.filter((n: any) => !n.is_read).length);
</script>

<svelte:head>
	<title>Notifications | BetChat</title>
</svelte:head>

<div class="container mx-auto px-4 py-8 max-w-2xl">
	<div class="flex items-center justify-between mb-6">
		<h1 class="text-3xl font-bold">Notifications</h1>
		{#if unreadCount > 0}
			<button
				class="btn btn-ghost btn-sm"
				onclick={markAllRead}
				disabled={markingAll}
			>
				{#if markingAll}
					<span class="loading loading-spinner loading-xs"></span>
				{/if}
				Mark all as read
			</button>
		{/if}
	</div>

	{#if notifications.length === 0}
		<div class="text-center py-16">
			<div class="text-6xl mb-4">🔔</div>
			<h3 class="text-xl font-bold mb-2">No notifications yet</h3>
			<p class="opacity-70">Follow some brands to start getting updates.</p>
			<a href="/explore" class="btn btn-primary mt-4">Explore Brands</a>
		</div>
	{:else}
		<div class="space-y-1">
			{#each notifications as n (n.id)}
				<button
					class="w-full text-left flex items-start gap-4 p-4 rounded-xl transition-colors hover:bg-base-200 {!n.is_read ? 'bg-base-200' : ''}"
					onclick={() => handleClick(n)}
				>
					<!-- Icon / Actor avatar -->
					<div class="flex-shrink-0 w-10 h-10 flex items-center justify-center rounded-full bg-base-300 text-lg">
						{#if n.actor?.avatar_url}
							<img
								src={n.actor.avatar_url}
								alt={n.actor.username}
								class="w-full h-full rounded-full object-cover"
							/>
						{:else}
							{getNotificationIcon(n.type)}
						{/if}
					</div>

					<!-- Content -->
					<div class="flex-1 min-w-0">
						<p class="text-sm leading-snug {!n.is_read ? 'font-semibold' : ''}">
							{getNotificationText(n)}
						</p>
						<p class="text-xs opacity-50 mt-1">{formatDate(n.created_at)}</p>
					</div>

					<!-- Unread indicator -->
					{#if !n.is_read}
						<div class="flex-shrink-0 w-2.5 h-2.5 rounded-full bg-primary mt-1.5"></div>
					{/if}
				</button>
			{/each}
		</div>
	{/if}
</div>
