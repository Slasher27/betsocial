// BetChat Database Types — v2 (Users first, Brands created separately)

export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type PostType = 'article' | 'promotion' | 'news' | 'update' | 'tip';
export type PostStatus = 'draft' | 'published' | 'archived';
export type ReactionType = 'like' | 'fire' | 'money' | 'trophy';
export type SubscriptionTier = 'free' | 'paid';
export type BrandRole = 'owner' | 'admin' | 'editor' | 'viewer';
export type NotificationType = 'new_post' | 'comment_reply' | 'new_follower' | 'promotion' | 'mention';

export interface Database {
	public: {
		Tables: {
			profiles: {
				Row: {
					id: string;
					username: string;
					display_name: string | null;
					avatar_url: string | null;
					bio: string | null;
					country_code: string | null;
					betting_interests: string[];
					created_at: string;
					updated_at: string;
				};
				Insert: {
					id: string;
					username: string;
					display_name?: string | null;
					avatar_url?: string | null;
					bio?: string | null;
					country_code?: string | null;
					betting_interests?: string[];
					created_at?: string;
					updated_at?: string;
				};
				Update: {
					id?: string;
					username?: string;
					display_name?: string | null;
					avatar_url?: string | null;
					bio?: string | null;
					country_code?: string | null;
					betting_interests?: string[];
					created_at?: string;
					updated_at?: string;
				};
			};
			brand_profiles: {
				Row: {
					id: string;
					owner_id: string;
					brand_name: string;
					slug: string;
					logo_url: string | null;
					banner_url: string | null;
					description: string | null;
					website_url: string | null;
					license_info: string | null;
					is_verified: boolean;
					categories: string[];
					target_jurisdictions: string[];
					stripe_account_id: string | null;
					follower_count: number;
					created_at: string;
					updated_at: string;
				};
				Insert: {
					owner_id: string;
					brand_name: string;
					slug: string;
					logo_url?: string | null;
					banner_url?: string | null;
					description?: string | null;
					website_url?: string | null;
					license_info?: string | null;
					categories?: string[];
					target_jurisdictions?: string[];
				};
				Update: {
					brand_name?: string;
					logo_url?: string | null;
					banner_url?: string | null;
					description?: string | null;
					website_url?: string | null;
					license_info?: string | null;
					categories?: string[];
					target_jurisdictions?: string[];
				};
			};
			brand_members: {
				Row: {
					brand_id: string;
					user_id: string;
					role: BrandRole;
					invited_by: string | null;
					created_at: string;
				};
				Insert: {
					brand_id: string;
					user_id: string;
					role?: BrandRole;
					invited_by?: string | null;
				};
				Update: {
					role?: BrandRole;
				};
			};
			posts: {
				Row: {
					id: string;
					brand_id: string;
					author_id: string;
					title: string;
					slug: string;
					content: Json;
					excerpt: string | null;
					cover_image_url: string | null;
					post_type: PostType;
					status: PostStatus;
					categories: string[];
					target_jurisdictions: string[];
					is_pinned: boolean;
					is_paywalled: boolean;
					like_count: number;
					comment_count: number;
					share_count: number;
					published_at: string | null;
					created_at: string;
					updated_at: string;
				};
				Insert: {
					brand_id: string;
					author_id: string;
					title: string;
					slug: string;
					content?: Json;
					excerpt?: string | null;
					cover_image_url?: string | null;
					post_type?: PostType;
					status?: PostStatus;
					categories?: string[];
					target_jurisdictions?: string[];
					is_pinned?: boolean;
					is_paywalled?: boolean;
					published_at?: string | null;
				};
				Update: {
					title?: string;
					slug?: string;
					content?: Json;
					excerpt?: string | null;
					cover_image_url?: string | null;
					post_type?: PostType;
					status?: PostStatus;
					categories?: string[];
					target_jurisdictions?: string[];
					is_pinned?: boolean;
					is_paywalled?: boolean;
					published_at?: string | null;
				};
			};
			promotions: {
				Row: {
					id: string;
					promo_code: string | null;
					offer_details: string | null;
					terms_conditions: string | null;
					min_deposit: number | null;
					wagering_requirements: string | null;
					expires_at: string | null;
					destination_url: string | null;
					is_exclusive: boolean;
				};
				Insert: {
					id: string;
					promo_code?: string | null;
					offer_details?: string | null;
					terms_conditions?: string | null;
					min_deposit?: number | null;
					wagering_requirements?: string | null;
					expires_at?: string | null;
					destination_url?: string | null;
					is_exclusive?: boolean;
				};
				Update: {
					promo_code?: string | null;
					offer_details?: string | null;
					terms_conditions?: string | null;
					min_deposit?: number | null;
					wagering_requirements?: string | null;
					expires_at?: string | null;
					destination_url?: string | null;
					is_exclusive?: boolean;
				};
			};
			follows: {
				Row: {
					follower_id: string;
					brand_id: string;
					subscription_tier: SubscriptionTier;
					created_at: string;
				};
				Insert: {
					follower_id: string;
					brand_id: string;
					subscription_tier?: SubscriptionTier;
				};
				Update: {
					subscription_tier?: SubscriptionTier;
				};
			};
			comments: {
				Row: {
					id: string;
					post_id: string;
					author_id: string;
					parent_id: string | null;
					content: string;
					is_hidden: boolean;
					like_count: number;
					created_at: string;
					updated_at: string;
				};
				Insert: {
					post_id: string;
					author_id: string;
					parent_id?: string | null;
					content: string;
				};
				Update: {
					content?: string;
					is_hidden?: boolean;
				};
			};
			reactions: {
				Row: {
					user_id: string;
					target_type: string;
					target_id: string;
					reaction_type: ReactionType;
					created_at: string;
				};
				Insert: {
					user_id: string;
					target_type: string;
					target_id: string;
					reaction_type?: ReactionType;
				};
				Update: {
					reaction_type?: ReactionType;
				};
			};
			bookmarks: {
				Row: {
					user_id: string;
					post_id: string;
					created_at: string;
				};
				Insert: {
					user_id: string;
					post_id: string;
				};
				Update: Record<string, never>;
			};
			notifications: {
				Row: {
					id: string;
					user_id: string;
					type: NotificationType;
					data: Json;
					is_read: boolean;
					created_at: string;
				};
				Insert: {
					user_id: string;
					type: NotificationType;
					data?: Json;
				};
				Update: {
					is_read?: boolean;
				};
			};
		};
		Views: Record<string, never>;
		Functions: Record<string, never>;
		Enums: Record<string, never>;
	};
}
