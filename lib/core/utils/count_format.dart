/// Lightweight grouping for large follower counts (no intl dependency).
String formatFollowerCount(double value) {
  final n = value.round();
  final s = n.toString();
  if (s.length <= 3) return s;
  final buf = StringBuffer();
  var first = s.length % 3;
  if (first == 0) first = 3;
  buf.write(s.substring(0, first));
  for (var i = first; i < s.length; i += 3) {
    buf.write(',');
    buf.write(s.substring(i, i + 3));
  }
  return buf.toString();
}
