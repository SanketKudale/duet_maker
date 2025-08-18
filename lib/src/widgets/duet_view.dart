import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../duet_controller.dart';
import '../duet_source.dart';

/// A ready-to-use UI widget for picking/previewing and recording a duet.
class DuetView extends StatefulWidget {
  final DuetController controller;
  final DuetSource source;
  final VoidCallback? onComposed;
  final void Function(String outputPath)? onComposedPath;
  final void Function(Object error)? onError;
  final Color? buttonColor;
  final Color? buttonTextColor;

  const DuetView(
      {super.key,
      required this.controller,
      required this.source,
      this.onComposed,
      this.onComposedPath,
      this.onError,
      this.buttonColor = Colors.yellowAccent,
      this.buttonTextColor = Colors.white});

  @override
  State<DuetView> createState() => _DuetViewState();
}

class _DuetViewState extends State<DuetView> {
  bool _loading = true;
  String? _status;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _status = 'Initializing camera...';
    });
    await widget.controller.initialize();
    setState(() {
      _status = 'Loading original...';
    });
    await widget.controller.loadOriginal(widget.source);
    setState(() {
      _loading = false;
      _status = null;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cam = widget.controller.cameraController;
    final player = widget.controller.originalPlayer;

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          Expanded(
            child: _loading
                ? Center(child: Text(_status ?? 'Loading...'))
                : Column(
                    children: [
                      Expanded(
                        child: player == null
                            ? const Center(child: Text('No original loaded'))
                            : AspectRatio(
                                aspectRatio: 1.777,
                                child: VideoPlayer(player),
                              ),
                      ),
                      Expanded(
                        child: player != null
                            ? cam == null || !cam.value.isInitialized
                                ? const Center(child: Text('Camera not ready'))
                                : AspectRatio(
                                    aspectRatio: 1.777,
                                    child: CameraPreview(cam))
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 50),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: widget.buttonColor,
                        textStyle: TextStyle(color: widget.buttonTextColor)),
                    onPressed: () async {
                      try {
                        await widget.controller.startRecordingWithPlayback();
                        if (!mounted) return;
                        setState(() {});
                      } catch (e) {
                        widget.onError?.call(e);
                      }
                    },
                    child: Text('Record', style: TextStyle(color: widget.buttonTextColor),),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: widget.buttonColor,
                        textStyle: TextStyle(color: widget.buttonTextColor)),
                    onPressed: () async {
                      try {
                        await widget.controller.stopRecording();
                        final res = await widget.controller.compose();
                        widget.onComposed?.call();
                        widget.onComposedPath?.call(res.outputPath);
                      } catch (e) {
                        widget.onError?.call(e);
                      }
                    },
                    child: Text('Stop & Compose', style: TextStyle(color: widget.buttonTextColor)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
