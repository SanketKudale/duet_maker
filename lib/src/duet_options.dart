import 'dart:ui';

enum DuetLayout { sideBySide, topBottom }

enum SelfieFilter { none, mono, sepia, beauty, vivid, vignette }

class DuetOptions {
  /// Final rendered size. Default 1080x1920 vertical canvas.
  final Size outputSize;

  /// Layout of the duet.
  final DuetLayout layout;

  /// Selfie (recorded) video filter applied during composition.
  final SelfieFilter filter;

  /// Countdown seconds before starting playback+record.
  final int countdownSeconds;

  /// Target fps for the final export.
  final int targetFps;

  /// Use only original video's audio in the final export (true by default).
  final bool originalAudioOnly;

  const DuetOptions({
    this.outputSize = const Size(1080, 1920),
    this.layout = DuetLayout.topBottom,
    this.filter = SelfieFilter.none,
    this.countdownSeconds = 3,
    this.targetFps = 30,
    this.originalAudioOnly = true,
  });
}
