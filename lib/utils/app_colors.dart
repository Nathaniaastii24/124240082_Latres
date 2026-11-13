import 'package:flutter/material.dart';

/// Palet warna diambil dari referensi UI "Habitz":
/// latar lavender, tombol ungu, kartu pastel (mint, pink, kuning, biru).
class AppColors {
  // Background
  static const Color background = Color(0xFFFFFFFF); // putih
  static const Color backgroundDeep = Color(0xFFEDE6FD); // blob lavender muda
  static const Color surface = Color(0xFFFFFFFF);
  static const Color fieldFill = Color(0xFFF3F3F8);

  // Brand
  static const Color purple = Color(0xFF6B4FD8); // tombol utama
  static const Color purpleDark = Color(0xFF5A3FC4);
  static const Color purpleSoft = Color(0xFFD9CCFA);
  static const Color ink = Color(0xFF1B1B2F); // teks judul

  // Pastel (kartu / tile)
  static const Color mint = Color(0xFFA9EBD3);
  static const Color pink = Color(0xFFFFB9D3);
  static const Color pinkSoft = Color(0xFFFFD3E3);
  static const Color yellow = Color(0xFFFFE9A8);
  static const Color blue = Color(0xFFBDD5FB);
  static const Color peach = Color(0xFFFFC9B5);
  static const Color grey = Color(0xFFDADDE3);

  // Primary
  static const Color primary = purple;
  static const Color secondary = pink;
  static const Color accent = yellow;

  // Text
  static const Color text = ink;
  static const Color secondaryText = Color(0xFF4A4A60);
  static const Color hintText = Color(0xFF9A9AAE);

  // Status
  static const Color alive = Color(0xFF3DBE94);
  static const Color dead = Color(0xFFF2677A);
  static const Color unknown = Color(0xFF9A9AAE);

  // Alias lama (supaya file lain tidak error)
  static const Color glaucous = purple;
  static const Color powderBlue = background;
  static const Color vanilla = yellow;
  static const Color mossGreen = mint;
  static const Color darkGreen = ink;
  static const Color steel = purple;
  static const Color steelDark = purpleDark;
  static const Color olive = mint;
  static const Color oliveDark = alive;
  static const Color teal = Color(0xFF7ED3C0);
  static const Color coral = dead;
  static const Color success = alive;
}
