<script lang="ts">
	import { toast } from '$lib/stores/toast';
	import { fade, fly } from 'svelte/transition';

	let toasts = $state<any[]>([]);

	$effect(() => {
		const unsubscribe = toast.subscribe((value) => {
			toasts = value;
		});
		return unsubscribe;
	});

	function getAlertClass(type: string) {
		switch (type) {
			case 'success':
				return 'alert-success';
			case 'error':
				return 'alert-error';
			case 'warning':
				return 'alert-warning';
			case 'info':
				return 'alert-info';
			default:
				return '';
		}
	}

	function getIcon(type: string) {
		switch (type) {
			case 'success':
				return 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z';
			case 'error':
				return 'M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z';
			case 'warning':
				return 'M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z';
			case 'info':
				return 'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z';
			default:
				return '';
		}
	}
</script>

<!-- Toast Container (fixed to top-right) -->
<div class="toast toast-top toast-end z-50" role="region" aria-live="polite" aria-label="Notifications">
	{#each toasts as t (t.id)}
		<div
			class="alert {getAlertClass(t.type)} shadow-lg"
			in:fly={{ y: -20, duration: 300 }}
			out:fade={{ duration: 200 }}
		>
			<svg
				xmlns="http://www.w3.org/2000/svg"
				class="h-6 w-6 flex-shrink-0"
				fill="none"
				viewBox="0 0 24 24"
				stroke="currentColor"
				aria-hidden="true"
			>
				<path
					stroke-linecap="round"
					stroke-linejoin="round"
					stroke-width="2"
					d={getIcon(t.type)}
				/>
			</svg>
			<span>{t.message}</span>
			<button
				type="button"
				class="btn btn-sm btn-ghost btn-circle"
				onclick={() => toast.remove(t.id)}
				aria-label="Dismiss notification"
			>
				<svg
					xmlns="http://www.w3.org/2000/svg"
					class="h-4 w-4"
					fill="none"
					viewBox="0 0 24 24"
					stroke="currentColor"
				>
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
				</svg>
			</button>
		</div>
	{/each}
</div>
