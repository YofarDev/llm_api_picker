extension StringsUtils on String {
  String safeSubstring(int start, int end) {
    if (start < 0 || end < 0) {
      return this;
    }
    if (start > end) {
      return this;
    }
    if (end > length) {
      return this;
    }
    return substring(start, end);
  }
}
