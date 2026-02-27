<script lang="ts">
	import type { PageData } from './$types';
	import { enhance } from '$app/forms';
	import TipTapEditor from '$lib/components/TipTapEditor.svelte';

	let { data } = $props<{ data: PageData }>();

	let title = $state((data.post as any).title);
	let slug = $state((data.post as any).slug);
	let excerpt = $state((data.post as any).excerpt || '');
	let content = $state((data.post as any).content);
	let categories = $state((data.post as any).categories?.join(', ') || '');
	let loading = $state(false);
	let successMessage = $state('');

	function generateSlug() {
		slug = title
			.toLowerCase()
			.replace(/[^a-z0-9]+/g, '-')
			.replace(/(^-|-$)/g, '');
	}

	async function handleSubmit(e: MouseEvent, status: 'draft' | 'published') {
		e.preventDefault();
		const button = e.target as HTMLButtonElement;
		const form = button.closest('form') as HTMLFormElement;
		const formData = new FormData(form);
		formData.set('status', status);
		formData.set('content', JSON.stringify(content));

		loading = true;
		successMessage = '';

		const response = await fetch(form.action, {
			method: 'POST',
			body: formData
		});

		loading = false;

		if (response.ok) {
			successMessage =
				status === 'published' ? 'Post updated and published!' : 'Post saved as draft!';
			// Auto-hide message after 3 seconds
			setTimeout(() => (successMessage = ''), 3000);

			// Redirect to dashboard after a short delay
			setTimeout(() => {
				window.location.href = '/dashboard';
			}, 1500);
		} else {
			// Handle error
			const result = await response.json();
			alert(result.error || 'Failed to update post');
		}
	}
</script>

<svelte:head>
	<title>Edit Post | BetChat</title>
</svelte:head>

<div class="container mx-auto px-4 py-8 max-w-4xl">
	<div class="mb-8">
		<h1 class="text-3xl font-bold mb-2">Edit Post</h1>
		<div class="text-sm breadcrumbs mb-4">
			<ul>
				<li>
					<a href="/dashboard{(data.post as any).brand ? `?brand=${(data.post as any).brand.slug}` : ''}">
						Dashboard
					</a>
				</li>
				<li>Edit Post</li>
			</ul>
		</div>
		{#if (data.post as any).brand}
			<div class="alert alert-info">
				<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
				</svg>
				<span>Editing post for <strong>{(data.post as any).brand.brand_name}</strong></span>
			</div>
		{/if}
	</div>

	{#if successMessage}
		<div class="alert alert-success mb-6">
			<svg
				xmlns="http://www.w3.org/2000/svg"
				class="stroke-current shrink-0 h-6 w-6"
				fill="none"
				viewBox="0 0 24 24"
			>
				<path
					stroke-linecap="round"
					stroke-linejoin="round"
					stroke-width="2"
					d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
				/>
			</svg>
			<span>{successMessage}</span>
		</div>
	{/if}

	<form method="POST" class="space-y-6">
		<!-- Title -->
		<div class="form-control">
			<label class="label" for="title">
				<span class="label-text">Title</span>
			</label>
			<input
				type="text"
				id="title"
				name="title"
				bind:value={title}
				onblur={generateSlug}
				class="input input-bordered"
				required
				maxlength="200"
			/>
		</div>

		<!-- Slug -->
		<div class="form-control">
			<label class="label" for="slug">
				<span class="label-text">URL Slug</span>
			</label>
			<input
				type="text"
				id="slug"
				name="slug"
				bind:value={slug}
				class="input input-bordered"
				required
				pattern="[a-z0-9\-]+"
			/>
			<label class="label">
				<span class="label-text-alt">Post URL: /{data.brand?.slug}/{slug}</span>
			</label>
		</div>

		<!-- Excerpt -->
		<div class="form-control">
			<label class="label" for="excerpt">
				<span class="label-text">Excerpt (Optional)</span>
			</label>
			<textarea
				id="excerpt"
				name="excerpt"
				bind:value={excerpt}
				class="textarea textarea-bordered h-20"
				maxlength="300"
				placeholder="A short summary of your post..."
			></textarea>
			<label class="label">
				<span class="label-text-alt">{excerpt.length}/300 characters</span>
			</label>
		</div>

		<!-- Categories -->
		<div class="form-control">
			<label class="label" for="categories">
				<span class="label-text">Categories (Optional)</span>
			</label>
			<input
				type="text"
				id="categories"
				name="categories"
				bind:value={categories}
				class="input input-bordered"
				placeholder="Sports, Gaming, News"
			/>
			<label class="label">
				<span class="label-text-alt">Separate categories with commas</span>
			</label>
		</div>

		<!-- Content Editor -->
		<div class="form-control">
			<label class="label" for="content">
				<span class="label-text">Content</span>
			</label>
			<TipTapEditor bind:content placeholder="Write your post content..." />
		</div>

		<!-- Action Buttons -->
		<div class="flex gap-4 pt-6 border-t border-base-300">
			<button
				type="submit"
				class="btn btn-primary"
				disabled={loading}
				onclick={(e) => handleSubmit(e, 'published')}
			>
				{#if loading}
					<span class="loading loading-spinner loading-sm"></span>
				{/if}
				Update & Publish
			</button>

			<button
				type="submit"
				class="btn btn-outline"
				disabled={loading}
				onclick={(e) => handleSubmit(e, 'draft')}
			>
				Save as Draft
			</button>

			<a href="/dashboard" class="btn btn-ghost">Cancel</a>
		</div>
	</form>
</div>
