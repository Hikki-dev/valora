import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

export async function verifyUser(req: Request) {
  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    throw new Error('Missing or invalid Authorization header')
  }

  const internalSecret = req.headers.get('X-Internal-Secret')
  const isInternal = internalSecret === Deno.env.get('VALORA_INTERNAL_KEY')

  // Initialize Supabase client
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    {
      global: {
        headers: { Authorization: authHeader },
      },
    }
  )

  const {
    data: { user },
    error,
  } = await supabase.auth.getUser()

  if (!user && !isInternal) {
    console.error('Auth verification failed:', error?.message ?? 'No user found')
    throw new Error(`Unauthorized: ${error?.message ?? 'Invalid session'}`)
  }

  // If we are internal but token failed, we might still need a user_id.
  // We can extract it from the JWT payload without strictly verifying the signature
  // if the internal handshake has already proven this request is from our app.
  let finalUser = user
  if (!finalUser && isInternal) {
    try {
      const token = authHeader.replace('Bearer ', '')
      const [_header, payload, _sig] = token.split('.')
      const decodedPayload = JSON.parse(atob(payload))
      finalUser = { id: decodedPayload.sub } as any
      console.log('Using internal secret with extracted user_id:', finalUser?.id)
    } catch (e) {
      console.error('Failed to extract user_id even with internal secret:', e)
      throw new Error('Unauthorized: Cannot identify user')
    }
  }

  return { user: finalUser!, supabase }
}
