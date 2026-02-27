/**
 * BetChat UI Design System Constants
 *
 * This file defines consistent design tokens that map to DaisyUI utility classes.
 * Use these constants to maintain visual consistency across the application.
 *
 * DaisyUI Documentation: https://daisyui.com/
 * Lucide Icons: https://lucide.dev/
 */

// =============================================================================
// CONTAINER WIDTHS
// =============================================================================

export const CONTAINER_WIDTHS = {
  // Content-focused pages (feed, posts, articles)
  content: 'max-w-3xl', // 768px

  // Settings and form pages
  forms: 'max-w-5xl', // 1024px

  // Dashboard and analytics pages
  dashboard: 'max-w-7xl', // 1280px

  // Landing pages with full-width sections
  landing: 'max-w-full',

  // Modal content
  modal: {
    sm: 'max-w-md', // 448px
    md: 'max-w-lg', // 512px
    lg: 'max-w-2xl', // 672px
  }
} as const;

// =============================================================================
// SPACING SCALE (DaisyUI TailwindCSS)
// =============================================================================

export const SPACING = {
  // Page-level spacing
  page: {
    padding: 'px-4 py-6 md:py-8', // Horizontal padding + responsive vertical
    marginBottom: 'mb-8',
  },

  // Section spacing
  section: {
    marginBottom: 'mb-6',
    gap: 'gap-6',
  },

  // Card spacing
  card: {
    padding: 'p-6',
    gap: 'gap-4',
  },

  // Component spacing
  component: {
    tight: 'gap-2',
    normal: 'gap-4',
    relaxed: 'gap-6',
  },

  // Element spacing
  element: {
    xs: 'p-2',
    sm: 'p-3',
    md: 'p-4',
    lg: 'p-6',
    xl: 'p-8',
  }
} as const;

// =============================================================================
// TYPOGRAPHY (DaisyUI text utilities)
// =============================================================================

export const TYPOGRAPHY = {
  // Page titles (H1)
  pageTitle: 'text-3xl font-bold',

  // Section titles (H2)
  sectionTitle: 'text-2xl font-bold',

  // Subsection titles (H3)
  subsectionTitle: 'text-xl font-semibold',

  // Card titles (H4)
  cardTitle: 'text-lg font-semibold',

  // Body text
  body: 'text-base',
  bodySmall: 'text-sm',

  // Captions and helper text
  caption: 'text-xs opacity-70',

  // Links
  link: 'link link-primary',
  linkHover: 'hover:underline',

  // Muted text
  muted: 'opacity-70',
  mutedLight: 'opacity-50',
} as const;

// =============================================================================
// BUTTON SIZES & STYLES (DaisyUI btn classes)
// =============================================================================

export const BUTTON = {
  // Size variants
  size: {
    xs: 'btn-xs',
    sm: 'btn-sm',
    md: '', // Default size
    lg: 'btn-lg',
  },

  // Style variants (DaisyUI button types)
  variant: {
    primary: 'btn-primary',
    secondary: 'btn-secondary',
    accent: 'btn-accent',
    ghost: 'btn-ghost',
    link: 'btn-link',
    outline: 'btn-outline',
  },

  // Color variants
  color: {
    success: 'btn-success',
    warning: 'btn-warning',
    error: 'btn-error',
    info: 'btn-info',
  },

  // Shape variants
  shape: {
    circle: 'btn-circle',
    square: 'btn-square',
  },

  // Context-specific button styles
  context: {
    // Primary Call-to-Action
    primaryCTA: 'btn btn-primary',

    // Secondary actions
    secondary: 'btn btn-outline',

    // Icon-only buttons
    iconOnly: 'btn btn-ghost btn-circle btn-sm',

    // Inline text actions
    inlineAction: 'btn btn-ghost btn-xs',

    // Danger/destructive actions
    danger: 'btn btn-error btn-outline',
  }
} as const;

// =============================================================================
// CARD SHADOWS (DaisyUI shadow utilities)
// =============================================================================

export const SHADOW = {
  // Card shadows
  card: 'shadow-sm', // Subtle shadow for cards

  // Elevated components (dropdowns, modals)
  elevated: 'shadow-lg',

  // Prominent modals/dialogs
  modal: 'shadow-xl',

  // No shadow (for nested or inline cards)
  none: 'shadow-none',
} as const;

// =============================================================================
// AVATAR SIZES
// =============================================================================

export const AVATAR = {
  size: {
    xs: 'w-6 h-6',
    sm: 'w-8 h-8',
    md: 'w-10 h-10',
    lg: 'w-12 h-12',
    xl: 'w-16 h-16',
    '2xl': 'w-24 h-24',
  }
} as const;

// =============================================================================
// ICON SIZES (for Lucide icons)
// =============================================================================

export const ICON = {
  size: {
    xs: 'h-3 w-3',
    sm: 'h-4 w-4',
    md: 'h-5 w-5',
    lg: 'h-6 w-6',
    xl: 'h-8 w-8',
    '2xl': 'h-12 w-12',
  },

  // Context-specific icon sizing
  context: {
    button: 'h-5 w-5',
    buttonSmall: 'h-4 w-4',
    navigation: 'h-5 w-5',
    alert: 'h-6 w-6',
    hero: 'h-12 w-12',
  }
} as const;

// =============================================================================
// BADGE/TAG STYLES (DaisyUI badge classes)
// =============================================================================

export const BADGE = {
  // Size variants
  size: {
    sm: 'badge-sm',
    md: '', // Default
    lg: 'badge-lg',
  },

  // Color variants
  color: {
    primary: 'badge-primary',
    secondary: 'badge-secondary',
    accent: 'badge-accent',
    ghost: 'badge-ghost',
    success: 'badge-success',
    warning: 'badge-warning',
    error: 'badge-error',
    info: 'badge-info',
  },

  // Context-specific badge styles
  context: {
    // Post status badges
    status: 'badge',

    // Role badges (team members)
    role: 'badge badge-primary badge-lg',

    // Count badges (notifications, comments)
    count: 'badge badge-ghost badge-sm',

    // Category tags
    category: 'badge badge-outline badge-sm',
  }
} as const;

// =============================================================================
// LOADING STATES
// =============================================================================

export const LOADING = {
  spinner: {
    xs: 'loading loading-spinner loading-xs',
    sm: 'loading loading-spinner loading-sm',
    md: 'loading loading-spinner loading-md',
    lg: 'loading loading-spinner loading-lg',
  },

  dots: 'loading loading-dots',
  ring: 'loading loading-ring',
  ball: 'loading loading-ball',
} as const;

// =============================================================================
// ALERT STYLES (DaisyUI alert classes)
// =============================================================================

export const ALERT = {
  variant: {
    info: 'alert alert-info',
    success: 'alert alert-success',
    warning: 'alert alert-warning',
    error: 'alert alert-error',
  }
} as const;

// =============================================================================
// TRANSITIONS & ANIMATIONS
// =============================================================================

export const TRANSITION = {
  // Standard transitions
  default: 'transition-all duration-200 ease-in-out',
  colors: 'transition-colors duration-200',
  fast: 'transition-all duration-150',
  slow: 'transition-all duration-300',

  // Hover effects
  hover: {
    scale: 'hover:scale-105 transition-transform duration-200',
    opacity: 'hover:opacity-80 transition-opacity duration-200',
  }
} as const;

// =============================================================================
// DROPDOWN/MENU STYLES
// =============================================================================

export const DROPDOWN = {
  menu: 'menu dropdown-content mt-3 z-[50] p-2 shadow-lg bg-base-200 rounded-box',

  width: {
    compact: 'w-48',
    normal: 'w-56',
    wide: 'w-64',
  }
} as const;

// =============================================================================
// Z-INDEX LAYERS
// =============================================================================

export const Z_INDEX = {
  dropdown: 'z-[50]',
  modal: 'z-[100]',
  toast: 'z-[200]',
  tooltip: 'z-[300]',
} as const;

// =============================================================================
// BREAKPOINT HELPERS (for responsive design)
// =============================================================================

export const BREAKPOINTS = {
  // TailwindCSS breakpoints
  sm: '640px',
  md: '768px',
  lg: '1024px',
  xl: '1280px',
  '2xl': '1536px',
} as const;

// =============================================================================
// FORM FIELD STYLES
// =============================================================================

export const FORM = {
  input: 'input input-bordered w-full',
  textarea: 'textarea textarea-bordered w-full',
  select: 'select select-bordered w-full',
  checkbox: 'checkbox',
  radio: 'radio',
  toggle: 'toggle',

  size: {
    xs: 'input-xs',
    sm: 'input-sm',
    md: '', // Default
    lg: 'input-lg',
  }
} as const;

// =============================================================================
// UTILITY HELPERS
// =============================================================================

/**
 * Combines multiple class strings, filtering out falsy values
 */
export function cn(...classes: (string | false | null | undefined)[]): string {
  return classes.filter(Boolean).join(' ');
}

/**
 * Helper to get responsive container classes
 */
export function getContainerClasses(variant: keyof typeof CONTAINER_WIDTHS): string {
  return cn('container mx-auto', SPACING.page.padding, CONTAINER_WIDTHS[variant]);
}

/**
 * Helper to get button classes
 */
export function getButtonClasses(
  variant: keyof typeof BUTTON.variant = 'primary',
  size: keyof typeof BUTTON.size = 'md'
): string {
  return cn('btn', BUTTON.variant[variant], BUTTON.size[size]);
}
