// Per-function buckets so a burst of searches cannot exhaust the price-fetch budget.
export async function checkRateLimit(
  supabase: any,
  _userId: string,
  limitPerHour = 60,
  bucket = 'default'
) {
  const windowStart = new Date()
  windowStart.setMinutes(0, 0, 0)

  // The RPC derives the user from the caller's JWT (auth.uid()); it ignores any
  // client-supplied user id so one user cannot burn another user's quota.
  const { data, error } = await supabase.rpc('increment_rate_limit', {
    p_window_start: windowStart.toISOString(),
    p_limit: limitPerHour,
    p_bucket: bucket,
  })

  if (error) throw new Error('Rate limit check failed')
  if (data?.[0]?.is_limited) {
    throw new Error(`Rate limit exceeded — max ${limitPerHour} requests per hour`)
  }
}
