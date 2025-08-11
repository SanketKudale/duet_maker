# duet_maker

A Flutter package to create TikTok-like duet videos on-device:

- Plays an original video while recording the front camera.
- **Auto-stops** when the original finishes.
- Exports a duet (side-by-side or top/bottom).
- **Original-only audio** retained from the source video.
- Optional selfie **filters** (mono, sepia, beauty, vivid, vignette).

## Quick start
```dart
final controller = DuetController(options: DuetOptions(originalAudioOnly: true));
await controller.initialize();
await controller.loadOriginal(DuetSource.network('https://example.com/video.mp4'));
await controller.startRecordingWithPlayback();
// recording auto-stops at original end, but you can also:
await controller.stopRecording();
final res = await controller.compose();
print('Output: ' + res.outputPath);
OR
DuetView(
  controller: DuetController(options: const DuetOptions(filter: SelfieFilter.vivid)),
  source: DuetSource.filePath('/path/original.mp4'),
  onComposedPath: (p) => debugPrint('Saved to $p'),
)