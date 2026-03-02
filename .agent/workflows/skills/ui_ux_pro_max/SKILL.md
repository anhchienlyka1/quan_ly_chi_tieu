---
name: UI/UX Pro Max
description: A comprehensive guide and set of standards for building premium, high-fidelity Flutter interfaces with a focus on user experience, animations, and modern design principles.
---

# UI/UX Pro Max: The Gold Standard for Flutter Development

This skill dictates the standards for creating exceptional user interfaces and experiences in Flutter. When this skill is active or referenced, all UI work must adhere to these guidelines to ensure a "Pro Max" quality level.

## 1. Design Philosophy
- **Premium Feel**: Every interaction should feel deliberate and polished. Avoid "default" looks.
- **Motion Design**: Static screens are forbidden. Use implicit animations, page transitions, and micro-interactions to bring the app to life.
- **Consistency**: adhere strictly to a design system (Typography, Colors, Spacing, Shadows).
- **Haptic Feedback**: Use `HapticFeedback` for significant user actions (e.g., success, error, selection).

## 2. Technical Implementation Standards

### A. Theming & Colors
- **Dynamic Theming**: Support both Light and Dark modes with seamless transitions.
- **Color Palette**: Use a semantic color system (Primary, Secondary, Surface, Error, Success, Warning) rather than hardcoded hex values.
- **Typography**: formatting should use `TextTheme` with varying weights and sizes to establish a clear visual hierarchy.

### B. Animations & Motion
- **Implicit Animations**: Prefer `AnimatedContainer`, `AnimatedOpacity`, `AnimatedPadding` over static widgets for state changes.
- **Page Transitions**: Use `CupertinoPageRouter` on iOS and `OpenUpwardsPageTransitionsBuilder`/`FadeUpwardsPageTransitionsBuilder` on Android, or custom transitions for specific flows.
- **Hero Animations**: Use `Hero` widgets for shared elements between screens.
- **Staggered Animations**: improved list or grid loading with staggered entry animations.

### C. Components & Widgets
- **Custom Buttons**: Create proprietary button components (Primary, Secondary, Text) with:
  - Valid/Invalid states
  - Loading indicators (replace text with spinner)
  - Splash effects (InkWell/InkResponse)
  - Scale on press
- **Input Fields**: Custom decoration, focused/error borders, and clear error messaging.
- **Dialogs & BottomSheets**: Use rounded corners (standardize radius, e.g., 16.0 or 24.0) and backdrop blur (`BackdropFilter`).

### D. Layout & Responsiveness
- **Safe Areas**: Always wrap top-level page content in `SafeArea` (or handle padding manually) to respect notches and dynamic islands.
- **Scroll Physics**: Use `BouncingScrollPhysics` for a native iOS feel or `ClampingScrollPhysics` where appropriate, but prefer Bouncing for a "fluid" feel generally.
- **Responsive Design**: Ensure layouts adapt to different screen widths using `LayoutBuilder` or flexible widgets (`Expanded`, `Flexible`).

## 3. Workflow for UI Tasks
1.  **Analyze**: Understand the user's requirement and visualize the "Premium" version of it.
2.  **Scaffold**: Build the structure using semantic widgets.
3.  **Style**: Apply the design system (colors, typography).
4.  **Animate**: Add entry animations and state change transitions.
5.  **Polish**: Add haptic feedback, check contrasting colors, and ensure touch targets are at least 44x44.

## 4. Code Snippets & Patterns

### Standard Screen Boilerplate
```dart
class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Content goes here
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### Premium Button Pattern
```dart
class ProButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;

  const ProButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: 1.0, // Add logic for scale on press
      duration: const Duration(milliseconds: 100),
      child: FilledButton(
        onPressed: isLoading ? null : () {
          HapticFeedback.lightImpact();
          onPressed?.call();
        },
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
```

## 5. Forbidden Practices
- ❌ Using generic standard blue (`Colors.blue`) without purpose.
- ❌ Hardcoding font sizes everywhere (use `Theme.of(context).textTheme`).
- ❌ Blocking the UI thread.
- ❌ Ignoring the keyboard overlap (use `ResizeToAvoidBottomInset` or scrolling).
- ❌ Creating "dead" static lists without ink responses or touch feedback.
