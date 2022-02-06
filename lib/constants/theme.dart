import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odin/constants/colors.dart';
import 'package:odin/services/locator.dart';

class OTheme {
  static final OColor _color = locator<OColor>();

  final lightTheme = FlexThemeData.light(
    colors: FlexSchemeColor(
      primary: _color.lPrimary,
      primaryVariant: _color.lPrimaryVariant,
      secondary: _color.lSecondary,
      secondaryVariant: _color.lSecondaryVariant,
      appBarColor: _color.lSecondaryVariant,
      error: _color.lError,
    ),
    surfaceMode: FlexSurfaceMode.highSurfaceLowScaffold,
    blendLevel: 18,
    appBarStyle: FlexAppBarStyle.background,
    appBarOpacity: 1,
    appBarElevation: 1,
    transparentStatusBar: true,
    tabBarStyle: FlexTabBarStyle.forBackground,
    tooltipsMatchBackground: true,
    swapColors: false,
    lightIsWhite: true,
    useSubThemes: true,
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    fontFamily: GoogleFonts.inter().fontFamily,
    subThemesData: const FlexSubThemesData(
      useTextTheme: true,
      defaultRadius: 8,
      fabUseShape: true,
      interactionEffects: true,
      bottomNavigationBarElevation: 1,
      bottomNavigationBarOpacity: 1,
      navigationBarOpacity: 1,
      navigationBarMutedUnselectedText: true,
      navigationBarMutedUnselectedIcon: true,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      inputDecoratorUnfocusedHasBorder: false,
      inputDecoratorSchemeColor: SchemeColor.primary,
      blendOnColors: true,
      blendTextTheme: true,
      popupMenuOpacity: 0.95,
    ),
  );

  final darkTheme = FlexThemeData.dark(
    colors: FlexSchemeColor(
      primary: _color.dPrimary,
      primaryVariant: _color.dPrimaryVariant,
      secondary: _color.dSecondary,
      secondaryVariant: _color.dSecondaryVariant,
      appBarColor: _color.dSecondaryVariant,
      error: _color.dError,
    ),
    surfaceMode: FlexSurfaceMode.highSurfaceLowScaffold,
    blendLevel: 18,
    appBarStyle: FlexAppBarStyle.background,
    appBarOpacity: 1,
    appBarElevation: 1,
    transparentStatusBar: true,
    tabBarStyle: FlexTabBarStyle.forBackground,
    tooltipsMatchBackground: true,
    swapColors: false,
    darkIsTrueBlack: true,
    useSubThemes: true,
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    fontFamily: GoogleFonts.inter().fontFamily,
    subThemesData: const FlexSubThemesData(
      useTextTheme: true,
      defaultRadius: 8,
      fabUseShape: true,
      interactionEffects: true,
      bottomNavigationBarElevation: 1,
      bottomNavigationBarOpacity: 1,
      navigationBarOpacity: 1,
      navigationBarMutedUnselectedText: true,
      navigationBarMutedUnselectedIcon: true,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      inputDecoratorUnfocusedHasBorder: false,
      inputDecoratorSchemeColor: SchemeColor.primary,
      blendOnColors: true,
      blendTextTheme: true,
      popupMenuOpacity: 0.95,
    ),
  );
}
