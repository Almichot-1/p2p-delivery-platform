String formatTimeAgo(DateTime dateTime, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final diff = ref.difference(dateTime);

  if (diff.inSeconds < 0) return 'just now';
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 2) return '1m ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 2) return '1h ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 2) return '1d ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';

  final months = (diff.inDays / 30).floor();
  if (months < 2) return '1mo ago';
  if (months < 12) return '${months}mo ago';

  final years = (months / 12).floor();
  if (years < 2) return '1y ago';
  return '${years}y ago';
}
