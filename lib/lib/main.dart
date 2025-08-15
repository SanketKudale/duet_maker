import 'package:flutter/material.dart';
import 'package:duet_maker/duet_maker.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    return MaterialApp(
      home: Scaffold(
        body: DuetView(
          controller: DuetController(
            options: DuetOptions(
              originalAudioOnly: true,
              filter: SelfieFilter.vivid,
              layout: DuetLayout.topBottom,
              targetFps: 30,
              countdownSeconds: 3,
            ),
          ),
          // Example with a network URL (could also be file path)
          source: DuetSource.network('https://example.com/video.mp4'),
          onComposedPath: (path) {
            debugPrint('Duet exported to: $path');
          },
          onError: (e) => debugPrint('Error: $e'),
        ),
      ),
    );
  }
}
