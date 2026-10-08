import 'dart:async';

import 'package:flutter/material.dart';

import 'package:omi/mobile/native_ui/ios_native_surface.dart';
import 'package:omi/mobile/native_ui/native_asset_image.dart';
import 'package:omi/providers/device_onboarding_provider.dart';
import 'package:omi/utils/l10n_extensions.dart';

/// Device-supplied text (a transcript, a question, an answer) as a bounded literal native label.
String deviceTutorialNativeText(String text, {int maximum = 4000}) {
  final characters = text.characters;
  return characters.length <= maximum ? text : '${characters.take(maximum)}…';
}

/// The tutorial's Continue action as a native row; the step keeps its own visibility rule.
NativeRow deviceTutorialContinueRow(BuildContext context, VoidCallback onComplete, {String? label}) =>
    NativeRow('dev_tut_continue', label ?? context.l10n.deviceOnboardingContinue, action: (_) => onComplete());

/// Static bundled device artwork for native rows, replacing the classic animated artwork. Null on
/// the classic path and until the copy is ready; a failed copy simply leaves the row without it.
mixin DeviceTutorialNativeArtwork<T extends StatefulWidget> on State<T> {
  final Map<String, String?> _nativeArtwork = {};

  String? nativeArtwork(String asset) {
    if (!nativePresentationEnabled) return null;
    if (!_nativeArtwork.containsKey(asset)) {
      _nativeArtwork[asset] = null;
      unawaited(nativeAssetImageUri(asset).then((uri) {
        if (mounted && uri != null) setState(() => _nativeArtwork[asset] = uri);
      }));
    }
    return _nativeArtwork[asset];
  }
}

// Persistent, self-animating progress indicator. Rendered once in the wrapper
// (above the transitioning content) and driven live by provider.currentStep, so
// the active dot grows in place as the flow advances instead of being duplicated
// inside each step and sliding away with it.
class OnboardingProgressDots extends StatelessWidget {
  final int currentStep;

  const OnboardingProgressDots({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(DeviceOnboardingProvider.totalSteps, (index) {
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? Colors.white
                : isCompleted
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.2),
          ),
        );
      }),
    );
  }
}

class OnboardingStepScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget content;
  final Widget? bottomAction;

  const OnboardingStepScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.content,
    this.bottomAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 16, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 40),
          Expanded(child: content),
          if (bottomAction != null) ...[bottomAction!, const SizedBox(height: 24)],
        ],
      ),
    );
  }
}

class OnboardingContinueButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String? label;

  const OnboardingContinueButton({super.key, required this.onPressed, this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 0,
        ),
        child: Text(
          label ?? context.l10n.deviceOnboardingContinue,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
