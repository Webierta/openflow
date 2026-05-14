import 'dart:math';

class FormatBytes {
  static String show(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    var i = (log(bytes) / log(1024)).floor();
    // Stay within the range of available suffixes
    i = i >= suffixes.length ? suffixes.length - 1 : i;
    final size = bytes / pow(1024, i);
    // Format number based on size
    if (size >= 100) {
      // No decimal places for large numbers
      return '${size.toStringAsFixed(0)} ${suffixes[i]}';
    } else if (size >= 10) {
      // One decimal place for medium numbers
      return '${size.toStringAsFixed(1)} ${suffixes[i]}';
    } else {
      // Two decimal places for small numbers
      return '${size.toStringAsFixed(2)} ${suffixes[i]}';
    }
  }
}
