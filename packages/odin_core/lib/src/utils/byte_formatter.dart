import 'dart:math';

String formatBytes(int bytes, [int decimals = 2]) {
  if (bytes <= 0) return '0 B';
  const suffixes = <String>[
    'B',
    'KB',
    'MB',
    'GB',
    'TB',
    'PB',
    'EB',
    'ZB',
    'YB',
  ];
  final index = (log(bytes) / log(1024)).floor();
  final fixed = bytes / pow(1024, index);
  return '${fixed.toStringAsFixed(decimals)} ${suffixes[index]}';
}
