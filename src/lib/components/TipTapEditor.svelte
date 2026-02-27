<script lang="ts">
	import { Editor } from '@tiptap/core';
	import StarterKit from '@tiptap/starter-kit';
	import Image from '@tiptap/extension-image';
	import Placeholder from '@tiptap/extension-placeholder';
	import { TextStyle } from '@tiptap/extension-text-style';
	import { Color } from '@tiptap/extension-color';
	import Highlight from '@tiptap/extension-highlight';
	import TextAlign from '@tiptap/extension-text-align';
	import { onMount, onDestroy } from 'svelte';

	let { content = $bindable(), placeholder = 'Start writing...' } = $props();

	let element: HTMLElement;
	let editor = $state<Editor | undefined>();
	let showColorPicker = $state(false);
	let showHighlightPicker = $state(false);

	onMount(() => {
		// Initialize with proper content structure
		let initialContent: any = '';

		if (content) {
			if (typeof content === 'object' && content !== null) {
				// Check if it's a valid TipTap JSON object with type property
				if ('type' in content && content.type === 'doc') {
					initialContent = content;
				}
				// Otherwise treat as empty
			} else if (typeof content === 'string' && content.trim() !== '') {
				initialContent = content;
			}
		}

		editor = new Editor({
			element: element,
			extensions: [
				StarterKit,
				TextStyle,
				Color,
				Highlight.configure({
					multicolor: true
				}),
				TextAlign.configure({
					types: ['heading', 'paragraph']
				}),
				Image,
				Placeholder.configure({
					placeholder
				})
			],
			content: initialContent,
			onUpdate: ({ editor }) => {
				content = editor.getJSON();
			},
			editorProps: {
				attributes: {
					class: 'prose prose-sm sm:prose lg:prose-lg xl:prose-xl focus:outline-none min-h-[300px] p-4'
				}
			}
		});
	});

	onDestroy(() => {
		editor?.destroy();
	});

	function toggleBold() {
		editor?.chain().focus().toggleBold().run();
	}

	function toggleItalic() {
		editor?.chain().focus().toggleItalic().run();
	}

	function toggleUnderline() {
		editor?.chain().focus().toggleUnderline().run();
	}

	function toggleStrike() {
		editor?.chain().focus().toggleStrike().run();
	}

	function toggleHeading(level: 1 | 2 | 3) {
		editor?.chain().focus().toggleHeading({ level }).run();
	}

	function setParagraph() {
		editor?.chain().focus().setParagraph().run();
	}

	function toggleBulletList() {
		editor?.chain().focus().toggleBulletList().run();
	}

	function toggleOrderedList() {
		editor?.chain().focus().toggleOrderedList().run();
	}

	function toggleBlockquote() {
		editor?.chain().focus().toggleBlockquote().run();
	}

	function setTextAlign(alignment: 'left' | 'center' | 'right' | 'justify') {
		editor?.chain().focus().setTextAlign(alignment).run();
	}

	function setTextColor(color: string) {
		editor?.chain().focus().setColor(color).run();
		showColorPicker = false;
	}

	function setHighlight(color: string) {
		editor?.chain().focus().toggleHighlight({ color }).run();
		showHighlightPicker = false;
	}

	function removeHighlight() {
		editor?.chain().focus().unsetHighlight().run();
		showHighlightPicker = false;
	}

	function setLink() {
		const url = window.prompt('Enter URL');
		if (url) {
			editor?.chain().focus().setLink({ href: url }).run();
		}
	}

	function removeLink() {
		editor?.chain().focus().unsetLink().run();
	}

	function addImage() {
		const url = window.prompt('Enter image URL');
		if (url) {
			editor?.chain().focus().setImage({ src: url }).run();
		}
	}

	function clearFormatting() {
		editor?.chain().focus().clearNodes().unsetAllMarks().run();
	}

	const colors = [
		'#000000', '#ffffff', '#ff0000', '#00ff00', '#0000ff',
		'#ffff00', '#ff00ff', '#00ffff', '#ff6600', '#9900ff'
	];

	const highlightColors = [
		'#ffff00', '#00ff00', '#00ffff', '#ff00ff',
		'#ff6600', '#ffd700', '#90ee90', '#add8e6'
	];
</script>

<div class="border border-base-300 rounded-lg overflow-hidden bg-base-100">
	<!-- Toolbar -->
	<div class="flex flex-wrap gap-1 p-2 bg-base-200 border-b border-base-300">
		<!-- Text Style -->
		<button
			type="button"
			class="btn btn-sm btn-ghost"
			onclick={toggleBold}
			class:btn-active={editor?.isActive('bold')}
			title="Bold (Ctrl+B)"
		>
			<strong>B</strong>
		</button>

		<button
			type="button"
			class="btn btn-sm btn-ghost"
			onclick={toggleItalic}
			class:btn-active={editor?.isActive('italic')}
			title="Italic (Ctrl+I)"
		>
			<em>I</em>
		</button>

		<button
			type="button"
			class="btn btn-sm btn-ghost"
			onclick={toggleUnderline}
			class:btn-active={editor?.isActive('underline')}
			title="Underline (Ctrl+U)"
		>
			<span class="underline">U</span>
		</button>

		<button
			type="button"
			class="btn btn-sm btn-ghost"
			onclick={toggleStrike}
			class:btn-active={editor?.isActive('strike')}
			title="Strikethrough"
		>
			<s>S</s>
		</button>

		<div class="divider divider-horizontal mx-0"></div>

		<!-- Headings -->
		<button
			type="button"
			class="btn btn-sm btn-ghost"
			onclick={setParagraph}
			class:btn-active={editor?.isActive('paragraph')}
			title="Paragraph"
		>
			P
		</button>

		<button
			type="button"
			class="btn btn-sm btn-ghost"
			onclick={() => toggleHeading(1)}
			class:btn-active={editor?.isActive('heading', { level: 1 })}
			title="Heading 1"
		>
			H1
		</button>

		<button
			type="button"
			class="btn btn-sm btn-ghost"
			onclick={() => toggleHeading(2)}
			class:btn-active={editor?.isActive('heading', { level: 2 })}
			title="Heading 2"
		>
			H2
		</button>

		<button
			type="button"
			class="btn btn-sm btn-ghost"
			onclick={() => toggleHeading(3)}
			class:btn-active={editor?.isActive('heading', { level: 3 })}
			title="Heading 3"
		>
			H3
		</button>

		<div class="divider divider-horizontal mx-0"></div>

		<!-- Lists -->
		<button
			type="button"
			class="btn btn-sm btn-ghost"
			onclick={toggleBulletList}
			class:btn-active={editor?.isActive('bulletList')}
			title="Bullet List"
		>
			• List
		</button>

		<button
			type="button"
			class="btn btn-sm btn-ghost"
			onclick={toggleOrderedList}
			class:btn-active={editor?.isActive('orderedList')}
			title="Numbered List"
		>
			1. List
		</button>

		<button
			type="button"
			class="btn btn-sm btn-ghost"
			onclick={toggleBlockquote}
			class:btn-active={editor?.isActive('blockquote')}
			title="Quote"
		>
			❝❞
		</button>

		<div class="divider divider-horizontal mx-0"></div>

		<!-- Alignment -->
		<button
			type="button"
			class="btn btn-sm btn-ghost"
			onclick={() => setTextAlign('left')}
			class:btn-active={editor?.isActive({ textAlign: 'left' })}
			title="Align Left"
		>
			⬅
		</button>

		<button
			type="button"
			class="btn btn-sm btn-ghost"
			onclick={() => setTextAlign('center')}
			class:btn-active={editor?.isActive({ textAlign: 'center' })}
			title="Align Center"
		>
			↔
		</button>

		<button
			type="button"
			class="btn btn-sm btn-ghost"
			onclick={() => setTextAlign('right')}
			class:btn-active={editor?.isActive({ textAlign: 'right' })}
			title="Align Right"
		>
			➡
		</button>

		<div class="divider divider-horizontal mx-0"></div>

		<!-- Text Color -->
		<div class="dropdown">
			<button
				type="button"
				class="btn btn-sm btn-ghost"
				onclick={() => (showColorPicker = !showColorPicker)}
				title="Text Color"
			>
				A
				<div class="w-4 h-1 bg-primary"></div>
			</button>
			{#if showColorPicker}
				<div class="dropdown-content z-[1] menu p-2 shadow bg-base-200 rounded-box w-52">
					<div class="grid grid-cols-5 gap-1 p-2">
						{#each colors as color}
							<button
								type="button"
								class="w-8 h-8 rounded border border-base-300"
								style="background-color: {color}"
								onclick={() => setTextColor(color)}
								aria-label="Set text color to {color}"
							></button>
						{/each}
					</div>
				</div>
			{/if}
		</div>

		<!-- Highlight -->
		<div class="dropdown">
			<button
				type="button"
				class="btn btn-sm btn-ghost"
				onclick={() => (showHighlightPicker = !showHighlightPicker)}
				class:btn-active={editor?.isActive('highlight')}
				title="Highlight"
			>
				🖍
			</button>
			{#if showHighlightPicker}
				<div class="dropdown-content z-[1] menu p-2 shadow bg-base-200 rounded-box w-44">
					<div class="grid grid-cols-4 gap-1 p-2">
						{#each highlightColors as color}
							<button
								type="button"
								class="w-8 h-8 rounded border border-base-300"
								style="background-color: {color}"
								onclick={() => setHighlight(color)}
								aria-label="Set highlight color to {color}"
							></button>
						{/each}
					</div>
					<button type="button" class="btn btn-sm btn-ghost" onclick={removeHighlight}>
						Remove
					</button>
				</div>
			{/if}
		</div>

		<div class="divider divider-horizontal mx-0"></div>

		<!-- Link & Image -->
		<button
			type="button"
			class="btn btn-sm btn-ghost"
			onclick={setLink}
			class:btn-active={editor?.isActive('link')}
			title="Add Link"
		>
			🔗
		</button>

		{#if editor?.isActive('link')}
			<button type="button" class="btn btn-sm btn-ghost" onclick={removeLink} title="Remove Link">
				🔗✕
			</button>
		{/if}

		<button type="button" class="btn btn-sm btn-ghost" onclick={addImage} title="Add Image">
			🖼
		</button>

		<div class="divider divider-horizontal mx-0"></div>

		<!-- Clear Formatting -->
		<button
			type="button"
			class="btn btn-sm btn-ghost"
			onclick={clearFormatting}
			title="Clear Formatting"
		>
			✕
		</button>
	</div>

	<!-- Editor -->
	<div bind:this={element}></div>
</div>

<style>
	:global(.ProseMirror p.is-editor-empty:first-child::before) {
		color: #adb5bd;
		content: attr(data-placeholder);
		float: left;
		height: 0;
		pointer-events: none;
	}

	:global(.ProseMirror:focus) {
		outline: none;
	}
</style>
