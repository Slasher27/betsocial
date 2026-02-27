<script lang="ts">
	import type { PageData } from './$types';
	import TipTapEditor from '$lib/components/TipTapEditor.svelte';
	import { enhance } from '$app/forms';

	let { data, form } = $props<{ data: PageData; form?: any }>();

	let title = $state('');
	let slug = $state('');
	let excerpt = $state('');
	let content = $state({});
	let categories = $state('');
	let saving = $state(false);

	function generateSlug() {
		slug = title
			.toLowerCase()
			.replace(/[^a-z0-9]+/g, '-')
			.replace(/^-|-$/g, '');
	}
</script>

<svelte:head>
	<title>New Post | BetChat</title>
</svelte:head>

<div class="container mx-auto px-4 py-8 max-w-4xl">
	<div class="mb-8">
		<h1 class="text-3xl font-bold mb-2">Create New Post</h1>
		<div class="text-sm breadcrumbs">
			<ul>
				<li><a href="/dashboard{data.brand ? `?brand=${data.brand.slug}` : ''}">Dashboard</a></li>
				<li>New Post</li>
			</ul>
		</div>
		{#if data.brand}
			<div class="alert alert-info mt-4">
				<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
				</svg>
				<span>Posting as <strong>{data.brand.brand_name}</strong></span>
			</div>
		{/if}
	</div>

	{#if form?.error}
		<div class="alert alert-error mb-6">
			<svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
			</svg>
			<span>{form.error}</span>
		</div>
	{/if}

	<form
		method="POST"
		use:enhance={() => {
			saving = true;
			return async ({ update }) => {
				await update();
				saving = false;
			};
		}}
	>
		<div class="space-y-6">
			<!-- Title -->
			<div class="form-control">
				<label class="label" for="title">
					<span class="label-text font-semibold">Title</span>
					<span class="label-text-alt text-error">Required</span>
				</label>
				<input
					id="title"
					name="title"
					type="text"
					placeholder="Enter post title"
					class="input input-bordered input-lg"
					bind:value={title}
					onblur={generateSlug}
					required
				/>
			</div>

			<!-- Slug -->
			<div class="form-control">
				<label class="label" for="slug">
					<span class="label-text font-semibold">URL Slug</span>
					<span class="label-text-alt text-error">Required</span>
				</label>
				<input
					id="slug"
					name="slug"
					type="text"
					placeholder="post-url-slug"
					class="input input-bordered"
					bind:value={slug}
					required
				/>
				{#if slug}
					<div class="label">
						<span class="label-text-alt">
							{#if data.brand}
								Post will be at: betchat.com/{data.brand.slug}/{slug}
							{:else}
								Post will be at: betchat.com/u/{data.profile?.username}/{slug}
							{/if}
						</span>
					</div>
				{/if}
			</div>

			<!-- Hidden fields for context -->
			{#if data.brand}
				<input type="hidden" name="brand_id" value={data.brand.id} />
				<input type="hidden" name="brand_slug" value={data.brand.slug} />
			{/if}

			<!-- Excerpt -->
			<div class="form-control">
				<label class="label" for="excerpt">
					<span class="label-text font-semibold">Excerpt</span>
					<span class="label-text-alt">Optional</span>
				</label>
				<textarea
					id="excerpt"
					name="excerpt"
					placeholder="Brief summary of your post (shown in feeds)"
					class="textarea textarea-bordered h-24"
					bind:value={excerpt}
					maxlength="300"
				></textarea>
				<div class="label">
					<span class="label-text-alt">{excerpt.length}/300 characters</span>
				</div>
			</div>

			<!-- Categories -->
			<div class="form-control">
				<label class="label" for="categories">
					<span class="label-text font-semibold">Categories</span>
					<span class="label-text-alt">Optional</span>
				</label>
				<input
					id="categories"
					name="categories"
					type="text"
					placeholder="betting, sports, tips (comma-separated)"
					class="input input-bordered"
					bind:value={categories}
				/>
			</div>

			<!-- Content Editor -->
			<div class="form-control">
				<div class="label">
					<span class="label-text font-semibold">Content</span>
					<span class="label-text-alt text-error">Required</span>
				</div>
				<TipTapEditor bind:content placeholder="Write your post content here..." />
				<input type="hidden" name="content" value={JSON.stringify(content)} />
			</div>

			<!-- Actions -->
			<div class="flex gap-4 justify-end pt-6 border-t border-base-300">
				<a href="/dashboard{data.brand ? `?brand=${data.brand.slug}` : ''}" class="btn btn-ghost">Cancel</a>
				<button
					type="submit"
					name="status"
					value="draft"
					class="btn btn-outline"
					disabled={saving || !title || !slug}
				>
					{saving ? 'Saving...' : 'Save as Draft'}
				</button>
				<button
					type="submit"
					name="status"
					value="published"
					class="btn btn-primary"
					disabled={saving || !title || !slug}
				>
					{saving ? 'Publishing...' : 'Publish'}
				</button>
			</div>
		</div>
	</form>
</div>
