<script lang="ts">
	import { supabase } from '$lib/supabase/client';
	import { invalidateAll } from '$app/navigation';
	import imageCompression from 'browser-image-compression';
	import { toast } from '$lib/stores/toast';

	let { userId, userAvatar, username, brandId } = $props<{
		userId: string;
		userAvatar?: string | null;
		username: string;
		brandId?: string | null;
	}>();

	let content = $state('');
	let loading = $state(false);
	let charCount = $derived(content.length);
	let maxChars = 500;

	let imageFile: File | null = $state(null);
	let imagePreview: string | null = $state(null);
	let imageLoading = $state(false);
	let fileInput: HTMLInputElement | null = $state(null);

	async function handleImageSelect(e: Event) {
		const target = e.target as HTMLInputElement;
		const file = target.files?.[0];

		if (!file) return;

		// Validate file type
		if (!file.type.startsWith('image/')) {
			toast.error('Please select an image file');
			return;
		}

		// Validate file size (max 5MB before compression)
		if (file.size > 5 * 1024 * 1024) {
			toast.error('Image must be smaller than 5MB');
			return;
		}

		imageLoading = true;

		try {
			// Compress image
			const options = {
				maxSizeMB: 1,
				maxWidthOrHeight: 1200,
				useWebWorker: true,
				initialQuality: 0.8
			};

			const compressedFile = await imageCompression(file, options);
			imageFile = new File([compressedFile], file.name, {
				type: compressedFile.type,
				lastModified: Date.now()
			});

			// Create preview
			const reader = new FileReader();
			reader.onload = (e) => {
				imagePreview = e.target?.result as string;
			};
			reader.readAsDataURL(imageFile);
		} catch (err) {
			toast.error('Failed to process image');
			imageFile = null;
			imagePreview = null;
		} finally {
			imageLoading = false;
		}
	}

	function removeImage() {
		imageFile = null;
		imagePreview = null;
		if (fileInput) {
			fileInput.value = '';
		}
	}

	async function handleSubmit() {
		if (!content.trim() || charCount > maxChars) return;

		loading = true;

		try {
			let imageUrl: string | null = null;

			// Upload image if selected
			if (imageFile) {
				const fileExt = imageFile.name.split('.').pop();
				const fileName = `${userId}-${Date.now()}.${fileExt}`;
				const filePath = `pulse/${fileName}`;

				const { error: uploadError, data } = await supabase.storage
					.from('profiles')
					.upload(filePath, imageFile, {
						cacheControl: '3600',
						upsert: false
					});

				if (uploadError) {
					throw new Error('Failed to upload image');
				}

				const { data: { publicUrl } } = supabase.storage
					.from('profiles')
					.getPublicUrl(filePath);

				imageUrl = publicUrl;
			}

			const pulseData: any = {
				author_id: userId,
				content: content.trim(),
				image_url: imageUrl
			};

			// Add brand_id if posting as brand
			if (brandId) {
				pulseData.brand_id = brandId;
			}

			const { error: submitError } = await supabase
				.from('pulse_posts')
				.insert(pulseData);

			if (submitError) {
				toast.error(submitError.message);
			} else {
				content = '';
				removeImage();
				toast.success('Pulse posted successfully!');
				await invalidateAll();
			}
		} catch (err) {
			const errorMessage = err instanceof Error ? err.message : 'Failed to post';
			toast.error(errorMessage);
		} finally {
			loading = false;
		}
	}

	function handleKeydown(e: KeyboardEvent) {
		// Submit on Cmd+Enter or Ctrl+Enter
		if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
			e.preventDefault();
			handleSubmit();
		}
	}
</script>

<div class="card bg-base-200 shadow-sm">
	<div class="card-body p-4">
		<div class="flex gap-3">
			<!-- User Avatar -->
			<div class="avatar">
				<div class="w-10 h-10 rounded-full">
					{#if userAvatar}
						<img src={userAvatar} alt={username} class="object-cover" />
					{:else}
						<div class="w-full h-full bg-neutral text-neutral-content flex items-center justify-center">
							<span class="text-sm font-semibold">{username[0].toUpperCase()}</span>
						</div>
					{/if}
				</div>
			</div>

			<!-- Input Area -->
			<div class="flex-1">
				<label for="pulse-textarea" class="sr-only">Write your pulse message</label>
				<textarea
					id="pulse-textarea"
					bind:value={content}
					onkeydown={handleKeydown}
					placeholder="What's on your mind? Share a tip, insight, or quick thought..."
					class="textarea textarea-ghost w-full min-h-[80px] resize-none focus:outline-none p-0 text-base"
					disabled={loading}
					aria-label="Pulse message content"
					aria-describedby="char-count"
				></textarea>

				<!-- Image Preview -->
				{#if imagePreview}
					<div class="relative mt-3 mb-2">
						<img src={imagePreview} alt="Upload preview" class="rounded-lg max-h-64 w-auto" />
						<button
							type="button"
							onclick={removeImage}
							class="btn btn-sm btn-circle btn-error absolute top-2 right-2"
							aria-label="Remove image"
						>
							<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
							</svg>
						</button>
					</div>
				{/if}

				<!-- Actions Row -->
				<div class="flex items-center justify-between mt-2">
					<div class="flex items-center gap-2">
						<!-- Image upload button -->
						<input
							type="file"
							accept="image/*"
							bind:this={fileInput}
							onchange={handleImageSelect}
							class="hidden"
							id="pulse-image-upload"
							disabled={loading || imageLoading}
						/>
						<label for="pulse-image-upload">
							<button
								type="button"
								onclick={() => fileInput?.click()}
								class="btn btn-ghost btn-sm btn-circle"
								aria-label="Add image to pulse"
								disabled={loading || imageLoading || imagePreview !== null}
								title="Add image"
							>
								{#if imageLoading}
									<span class="loading loading-spinner loading-xs"></span>
								{:else}
									<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
									</svg>
								{/if}
							</button>
						</label>
					</div>

					<div class="flex items-center gap-3">
						<!-- Character count -->
						<span
							id="char-count"
							class="text-sm {charCount > maxChars ? 'text-error' : 'opacity-60'}"
							role="status"
							aria-live="polite"
						>
							{charCount}/{maxChars}
						</span>

						<!-- Post button -->
						<button
							type="submit"
							onclick={handleSubmit}
							disabled={loading || !content.trim() || charCount > maxChars}
							class="btn btn-primary btn-sm"
							aria-label="Post pulse"
						>
							{#if loading}
								<span class="loading loading-spinner loading-xs" aria-hidden="true"></span>
								<span class="sr-only">Posting...</span>
							{:else}
								Post
							{/if}
						</button>
					</div>
				</div>
			</div>
		</div>
	</div>
</div>
