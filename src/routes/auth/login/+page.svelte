<script lang="ts">
	import { supabase } from '$lib/supabase/client';
	import { goto, invalidate } from '$app/navigation';

	let email = $state('');
	let password = $state('');
	let error = $state('');
	let loading = $state(false);

	async function handleLogin(e: Event) {
		e.preventDefault();
		loading = true;
		error = '';

		const { error: err } = await supabase.auth.signInWithPassword({
			email,
			password
		});

		if (err) {
			error = err.message;
			loading = false;
		} else {
			await invalidate('supabase:auth');
			goto('/feed');
		}
	}
</script>

<div class="hero min-h-[80vh]">
	<div class="hero-content flex-col">
		<div class="text-center mb-4">
			<h1 class="text-4xl font-bold">Login to BetChat</h1>
			<p class="py-4">Welcome back! Sign in to continue.</p>
		</div>
		<div class="card bg-base-200 w-full max-w-md shadow-2xl">
			<form class="card-body" onsubmit={handleLogin}>
				{#if error}
					<div class="alert alert-error mb-4">
						<span>{error}</span>
					</div>
				{/if}

				<div class="form-control w-full">
					<label for="email" class="label">
						<span class="label-text">Email</span>
					</label>
					<input
						id="email"
						type="email"
						placeholder="email@example.com"
						class="input input-bordered w-full"
						bind:value={email}
						required
					/>
				</div>

				<div class="form-control w-full">
					<label for="password" class="label">
						<span class="label-text">Password</span>
					</label>
					<input
						id="password"
						type="password"
						placeholder="password"
						class="input input-bordered w-full"
						bind:value={password}
						required
					/>
					<div class="label">
						<span class="label-text-alt"></span>
						<a href="/auth/forgot-password" class="label-text-alt link link-hover"
							>Forgot password?</a
						>
					</div>
				</div>

				<div class="form-control mt-6">
					<button type="submit" class="btn btn-primary" disabled={loading}>
						{loading ? 'Logging in...' : 'Login'}
					</button>
				</div>

				<div class="text-center mt-4">
					<p class="text-sm">
						Don't have an account?
						<a href="/auth/signup" class="link link-primary">Sign up</a>
					</p>
				</div>
			</form>
		</div>
	</div>
</div>
