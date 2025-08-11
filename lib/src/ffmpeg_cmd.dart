import 'duet_options.dart';
import 'filters.dart';

class FfmpegCmdBuilder {
  final String originalPath; // input0
  final String selfiePath; // input1
  final DuetOptions opts;

  FfmpegCmdBuilder(
      {required this.originalPath,
      required this.selfiePath,
      required this.opts});

  /// Builds a safe ffmpeg command string with proper quoting for paths.
  String build(String outPath) {
    final width = opts.outputSize.width.toInt();
    final height = opts.outputSize.height.toInt();

    // Compute per-pane target sizes for scaling/cropping.
    late final String vFilter;
    late final String layoutFilter;

    if (opts.layout == DuetLayout.sideBySide) {
      final w = (width / 2).toInt();
      final h = height;
      vFilter =
          "[0:v]scale=${w}:${h}:force_original_aspect_ratio=increase,crop=${w}:${h},setsar=1[v0];" // original
          "[1:v]hflip${_pref(selfieFilterChain(opts.filter))},scale=${w}:${h}:force_original_aspect_ratio=increase,crop=${w}:${h},setsar=1[v1];"; // selfie with optional filter
      layoutFilter = "[v0][v1]hstack=inputs=2:shortest=1[v]";
    } else {
      final w = width;
      final h = (height / 2).toInt();
      vFilter =
          "[0:v]scale=${w}:${h}:force_original_aspect_ratio=increase,crop=${w}:${h},setsar=1[v0];"
          "[1:v]hflip${_pref(selfieFilterChain(opts.filter))},scale=${w}:${h}:force_original_aspect_ratio=increase,crop=${w}:${h},setsar=1[v1];";
      layoutFilter = "[v0][v1]vstack=inputs=2:shortest=1[v]";
    }

    // Audio: map ONLY original audio, if present (0:a?)
    final audioMap = '-map 0:a? -c:a aac -b:a 192k';

    return "-y -i ${q(originalPath)} -i ${q(selfiePath)} "
        "-filter_complex \"${vFilter} ${layoutFilter}\" "
        "-map \"[v]\" ${audioMap} -r ${opts.targetFps} -c:v libx264 -preset veryfast -crf 23 -shortest ${q(outPath)}";
  }

  String _pref(String s) =>
      s.isEmpty ? '' : ",${s}"; // prepend comma if not empty
}

String q(String s) {
  final esc = s.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
  return '"$esc"';
}
