import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:http/http.dart' as http;

import 'duet_options.dart';
import 'duet_source.dart';
import 'ffmpeg_cmd.dart';

class DuetResult {
  final String outputPath;
  DuetResult(this.outputPath);
}

class DuetController {
  final DuetOptions options;
  DuetController({this.options = const DuetOptions()});

  CameraController? _cam;
  VideoPlayerController? _origVc;
  late final StreamController<bool> _recStream = StreamController.broadcast();
  bool _isRecording = false;
  bool _disposed = false;
  XFile? _recorded;
  VoidCallback? _listener;

  Stream<bool> get recordingStream => _recStream.stream;
  bool get isRecording => _isRecording;
  VideoPlayerController? get originalPlayer => _origVc;
  CameraController? get cameraController => _cam;

  Future<void> initialize() async {
    final cams = await availableCameras();
    final front = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first);
    _cam = CameraController(front, ResolutionPreset.high, enableAudio: true);
    await _cam!.initialize();
  }

  Future<void> loadOriginal(DuetSource source) async {
    // Dispose old controller
    await _origVc?.dispose();

    String path;
    if (source.uri.isScheme('http') || source.uri.isScheme('https')) {
      final tmp = await getTemporaryDirectory();
      final fname = 'orig_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final fpath = '${tmp.path}/$fname';
      final resp = await http.get(source.uri);
      final file = File(fpath);
      await file.writeAsBytes(resp.bodyBytes);
      path = fpath;
    } else if (source.uri.isScheme('file')) {
      path = source.uri.toFilePath();
    } else {
      throw UnsupportedError('Only file:// or http(s):// URIs are supported');
    }

    _origVc = VideoPlayerController.file(File(path));
    await _origVc!.initialize();
    _origVc!.setLooping(false);

    // Ensure the listener is attached once.
    _listener = () async {
      final v = _origVc!.value;
      if (_isRecording && v.isInitialized) {
        final dur = v.duration;
        final pos = v.position;
        if (!v.isPlaying &&
            dur != Duration.zero &&
            pos >= dur - const Duration(milliseconds: 80)) {
          await stopRecording(); // auto-stop when original ends
        }
      }
    };
    _origVc!.addListener(_listener!);
  }

  Future<void> startRecordingWithPlayback() async {
    if (_cam == null || !_cam!.value.isInitialized || _origVc == null) {
      throw StateError('Camera or original video not ready');
    }

    // Reset original to start and start both ASAP
    await _origVc!.seekTo(Duration.zero);

    // Start camera recording first (ensures frames captured once playback begins)
    await _cam!.startVideoRecording();

    // Optional countdown
    if (options.countdownSeconds > 0) {
      await Future.delayed(Duration(seconds: options.countdownSeconds));
    }

    await _origVc!.play();

    _isRecording = true;
    _recStream.add(true);
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    _isRecording = false;
    _recStream.add(false);

    if (_cam != null && _cam!.value.isRecordingVideo) {
      _recorded = await _cam!.stopVideoRecording();
    }
    try {
      await _origVc?.pause();
    } catch (_) {}
  }

  Future<DuetResult> compose() async {
    if (_recorded == null || _origVc == null) {
      throw StateError('Nothing recorded or original not loaded');
    }
    final tmp = await getTemporaryDirectory();
    final outPath =
        '${tmp.path}/duet_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final builder = FfmpegCmdBuilder(
      originalPath: _origVc!.dataSource,
      selfiePath: _recorded!.path,
      opts: options,
    );
    final cmd = builder.build(outPath);
    final session = await FFmpegKit.execute(cmd);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) {
      return DuetResult(outPath);
    } else {
      final log = await session.getAllLogsAsString();
      throw Exception('FFmpeg failed: $log');
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _recStream.close();
    try {
      await _cam?.dispose();
    } catch (_) {}
    try {
      if (_listener != null) _origVc?.removeListener(_listener!);
      await _origVc?.dispose();
    } catch (_) {}
  }
}
