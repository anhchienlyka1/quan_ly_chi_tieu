---
description: How to maintain consistent font usage (Outfit) across the application.
---

# Font Consistency Guide

The application uses **Outfit** (via `google_fonts`) as the primary font family. To maintain consistency, follow these rules:

## 1. Use `Theme.of(context).textTheme`
Always prefer using the global text theme, which is already configured to use Outfit.

```dart
// ✅ GOOD
Text(
  'Hello World',
  style: context.textTheme.bodyLarge,
);

// ❌ BAD
Text(
  'Hello World',
  style: TextStyle(fontSize: 16), // Uses default font (Roboto/SF)
);
```

## 2. Using Custom Styles
If you need a specific style not covered by the theme, use `GoogleFonts.outfit` directly, or extend a theme style.

```dart
// ✅ GOOD
Text(
  'Custom Style',
  style: GoogleFonts.outfit(
    fontSize: 40,
    fontWeight: FontWeight.w900,
  ),
);

// ✅ GOOD (Preferred)
Text(
  'Custom Style',
  style: context.textTheme.headlineLarge?.copyWith(
    fontSize: 40,
    fontWeight: FontWeight.w900,
  ),
);
```

## 3. App Theme Configuration
The `AppTheme` class in `lib/theme/app_theme.dart` configures the font globally:

```dart
textTheme: GoogleFonts.outfitTextTheme().copyWith(...)
```

It also explicitly sets the font for `AppBar` and `FilledButton`:

```dart
appBarTheme: AppBarTheme(
  titleTextStyle: GoogleFonts.outfit(...),
),
filledButtonTheme: FilledButtonThemeData(
  style: FilledButton.styleFrom(
    textStyle: GoogleFonts.outfit(...),
  ),
),
```

## 4. Verification
To verify consistency, search for `TextStyle(` in the codebase. Legitimate uses are rare (mostly in `AppTheme` definition itself). Most UI code should not use `TextStyle` constructor directly unless it's wrapped in a `GoogleFonts` call or `copyWith`.
