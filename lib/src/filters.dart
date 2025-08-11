import 'duet_options.dart';

/// Returns the FFmpeg filter chain to apply to the selfie stream BEFORE scaling/cropping.
String selfieFilterChain(SelfieFilter f) {
  switch (f) {
    case SelfieFilter.none:
      return '';
    case SelfieFilter.mono:
      return 'hue=s=0';
    case SelfieFilter.sepia:
      return 'colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131';
    case SelfieFilter.beauty:
      // Light denoise + subtle sharpen.
      return 'hqdn3d=4:3:6:4,unsharp=5:5:0.5:5:5:0.0';
    case SelfieFilter.vivid:
      return 'eq=contrast=1.15:saturation=1.35:brightness=0.02';
    case SelfieFilter.vignette:
      return 'vignette=PI/5';
  }
}
