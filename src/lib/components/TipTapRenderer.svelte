<script lang="ts">
	import { Editor } from '@tiptap/core';
	import StarterKit from '@tiptap/starter-kit';
	import Image from '@tiptap/extension-image';
	import { TextStyle } from '@tiptap/extension-text-style';
	import { Color } from '@tiptap/extension-color';
	import Highlight from '@tiptap/extension-highlight';
	import TextAlign from '@tiptap/extension-text-align';
	import { onMount, onDestroy } from 'svelte';

	let { content } = $props<{ content: any }>();

	let element: HTMLElement;
	let editor: Editor | undefined;

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
				Image
			],
			content: initialContent,
			editable: false,
			editorProps: {
				attributes: {
					class: 'prose prose-lg max-w-none focus:outline-none'
				}
			}
		});
	});

	onDestroy(() => {
		editor?.destroy();
	});
</script>

<div bind:this={element}></div>

<style>
	:global(.ProseMirror) {
		outline: none;
	}

	:global(.ProseMirror img) {
		max-width: 100%;
		height: auto;
		border-radius: 0.5rem;
	}

	:global(.ProseMirror p) {
		margin-bottom: 1em;
	}

	:global(.ProseMirror h1) {
		font-size: 2em;
		font-weight: bold;
		margin-top: 1em;
		margin-bottom: 0.5em;
	}

	:global(.ProseMirror h2) {
		font-size: 1.5em;
		font-weight: bold;
		margin-top: 1em;
		margin-bottom: 0.5em;
	}

	:global(.ProseMirror h3) {
		font-size: 1.25em;
		font-weight: bold;
		margin-top: 1em;
		margin-bottom: 0.5em;
	}

	:global(.ProseMirror ul),
	:global(.ProseMirror ol) {
		padding-left: 1.5em;
		margin-bottom: 1em;
	}

	:global(.ProseMirror li) {
		margin-bottom: 0.25em;
	}

	:global(.ProseMirror u) {
		text-decoration: underline;
	}

	:global(.ProseMirror mark) {
		border-radius: 0.125rem;
		padding: 0.125rem 0.25rem;
	}

	:global(.ProseMirror blockquote) {
		border-left: 3px solid currentColor;
		padding-left: 1rem;
		font-style: italic;
		margin: 1em 0;
		opacity: 0.8;
	}

	:global(.ProseMirror [style*="text-align: center"]) {
		text-align: center;
	}

	:global(.ProseMirror [style*="text-align: right"]) {
		text-align: right;
	}

	:global(.ProseMirror [style*="text-align: justify"]) {
		text-align: justify;
	}
</style>
