import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OColor {
  BuildContext? _context;

  // Font
  TextStyle textStyle({
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
  }) =>
      GoogleFonts.inter(
        color: color,
        backgroundColor: backgroundColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        textBaseline: textBaseline,
        height: height,
        locale: locale,
      );

  // Light Theme Colors
  static const Color _lPrimary = Color(0xFF7D5DEC);
  static const Color _lPrimaryContainer = Color(0xFF6148B9);
  static const Color _lSecondary = Color(0xff212121);
  static const Color _lSecondaryContainer = Color(0xff131313);
  static const Color _lBackground = Color(0xfffafafa);
  static const Color _lBackgroundContainer = Color(0xfff2f2f2);
  static const Color _lError = Color(0xffB00020);

  // Dark Theme Colors
  static const Color _dPrimary = Color(0xFF7D5DEC);
  static const Color _dPrimaryContainer = Color(0xFF6148B9);
  static const Color _dSecondary = Color(0xfffafafa);
  static const Color _dSecondaryContainer = Color(0xfff2f2f2);
  static const Color _dBackground = Color(0xFF151515);
  static const Color _dBackgroundContainer = Color(0xFF111111);
  static const Color _dError = Color(0xffcf6679);
  static const Color _dSecondaryOnBackground = Color(0xFF838383);
  static const Color _dSecondaryContainerOnBackground = Color(0xFF181818);
  static const Color _dCardOnBackground = Color(0xFF1E1E1E);

  Color get lPrimary => _lPrimary;
  Color get lPrimaryContainer => _lPrimaryContainer;
  Color get lSecondary => _lSecondary;
  Color get lSecondaryContainer => _lSecondaryContainer;
  Color get lBackground => _lBackground;
  Color get lBackgroundContainer => _lBackgroundContainer;
  Color get lError => _lError;

  Color get dPrimary => _dPrimary;
  Color get dPrimaryContainer => _dPrimaryContainer;
  Color get dSecondary => _dSecondary;
  Color get dSecondaryContainer => _dSecondaryContainer;
  Color get dBackground => _dBackground;
  Color get dBackgroundContainer => _dBackgroundContainer;
  Color get dError => _dError;
  Color get dSecondaryOnBackground => _dSecondaryOnBackground;
  Color get dSecondaryContainerOnBackground => _dSecondaryContainerOnBackground;
  Color get dCardOnBackground => _dCardOnBackground;

  Color get primary {
    if (_context == null) {
      return dPrimary;
    }
    return Theme.of(_context!).brightness == Brightness.light ? lPrimary : dPrimary;
  }

  Color get primaryContainer {
    if (_context == null) {
      return dPrimaryContainer;
    }
    return Theme.of(_context!).brightness == Brightness.light ? lPrimaryContainer : dPrimaryContainer;
  }

  Color get secondary {
    if (_context == null) {
      return dSecondary;
    }
    return Theme.of(_context!).brightness == Brightness.light ? lSecondary : dSecondary;
  }

  Color get secondaryContainer {
    if (_context == null) {
      return dSecondaryContainer;
    }
    return Theme.of(_context!).brightness == Brightness.light ? lSecondaryContainer : dSecondaryContainer;
  }

  Color get background {
    if (_context == null) {
      return dBackground;
    }
    return Theme.of(_context!).brightness == Brightness.light ? lBackground : dBackground;
  }

  Color get backgroundContainer {
    if (_context == null) {
      return dBackgroundContainer;
    }
    return Theme.of(_context!).brightness == Brightness.light ? lBackgroundContainer : dBackgroundContainer;
  }

  Color get error {
    if (_context == null) {
      return dError;
    }
    return Theme.of(_context!).brightness == Brightness.light ? lError : dError;
  }

  Color get secondaryContainerOnBackground {
    if (_context == null) {
      return _dSecondaryOnBackground;
    }
    if (Theme.of(_context!).brightness == Brightness.light) {
      throw UnimplementedError();
    } else {
      return dSecondaryContainerOnBackground;
    }
  }

  Color get secondaryOnBackground {
    if (_context == null) {
      return _dSecondaryOnBackground;
    }
    if (Theme.of(_context!).brightness == Brightness.light) {
      throw UnimplementedError();
    } else {
      return dSecondaryOnBackground;
    }
  }

  Color get cardOnBackground {
    if (_context == null) {
      return _dCardOnBackground;
    }
    if (Theme.of(_context!).brightness == Brightness.light) {
      throw UnimplementedError();
    } else {
      return dCardOnBackground;
    }
  }

  // Constructors

  OColor();

  OColor.withContext(BuildContext context) {
    _context = context;
  }
}
