<script lang="ts">
	import { supabase } from '$lib/supabase/client';

	let email = $state('');
	let password = $state('');
	let username = $state('');
	let displayName = $state('');
	let loading = $state(false);
	let error = $state('');
	let success = $state(false);
	let usernameError = $state('');
	let checkingUsername = $state(false);
	let emailError = $state('');
	let checkingEmail = $state(false);

	// Debounce timers
	let usernameCheckTimer: ReturnType<typeof setTimeout> | null = null;
	let emailCheckTimer: ReturnType<typeof setTimeout> | null = null;

	// Check if username is available
	async function checkUsernameAvailability(usernameValue: string) {
		if (!usernameValue || usernameValue.length < 3) {
			usernameError = '';
			return;
		}

		checkingUsername = true;
		usernameError = '';

		try {
			const { data, error: queryError } = await supabase
				.from('profiles')
				.select('username')
				.eq('username', usernameValue.toLowerCase())
				.maybeSingle();

			if (queryError) {
				console.error('Error checking username:', queryError);
				// Don't show error to user, just log it
				checkingUsername = false;
				return;
			}

			if (data) {
				usernameError = 'This username is already taken';
			} else {
				usernameError = '';
			}
		} catch (err) {
			console.error('Unexpected error checking username:', err);
		} finally {
			checkingUsername = false;
		}
	}

	// Debounced username check
	function handleUsernameInput() {
		if (usernameCheckTimer) {
			clearTimeout(usernameCheckTimer);
		}

		usernameCheckTimer = setTimeout(() => {
			checkUsernameAvailability(username);
		}, 500); // Wait 500ms after user stops typing
	}

	// Check if email is available
	async function checkEmailAvailability(emailValue: string) {
		if (!emailValue || !emailValue.includes('@')) {
			emailError = '';
			return;
		}

		checkingEmail = true;
		emailError = '';

		try {
			// Check if email exists in auth.users by trying to trigger password reset
			// A cleaner way: query profiles if they have email stored, or use Supabase Admin API
			// For now, we'll skip this check as auth.users is not directly queryable
			// The server will return an error if email is taken

			// Alternative: Check if a profile exists with metadata containing this email
			// This is a limitation - we can't directly query auth.users from client
			checkingEmail = false;
			emailError = '';
		} catch (err) {
			console.error('Unexpected error checking email:', err);
			checkingEmail = false;
		}
	}

	// Debounced email check
	function handleEmailInput() {
		if (emailCheckTimer) {
			clearTimeout(emailCheckTimer);
		}

		emailCheckTimer = setTimeout(() => {
			checkEmailAvailability(email);
		}, 500);
	}

	// Watch username changes
	$effect(() => {
		if (username) {
			handleUsernameInput();
		}
	});

	// Watch email changes
	$effect(() => {
		if (email) {
			handleEmailInput();
		}
	});

	async function handleSignup(e: Event) {
		e.preventDefault();
		loading = true;
		error = '';

		// Final username check before submission
		if (usernameError) {
			error = usernameError;
			loading = false;
			return;
		}

		// Validate username format
		const usernameRegex = /^[a-zA-Z0-9_-]+$/;
		if (!usernameRegex.test(username)) {
			error = 'Username can only contain letters, numbers, hyphens, and underscores';
			loading = false;
			return;
		}

		if (username.length < 3) {
			error = 'Username must be at least 3 characters long';
			loading = false;
			return;
		}

		try {
			const { data, error: authError } = await supabase.auth.signUp({
				email,
				password,
				options: {
					data: {
						username: username.toLowerCase(),
						display_name: displayName
					},
					emailRedirectTo: `${window.location.origin}/auth/callback`
				}
			});

			if (authError) {
				console.error('Signup error:', authError);

				// Provide user-friendly error messages
				if (authError.message.includes('User already registered')) {
					error = 'This email address is already registered. Try logging in instead.';
				} else if (authError.message.includes('Database error')) {
					error = 'Server error. Please ensure the database trigger is set up correctly. Check the console for details.';
				} else {
					error = authError.message;
				}

				loading = false;
				return;
			}

			console.log('Signup successful:', data);
			success = true;
			loading = false;
		} catch (err) {
			console.error('Unexpected signup error:', err);
			error = err instanceof Error ? err.message : 'An unexpected error occurred';
			loading = false;
		}
	}
</script>

<svelte:head>
	<title>Sign Up — BetChat</title>
</svelte:head>

<div class="min-h-[80vh] flex items-center justify-center px-4">
	<div class="card w-full max-w-md bg-base-200 shadow-xl">
		<div class="card-body">
			<h1 class="text-2xl font-bold text-center mb-2">Join BetChat</h1>
			<p class="text-center text-base-content/60 mb-6">Create your free account</p>

			{#if success}
				<div class="alert alert-success">
					<div>
						<h3 class="font-bold">Check your email!</h3>
						<p class="text-sm">We've sent a confirmation link to <strong>{email}</strong>. Click it to activate your account.</p>
					</div>
				</div>
			{:else}
				{#if error}
					<div class="alert alert-error mb-4">
						<span>{error}</span>
					</div>
				{/if}

				<form onsubmit={handleSignup} class="space-y-4">
					<div class="form-control">
						<label class="label" for="displayName">
							<span class="label-text">Display Name</span>
						</label>
						<input
							id="displayName"
							type="text"
							placeholder="John Smith"
							class="input input-bordered w-full"
							bind:value={displayName}
							required
						/>
					</div>

					<div class="form-control">
						<label class="label" for="username">
							<span class="label-text">Username</span>
						</label>
						<div class="relative">
							<input
								id="username"
								type="text"
								placeholder="johnsmith"
								class="input input-bordered w-full"
								class:input-error={usernameError}
								class:input-success={username.length >= 3 && !usernameError && !checkingUsername}
								bind:value={username}
								required
								pattern="[a-zA-Z0-9_\-]+"
								minlength="3"
							/>
							{#if checkingUsername}
								<span class="absolute right-3 top-1/2 -translate-y-1/2 loading loading-spinner loading-sm"></span>
							{/if}
						</div>
						<div class="label">
							{#if usernameError}
								<span class="label-text-alt text-error">{usernameError}</span>
							{:else if username.length >= 3 && !checkingUsername}
								<span class="label-text-alt text-success">Username available!</span>
							{:else}
								<span class="label-text-alt text-base-content/50">Letters, numbers, hyphens, underscores only (min 3 chars)</span>
							{/if}
						</div>
					</div>

					<div class="form-control">
						<label class="label" for="email">
							<span class="label-text">Email</span>
						</label>
						<input
							id="email"
							type="email"
							placeholder="you@example.com"
							class="input input-bordered w-full"
							bind:value={email}
							required
						/>
					</div>

					<div class="form-control">
						<label class="label" for="password">
							<span class="label-text">Password</span>
						</label>
						<input
							id="password"
							type="password"
							placeholder="••••••••"
							class="input input-bordered w-full"
							bind:value={password}
							required
							minlength="8"
						/>
						<div class="label">
							<span class="label-text-alt text-base-content/50">Minimum 8 characters</span>
						</div>
					</div>

					<button type="submit" class="btn btn-primary w-full" disabled={loading}>
						{#if loading}
							<span class="loading loading-spinner loading-sm"></span>
						{/if}
						Create Account
					</button>
				</form>

				<div class="divider">OR</div>

				<div class="text-center text-sm">
					<p>
						Already have an account?
						<a href="/auth/login" class="link link-primary">Log in</a>
					</p>
				</div>
			{/if}
		</div>
	</div>
</div>
