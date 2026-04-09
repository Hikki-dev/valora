export async function checkRateLimit(
  supabase: any,
  userId: string,
  limitPerHour = 60
) {
  const windowStart = new Date()
  windowStart.setMinutes(0, 0, 0)

  const { data, error } = await supabase.rpc('increment_rate_limit', {
    p_user_id: userId,
    p_window_start: windowStart.toISOString(),
    p_limit: limitPerHour,
  })

  if (error) throw new Error('Rate limit check failed')
  if (data?.[0]?.is_limited) {
    throw new Error('Rate limit exceeded — max 60 price fetches per hour')
  }
}
