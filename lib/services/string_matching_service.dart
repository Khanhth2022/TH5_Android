class StringMatchingService {
  static int levenshteinDistance(String a, String b) {
    final left = _normalize(a);
    final right = _normalize(b);

    if (left == right) {
      return 0;
    }
    if (left.isEmpty) {
      return right.length;
    }
    if (right.isEmpty) {
      return left.length;
    }

    final rows = left.length + 1;
    final cols = right.length + 1;
    final matrix = List<List<int>>.generate(
      rows,
      (_) => List<int>.filled(cols, 0),
    );

    for (var i = 0; i < rows; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j < cols; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i < rows; i++) {
      for (var j = 1; j < cols; j++) {
        final cost = left[i - 1] == right[j - 1] ? 0 : 1;
        final deletion = matrix[i - 1][j] + 1;
        final insertion = matrix[i][j - 1] + 1;
        final substitution = matrix[i - 1][j - 1] + cost;

        matrix[i][j] = _min3(deletion, insertion, substitution);
      }
    }

    return matrix[left.length][right.length];
  }

  static double normalizedSimilarity(String a, String b) {
    final left = _normalize(a);
    final right = _normalize(b);
    if (left.isEmpty && right.isEmpty) {
      return 1;
    }
    final maxLength = left.length > right.length ? left.length : right.length;
    if (maxLength == 0) {
      return 1;
    }
    final distance = levenshteinDistance(left, right);
    return (1 - (distance / maxLength)).clamp(0, 1);
  }

  static bool isPotentialDuplicate(
    String candidate,
    Iterable<String> existingNames, {
    double threshold = 0.9,
  }) {
    return firstDuplicateMatch(
          candidate,
          existingNames,
          threshold: threshold,
        ) !=
        null;
  }

  static String? firstDuplicateMatch(
    String candidate,
    Iterable<String> existingNames, {
    double threshold = 0.9,
  }) {
    final normalizedCandidate = _normalize(candidate);
    if (normalizedCandidate.isEmpty) {
      return null;
    }

    for (final name in existingNames) {
      final similarity = normalizedSimilarity(normalizedCandidate, name);
      if (similarity >= threshold) {
        return name;
      }
    }

    return null;
  }

  static String _normalize(String value) {
    final compacted = value.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    return compacted;
  }

  static int _min3(int a, int b, int c) {
    var min = a;
    if (b < min) {
      min = b;
    }
    if (c < min) {
      min = c;
    }
    return min;
  }
}
