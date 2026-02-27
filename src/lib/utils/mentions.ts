import type { SupabaseClient } from '@supabase/supabase-js';

export interface ParsedMention {
	username: string;
	type: 'user' | 'brand';
	id: string;
}

/**
 * Extract all @mentions from text and resolve them to user/brand IDs
 */
export async function parseMentions(
	text: string,
	supabase: SupabaseClient
): Promise<ParsedMention[]> {
	// Extract all @mentions from the text (including hyphens)
	const mentionRegex = /@([\w-]+)/g;
	const matches = Array.from(text.matchAll(mentionRegex));
	const uniqueUsernames = [...new Set(matches.map((m) => m[1]))];

	if (uniqueUsernames.length === 0) {
		return [];
	}

	const mentions: ParsedMention[] = [];

	// Look up users
	const { data: users } = await supabase
		.from('profiles')
		.select('id, username')
		.in('username', uniqueUsernames);

	if (users) {
		mentions.push(
			...users.map((u) => ({
				username: u.username,
				type: 'user' as const,
				id: u.id
			}))
		);
	}

	// Look up brands
	const { data: brands } = await supabase
		.from('brand_profiles')
		.select('id, slug')
		.in('slug', uniqueUsernames);

	if (brands) {
		mentions.push(
			...brands.map((b) => ({
				username: b.slug,
				type: 'brand' as const,
				id: b.id
			}))
		);
	}

	return mentions;
}

/**
 * Render text with @mentions as clickable HTML links
 * Optionally pass the parsed mentions to render proper links to brands vs users
 */
export function renderMentions(text: string, mentions?: ParsedMention[]): string {
	const mentionRegex = /@([\w-]+)/g;

	return text.replace(mentionRegex, (match, username) => {
		// If we have mention data, use it to determine the proper link
		if (mentions) {
			const mention = mentions.find((m) => m.username === username);
			if (mention) {
				const href = mention.type === 'brand' ? `/${username}` : `/u/${username}`;
				return `<a href="${href}" class="text-primary hover:underline font-semibold">@${username}</a>`;
			}
		}

		// Default to user profile link
		return `<a href="/u/${username}" class="text-primary hover:underline font-semibold">@${username}</a>`;
	});
}

/**
 * Create mention records in the database
 */
export async function createMentions(
	commentId: string,
	mentions: ParsedMention[],
	supabase: SupabaseClient
): Promise<void> {
	if (mentions.length === 0) return;

	const mentionRecords = mentions.map((m) => ({
		comment_id: commentId,
		mentioned_user_id: m.type === 'user' ? m.id : null,
		mentioned_brand_id: m.type === 'brand' ? m.id : null
	}));

	const { error } = await supabase.from('mentions').insert(mentionRecords);

	if (error) {
		console.error('Error creating mentions:', error);
	}
}
