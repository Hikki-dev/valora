/// "just now", "5m ago", "3h ago", "2d ago".
String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 2) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

/// S >= $100, A >= $40, otherwise B.
String valueRank(double v) => v >= 100 ? 'S' : (v >= 40 ? 'A' : 'B');
