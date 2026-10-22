import { createClient } from '@supabase/supabase-js'

/**
 * Verifies the user session using the incoming request's Authorization header.
 * By initializing the client with the user's JWT, we enforce RLS and validate
 * the session in a single, robust step.
 */
export async function verifyUser(req: Request) {
  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    throw new Error('Unauthorized: missing or invalid Authorization header')
  }

  // Initialize client with User's JWT (not service role)
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    {
      global: { headers: { Authorization: authHeader } }
    }
  )

  // Verify token and get user object
  const { data: { user }, error } = await supabase.auth.getUser()

  if (error || !user) {
    // Log the reason server-side only. (The previous version also decoded and
    // logged JWT claims — issuer, subject, expiry — which does not belong in logs.)
    console.error(`[Auth] Verification failed: ${error?.message ?? 'Invalid session'}`)
    throw new Error('Unauthorized')
  }

  return { user, supabase }
}
