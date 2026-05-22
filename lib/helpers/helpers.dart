String buildInitials(String text, {int maxLength = 4, String fallback = ''}) {
  final initials = text
      .trim()
      .split(RegExp(r'\s+'))
      .where((segment) => segment.isNotEmpty)
      .map((segment) => segment[0].toUpperCase())
      .join();

  if (initials.isEmpty) {
    return fallback;
  }

  return initials.length > maxLength
      ? initials.substring(0, maxLength)
      : initials;
}
