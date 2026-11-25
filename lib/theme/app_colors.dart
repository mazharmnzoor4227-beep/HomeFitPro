import 'package:flutter/material.dart';

@immutable
class GymColors extends ThemeExtension<GymColors> {
  const GymColors({
    required this.pageBg,
    required this.bg,
    required this.bgRaised,
    required this.bgRaised2,
    required this.border,
    required this.navBg,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.ember,
    required this.emberDeep,
    required this.onEmber,
    required this.emberSoft,
    required this.emberShadow,
    required this.accent,
    required this.accentSoft,
    required this.brass,
    required this.sage,
    required this.sageSoft,
    required this.mutedFill,
    required this.heatEmpty,
    required this.info,
    required this.warn,
    required this.danger,
  });

  final Color pageBg;
  final Color bg;
  final Color bgRaised;
  final Color bgRaised2;
  final Color border;
  final Color navBg;
  final Color text;
  final Color textSecondary;
  final Color textTertiary;
  final Color ember;
  final Color emberDeep;
  final Color onEmber;
  final Color emberSoft;
  final Color emberShadow;
  final Color accent;
  final Color accentSoft;
  final Color brass;
  final Color sage;
  final Color sageSoft;
  final Color mutedFill;
  final Color heatEmpty;
  final Color info;
  final Color warn;
  final Color danger;

  static const dark = GymColors(
    pageBg: Color(0xFF181E27),
    bg: Color(0xFF1E2530),
    bgRaised: Color(0xFF252D3A),
    bgRaised2: Color(0xFF2A3340),
    border: Color(0xFF3A4554),
    navBg: Color(0xE61E2530),
    text: Color(0xFFF0F3F7),
    textSecondary: Color(0xFF8A98AA),
    textTertiary: Color(0xFF6B7888),
    ember: Color(0xFFFF7A2F),
    emberDeep: Color(0xFFE85E12),
    onEmber: Color(0xFF1E2530),
    emberSoft: Color(0x29FF7A2F),
    emberShadow: Color(0x66000000),
    accent: Color(0xFFFF7A2F),
    accentSoft: Color(0x29FF7A2F),
    brass: Color(0xFF8A98AA),
    sage: Color(0xFF6E8BA8),
    sageSoft: Color(0x296E8BA8),
    mutedFill: Color(0xFF222A35),
    heatEmpty: Color(0xFF1A212B),
    info: Color(0xFF7EC4E8),
    warn: Color(0xFFE89A4A),
    danger: Color(0xFFFF6B5A),
  );

  static const amoled = GymColors(
    pageBg: Color(0xFF000000),
    bg: Color(0xFF000000),
    bgRaised: Color(0xFF161B22),
    bgRaised2: Color(0xFF1E2530),
    border: Color(0xFF2A3340),
    navBg: Color(0xE6000000),
    text: Color(0xFFF0F3F7),
    textSecondary: Color(0xFF8A98AA),
    textTertiary: Color(0xFF6B7888),
    ember: Color(0xFFFF7A2F),
    emberDeep: Color(0xFFE85E12),
    onEmber: Color(0xFF1E2530),
    emberSoft: Color(0x29FF7A2F),
    emberShadow: Color(0x80000000),
    accent: Color(0xFFFF7A2F),
    accentSoft: Color(0x29FF7A2F),
    brass: Color(0xFF8A98AA),
    sage: Color(0xFF6E8BA8),
    sageSoft: Color(0x296E8BA8),
    mutedFill: Color(0xFF12161C),
    heatEmpty: Color(0xFF0C0F14),
    info: Color(0xFF7EC4E8),
    warn: Color(0xFFE89A4A),
    danger: Color(0xFFFF6B5A),
  );

  static const light = GymColors(
    pageBg: Color(0xFFDCE2EA),
    bg: Color(0xFFEFF2F6),
    bgRaised: Color(0xFFF7F9FB),
    bgRaised2: Color(0xFFDCE2EA),
    border: Color(0xFFC5CDD8),
    navBg: Color(0xF2F0F3F7),
    text: Color(0xFF1E2530),
    textSecondary: Color(0xFF5B6B80),
    textTertiary: Color(0xFF8A98AA),
    ember: Color(0xFFFF7A2F),
    emberDeep: Color(0xFFE85E12),
    onEmber: Color(0xFFFFFFFF),
    emberSoft: Color(0x33FF7A2F),
    emberShadow: Color(0x1A1E2530),
    accent: Color(0xFFFF7A2F),
    accentSoft: Color(0x26FF7A2F),
    brass: Color(0xFF5B6B80),
    sage: Color(0xFF4A6278),
    sageSoft: Color(0x1F4A6278),
    mutedFill: Color(0xFFE6EAF0),
    heatEmpty: Color(0xFFE8ECF1),
    info: Color(0xFF2B6B9E),
    warn: Color(0xFFC46A1A),
    danger: Color(0xFFD1433B),
  );

  @override
  GymColors copyWith({
    Color? pageBg,
    Color? bg,
    Color? bgRaised,
    Color? bgRaised2,
    Color? border,
    Color? navBg,
    Color? text,
    Color? textSecondary,
    Color? textTertiary,
    Color? ember,
    Color? emberDeep,
    Color? onEmber,
    Color? emberSoft,
    Color? emberShadow,
    Color? accent,
    Color? accentSoft,
    Color? brass,
    Color? sage,
    Color? sageSoft,
    Color? mutedFill,
    Color? heatEmpty,
    Color? info,
    Color? warn,
    Color? danger,
  }) {
    return GymColors(
      pageBg: pageBg ?? this.pageBg,
      bg: bg ?? this.bg,
      bgRaised: bgRaised ?? this.bgRaised,
      bgRaised2: bgRaised2 ?? this.bgRaised2,
      border: border ?? this.border,
      navBg: navBg ?? this.navBg,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      ember: ember ?? this.ember,
      emberDeep: emberDeep ?? this.emberDeep,
      onEmber: onEmber ?? this.onEmber,
      emberSoft: emberSoft ?? this.emberSoft,
      emberShadow: emberShadow ?? this.emberShadow,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      brass: brass ?? this.brass,
      sage: sage ?? this.sage,
      sageSoft: sageSoft ?? this.sageSoft,
      mutedFill: mutedFill ?? this.mutedFill,
      heatEmpty: heatEmpty ?? this.heatEmpty,
      info: info ?? this.info,
      warn: warn ?? this.warn,
      danger: danger ?? this.danger,
    );
  }

  @override
  GymColors lerp(GymColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return GymColors(
      pageBg: c(pageBg, other.pageBg),
      bg: c(bg, other.bg),
      bgRaised: c(bgRaised, other.bgRaised),
      bgRaised2: c(bgRaised2, other.bgRaised2),
      border: c(border, other.border),
      navBg: c(navBg, other.navBg),
      text: c(text, other.text),
      textSecondary: c(textSecondary, other.textSecondary),
      textTertiary: c(textTertiary, other.textTertiary),
      ember: c(ember, other.ember),
      emberDeep: c(emberDeep, other.emberDeep),
      onEmber: c(onEmber, other.onEmber),
      emberSoft: c(emberSoft, other.emberSoft),
      emberShadow: c(emberShadow, other.emberShadow),
      accent: c(accent, other.accent),
      accentSoft: c(accentSoft, other.accentSoft),
      brass: c(brass, other.brass),
      sage: c(sage, other.sage),
      sageSoft: c(sageSoft, other.sageSoft),
      mutedFill: c(mutedFill, other.mutedFill),
      heatEmpty: c(heatEmpty, other.heatEmpty),
      info: c(info, other.info),
      warn: c(warn, other.warn),
      danger: c(danger, other.danger),
    );
  }
}

extension GymColorsX on BuildContext {
  GymColors get gc => Theme.of(this).extension<GymColors>()!;
}
