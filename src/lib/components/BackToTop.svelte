<script lang="ts">
	import { onMount } from 'svelte';
	import { ArrowUp } from 'lucide-svelte';

	let showButton = $state(false);

	function scrollToTop() {
		window.scrollTo({
			top: 0,
			behavior: 'smooth'
		});
	}

	onMount(() => {
		function handleScroll() {
			showButton = window.scrollY > 500;
		}

		window.addEventListener('scroll', handleScroll);

		return () => {
			window.removeEventListener('scroll', handleScroll);
		};
	});
</script>

{#if showButton}
	<button
		onclick={scrollToTop}
		class="fixed bottom-8 right-8 btn btn-circle btn-primary shadow-lg z-50 hover:scale-110 transition-transform"
		aria-label="Back to top"
	>
		<ArrowUp class="h-5 w-5" />
	</button>
{/if}
