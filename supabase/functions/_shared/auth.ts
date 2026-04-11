import { createClient } from '@supabase/supabase-js'

/**
 * Verifies the user session using the incoming request's Authorization header.
 * By initializing the client with the user's JWT, we enforce RLS and validate
 * the session in a single, robust step.
 */
export async function verifyUser(req: Request) {
  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    throw new Error('Missing or invalid Authorization header')
  }

  const token = authHeader.replace('Bearer ', '')

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
    const errorMsg = error?.message ?? 'Invalid session';
    console.error(`[Auth] Verification failed: ${errorMsg}`);
    console.debug(`[Auth] URL: ${Deno.env.get('SUPABASE_URL')}`);
    console.debug(`[Auth] Token prefix: ${token.substring(0, 10)}...`);
    throw new Error(`Unauthorized: ${errorMsg}`);
  }

  return { user, supabase }
}
