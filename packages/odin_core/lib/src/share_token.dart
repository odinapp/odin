final class ParsedShareToken {
  const ParsedShareToken({required this.fileCode});

  final String fileCode;
}

const _tokenRegex = r'^[A-Za-z0-9]{8}$';

ParsedShareToken parseShareToken(String input) {
  final code = input.trim();
  if (code.isEmpty) {
    throw const FormatException('Token is empty');
  }
  if (!RegExp(_tokenRegex).hasMatch(code)) {
    throw const FormatException('Token must be exactly 8 letters/numbers.');
  }
  return ParsedShareToken(fileCode: code);
}
