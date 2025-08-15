import 'duet_options.dart';
import 'filters.dart';

class FfmpegCmdBuilder {
  final String originalPath; // input0
  final String selfiePath;   // input1
  final DuetOptions opts;

  FfmpegCmdBuilder({
    required this.originalPath,
    required this.selfiePath,
    required this.opts,
  });

  /// Builds a safe ffmpeg command string with proper quoting for paths.
  String build(String outPath) {
    final width  = opts.outputSize.width.toInt();   // e.g., 1080
    final height = opts.outputSize.height.toInt();  // e.g., 1920

    // Decide layout explicitly
    final isTopBottom = opts.layout == DuetLayout.topBottom
        || opts.layout != DuetLayout.sideBySide; // default to vertical

    // Per-pane target sizes
    final paneW = isTopBottom ? width : (width / 2).toInt();
    final paneH = isTopBottom ? (height / 2).toInt() : height;

    // --- COVER variant (fills pane, may crop) ---
    final vFilterCover =
        "[0:v]scale=${paneW}:${paneH}:force_original_aspect_ratio=increase,"
        "crop=${paneW}:${paneH},setsar=1[v0];"
        "[1:v]hflip${_pref(selfieFilterChain(opts.filter))},"
        "scale=${paneW}:${paneH}:force_original_aspect_ratio=increase,"
        "crop=${paneW}:${paneH},setsar=1[v1];";

    // --- CONTAIN variant (no crop, may letterbox) ---
    final vFilterContain =
        "[0:v]scale=${paneW}:${paneH}:force_original_aspect_ratio=decrease,"
        "pad=${paneW}:${paneH}:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1[v0];"
        "[1:v]hflip${_pref(selfieFilterChain(opts.filter))},"
        "scale=${paneW}:${paneH}:force_original_aspect_ratio=decrease,"
        "pad=${paneW}:${paneH}:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1[v1];";

    // Choose which visual fit you want:
    final vFilter = vFilterCover; // or vFilterContain;

    final layoutFilter = isTopBottom
        ? "[v0][v1]vstack=inputs=2:shortest=1[v]"
        : "[v0][v1]hstack=inputs=2:shortest=1[v]";

    // Audio: only ORIGINAL track if present (avoids echo); change to `-map 1:a?` for selfie audio.
    final audioMap = '-map 0:a? -c:a aac -b:a 192k';

    return "-y -i ${q(originalPath)} -i ${q(selfiePath)} "
        "-filter_complex \"${vFilter} ${layoutFilter}\" "
        "-map \"[v]\" ${audioMap} "
        "-r ${opts.targetFps} "
        "-c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p "
        "-shortest ${q(outPath)}";
  }

  String _pref(String s) => s.isEmpty ? '' : ",$s";
}

String q(String s) {
  final esc = s.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
  return '"$esc"';
}
