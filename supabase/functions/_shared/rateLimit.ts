export async function checkRateLimit(supabase: any, userId: string, limit = 60) {
  const windowStart = new Date()
  windowStart.setMinutes(0, 0, 0) // round to current hour

  const { data, error } = await supabase.rpc('increment_rate_limit', {
    p_user_id: userId,
    p_window_start: windowStart.toISOString(),
    p_limit: limit
  })
  
  // rpc might return is_limited as a boolean or part of a list
  const isLimited = Array.isArray(data) ? data[0]?.is_limited : data?.is_limited;

  if (error || isLimited) {
    throw new Error('Rate limit exceeded. Max 60 price fetches per hour.')
  }
}
