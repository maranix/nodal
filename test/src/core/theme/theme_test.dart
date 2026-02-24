import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodal/src/core/theme/theme.dart';

void main() {
  group('AppThemeData', () {
    test('light() produces light brightness', () {
      final data = AppThemeData.light();
      expect(data.brightness, Brightness.light);
    });

    test('dark() produces dark brightness', () {
      final data = AppThemeData.dark();
      expect(data.brightness, Brightness.dark);
    });

    test('fromBrightness resolves correctly', () {
      final light = AppThemeData.fromBrightness(Brightness.light);
      final dark = AppThemeData.fromBrightness(Brightness.dark);

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
    });

    test('equality – same brightness are equal', () {
      final a = AppThemeData.light();
      final b = AppThemeData.light();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('equality – different brightness are not equal', () {
      final light = AppThemeData.light();
      final dark = AppThemeData.dark();
      expect(light, isNot(equals(dark)));
    });

    test('fromColorScheme accepts custom scheme', () {
      final data = AppThemeData.fromColorScheme(const LightColorScheme());
      expect(data.brightness, Brightness.light);
      expect(data.background, const LightColorScheme().background);
    });

    test('convenience color getters delegate to colorScheme', () {
      final scheme = const DarkColorScheme();
      final data = AppThemeData.fromColorScheme(scheme);

      expect(data.background, scheme.background);
      expect(data.surface, scheme.surface);
      expect(data.text, scheme.text);
      expect(data.textSecondary, scheme.textSecondary);
      expect(data.primary, scheme.primary);
      expect(data.primaryButton, scheme.primaryButton);
      expect(data.border, scheme.border);
      expect(data.error, scheme.error);
    });

    test('textTheme color matches colorScheme text color', () {
      final data = AppThemeData.light();
      expect(
        data.textTheme.bodyMedium.color,
        const LightColorScheme().text,
      );
    });
  });

  group('AppTextTheme', () {
    test('equality – same color are equal', () {
      const a = AppTextTheme(color: Color(0xFF000000));
      const b = AppTextTheme(color: Color(0xFF000000));
      expect(a, equals(b));
    });

    test('equality – different color are not equal', () {
      const a = AppTextTheme(color: Color(0xFF000000));
      const b = AppTextTheme(color: Color(0xFFFFFFFF));
      expect(a, isNot(equals(b)));
    });
  });

  group('AppTheme', () {
    testWidgets('of() returns theme data', (tester) async {
      late AppThemeData captured;

      await tester.pumpWidget(
        AppTheme(
          data: AppThemeData.light(),
          child: Builder(
            builder: (context) {
              captured = AppTheme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(captured.brightness, Brightness.light);
    });

    testWidgets('maybeOf() returns null when no AppTheme ancestor', (
      tester,
    ) async {
      AppThemeData? captured;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            captured = AppTheme.maybeOf(context);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(captured, isNull);
    });

    testWidgets('per-aspect helpers return correct values', (tester) async {
      final data = AppThemeData.dark();

      late Color bg,
          surface,
          text,
          textSecondary,
          primary,
          primaryButton,
          border,
          error;
      late Brightness brightness;
      late AppTextTheme textTheme;

      await tester.pumpWidget(
        AppTheme(
          data: data,
          child: Builder(
            builder: (context) {
              brightness = AppTheme.brightnessOf(context);
              bg = AppTheme.backgroundOf(context);
              surface = AppTheme.surfaceOf(context);
              text = AppTheme.textColorOf(context);
              textSecondary = AppTheme.textSecondaryOf(context);
              primary = AppTheme.primaryOf(context);
              primaryButton = AppTheme.primaryButtonOf(context);
              border = AppTheme.borderColorOf(context);
              error = AppTheme.errorOf(context);
              textTheme = AppTheme.textThemeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(brightness, data.brightness);
      expect(bg, data.background);
      expect(surface, data.surface);
      expect(text, data.text);
      expect(textSecondary, data.textSecondary);
      expect(primary, data.primary);
      expect(primaryButton, data.primaryButton);
      expect(border, data.border);
      expect(error, data.error);
      expect(textTheme, data.textTheme);
    });
  });

  group('Aspect-based rebuilds', () {
    test('updateShouldNotifyDependent returns false when '
        'dependent aspect did not change', () {
      // Both light — all properties identical.
      final oldWidget = AppTheme(
        data: AppThemeData.light(),
        child: const SizedBox.shrink(),
      );
      final newWidget = AppTheme(
        data: AppThemeData.light(),
        child: const SizedBox.shrink(),
      );

      // Widget watching only background should NOT be notified.
      expect(
        newWidget.updateShouldNotifyDependent(
          oldWidget,
          {AppThemeAspect.background},
        ),
        isFalse,
      );
    });

    test('updateShouldNotifyDependent returns true when '
        'dependent aspect changed', () {
      final oldWidget = AppTheme(
        data: AppThemeData.light(),
        child: const SizedBox.shrink(),
      );
      final newWidget = AppTheme(
        data: AppThemeData.dark(),
        child: const SizedBox.shrink(),
      );

      // Widget watching background SHOULD be notified (light→dark bg differs).
      expect(
        newWidget.updateShouldNotifyDependent(
          oldWidget,
          {AppThemeAspect.background},
        ),
        isTrue,
      );
    });

    test('updateShouldNotifyDependent checks only subscribed aspects', () {
      final oldWidget = AppTheme(
        data: AppThemeData.light(),
        child: const SizedBox.shrink(),
      );
      final newWidget = AppTheme(
        data: AppThemeData.dark(),
        child: const SizedBox.shrink(),
      );

      // Every individual aspect should detect the change between light→dark.
      for (final aspect in AppThemeAspect.values) {
        expect(
          newWidget.updateShouldNotifyDependent(oldWidget, {aspect}),
          isTrue,
          reason: 'Expected $aspect to detect a change between light→dark',
        );
      }
    });

    testWidgets('widget depending on background DOES rebuild '
        'when background changes', (tester) async {
      int buildCount = 0;

      await tester.pumpWidget(
        _RebuildTracker(
          themeData: AppThemeData.light(),
          aspect: AppThemeAspect.background,
          onBuild: () => buildCount++,
        ),
      );

      expect(buildCount, 1);

      await tester.pumpWidget(
        _RebuildTracker(
          themeData: AppThemeData.dark(),
          aspect: AppThemeAspect.background,
          onBuild: () => buildCount++,
        ),
      );

      // Background changed (light→dark), so the widget MUST rebuild.
      expect(buildCount, 2);
    });
  });

  group('AppThemeProvider', () {
    testWidgets('provides theme data from platform brightness', (tester) async {
      late Brightness capturedBrightness;

      await tester.pumpWidget(
        const AppThemeProvider(
          child: _BrightnessCapture(),
        ),
      );

      final state = tester.state<_BrightnessCaptureState>(
        find.byType(_BrightnessCapture),
      );
      capturedBrightness = state.capturedBrightness;

      // Should match the test platform's default brightness.
      expect(capturedBrightness, isNotNull);
    });

    testWidgets('setMode switches theme and animates', (tester) async {
      late Brightness capturedBrightness;

      await tester.pumpWidget(
        AppThemeProvider(
          duration: const Duration(milliseconds: 200),
          child: Builder(
            builder: (context) {
              capturedBrightness = AppTheme.brightnessOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // Initially matches platform default (light in tests).
      expect(capturedBrightness, Brightness.light);

      // Switch to dark programmatically.
      final state = tester.state<AppThemeProviderState>(
        find.byType(AppThemeProvider),
      );
      state.setMode(ThemeMode.dark);

      // Pump a few frames — animation is in progress.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Complete the animation.
      await tester.pumpAndSettle();

      expect(capturedBrightness, Brightness.dark);
    });

    testWidgets('setMode to system reverts to platform brightness', (
      tester,
    ) async {
      late Brightness capturedBrightness;

      await tester.pumpWidget(
        AppThemeProvider(
          duration: const Duration(milliseconds: 100),
          child: Builder(
            builder: (context) {
              capturedBrightness = AppTheme.brightnessOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final state = tester.state<AppThemeProviderState>(
        find.byType(AppThemeProvider),
      );

      // Force dark.
      state.setMode(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(capturedBrightness, Brightness.dark);

      // Revert to system (test platform default is light).
      state.setMode(ThemeMode.system);
      await tester.pumpAndSettle();
      expect(capturedBrightness, Brightness.light);
    });
  });

  group('AppThemeData.lerp', () {
    test('t=0 returns a', () {
      final a = AppThemeData.light();
      final b = AppThemeData.dark();
      final result = AppThemeData.lerp(a, b, 0.0);
      expect(identical(result, a), isTrue);
    });

    test('t=1 returns b', () {
      final a = AppThemeData.light();
      final b = AppThemeData.dark();
      final result = AppThemeData.lerp(a, b, 1.0);
      expect(identical(result, b), isTrue);
    });

    test('midpoint produces blended colors', () {
      final a = AppThemeData.light();
      final b = AppThemeData.dark();
      final mid = AppThemeData.lerp(a, b, 0.5);

      // Midpoint should differ from both endpoints.
      expect(mid.background, isNot(equals(a.background)));
      expect(mid.background, isNot(equals(b.background)));
    });

    test('brightness resolves to b when t >= 0.5', () {
      final a = AppThemeData.light();
      final b = AppThemeData.dark();

      expect(AppThemeData.lerp(a, b, 0.49).brightness, Brightness.light);
      expect(AppThemeData.lerp(a, b, 0.5).brightness, Brightness.dark);
    });
  });
}

/// A widget that subscribes to a single [AppThemeAspect] and calls [onBuild]
/// each time its builder runs. Used to verify aspect-gated rebuilds.
class _RebuildTracker extends StatelessWidget {
  const _RebuildTracker({
    required this.themeData,
    required this.aspect,
    required this.onBuild,
  });

  final AppThemeData themeData;
  final AppThemeAspect aspect;
  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    return AppTheme(
      data: themeData,
      child: Builder(
        builder: (context) {
          // Subscribe to only the specified aspect.
          InheritedModel.inheritFrom<AppTheme>(context, aspect: aspect);
          onBuild();
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// Simple widget that captures the brightness from [AppTheme].
class _BrightnessCapture extends StatefulWidget {
  const _BrightnessCapture();

  @override
  State<_BrightnessCapture> createState() => _BrightnessCaptureState();
}

class _BrightnessCaptureState extends State<_BrightnessCapture> {
  late Brightness capturedBrightness;

  @override
  Widget build(BuildContext context) {
    capturedBrightness = AppTheme.brightnessOf(context);
    return const SizedBox.shrink();
  }
}
