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
  // This ensures that all subsequent DB queries are scoped to this user via RLS.
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
    throw new Error(`Unauthorized: ${error?.message ?? 'Invalid session'}`)
  }

  return { user, supabase }
}
