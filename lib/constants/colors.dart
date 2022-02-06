import 'package:flutter/material.dart';

class OColor {
  BuildContext? _context;

  // Light Theme Colors
  static const Color _lPrimary = Color(0xFF7D5DEC);
  static const Color _lPrimaryVariant = Color(0xFF6148B9);
  static const Color _lSecondary = Color(0xff212121);
  static const Color _lSecondaryVariant = Color(0xff131313);
  static const Color _lBackground = Color(0xfffafafa);
  static const Color _lBackgroundVariant = Color(0xfff2f2f2);
  static const Color _lError = Color(0xffB00020);

  // Dark Theme Colors
  static const Color _dPrimary = Color(0xFF7D5DEC);
  static const Color _dPrimaryVariant = Color(0xFF6148B9);
  static const Color _dSecondary = Color(0xfffafafa);
  static const Color _dSecondaryVariant = Color(0xfff2f2f2);
  static const Color _dBackground = Color(0xFF151515);
  static const Color _dBackgroundVariant = Color(0xFF111111);
  static const Color _dError = Color(0xffcf6679);

  Color get lPrimary => _lPrimary;
  Color get lPrimaryVariant => _lPrimaryVariant;
  Color get lSecondary => _lSecondary;
  Color get lSecondaryVariant => _lSecondaryVariant;
  Color get lBackground => _lBackground;
  Color get lBackgroundVariant => _lBackgroundVariant;
  Color get lError => _lError;

  Color get dPrimary => _dPrimary;
  Color get dPrimaryVariant => _dPrimaryVariant;
  Color get dSecondary => _dSecondary;
  Color get dSecondaryVariant => _dSecondaryVariant;
  Color get dBackground => _dBackground;
  Color get dBackgroundVariant => _dBackgroundVariant;
  Color get dError => _dError;

  Color get primary {
    if (_context == null) {
      return dPrimary;
    }
    return Theme.of(_context!).brightness == Brightness.light
        ? lPrimary
        : dPrimary;
  }

  Color get primaryVariant {
    if (_context == null) {
      return dPrimaryVariant;
    }
    return Theme.of(_context!).brightness == Brightness.light
        ? lPrimaryVariant
        : dPrimaryVariant;
  }

  Color get secondary {
    if (_context == null) {
      return dSecondary;
    }
    return Theme.of(_context!).brightness == Brightness.light
        ? lSecondary
        : dSecondary;
  }

  Color get secondaryVariant {
    if (_context == null) {
      return dSecondaryVariant;
    }
    return Theme.of(_context!).brightness == Brightness.light
        ? lSecondaryVariant
        : dSecondaryVariant;
  }

  Color get background {
    if (_context == null) {
      return dBackground;
    }
    return Theme.of(_context!).brightness == Brightness.light
        ? lBackground
        : dBackground;
  }

  Color get backgroundVariant {
    if (_context == null) {
      return dBackgroundVariant;
    }
    return Theme.of(_context!).brightness == Brightness.light
        ? lBackgroundVariant
        : dBackgroundVariant;
  }

  Color get error {
    if (_context == null) {
      return dError;
    }
    return Theme.of(_context!).brightness == Brightness.light ? lError : dError;
  }

  // Constructors

  OColor();

  OColor.withContext(BuildContext context) {
    _context = context;
  }
}
