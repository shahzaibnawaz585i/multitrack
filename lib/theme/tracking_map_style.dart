import 'package:flutter/widgets.dart';

import 'app_theme_tokens.dart';

/// Default live-track map — readable roads at moderate zoom; highways drawn wide.
const String trackingMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f5f5f5"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#f5f5f5"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#d0d0d0"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#fefefe"}]},
  {"featureType":"road.arterial","elementType":"geometry.stroke","stylers":[{"color":"#c0c0c0"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#ffe082"},{"weight":4}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#f9a825"},{"weight":4}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#c9e6ff"}]},
  {"featureType":"poi","elementType":"labels.icon","stylers":[{"visibility":"off"}]}
]
''';

/// Zoom that shows nearby roads without street-level clutter.
const double liveTrackInitialZoom = 16.0;

extension LiveTrackMapStyleContext on BuildContext {
  String get liveTrackMapStyle {
    if (isHackingTheme) {
      return hackingLiveTrackMapStyle;
    }
    if (isAuroraTheme) {
      return auroraLiveTrackMapStyle;
    }
    return trackingMapStyle;
  }
}

/// Aurora theme + 4px highways for live tracking.
const String auroraLiveTrackMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#060918"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#a0b4ff"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#030510"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#1f2952"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#c4b5fd"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#818cf8"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#0c142b"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#131c3a"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#2e1f47"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#cbd5e1"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#1e1b4b"},{"weight":4}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#00f5d4"},{"weight":4}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#00f5d4"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#172554"}]},
  {"featureType":"road.arterial","elementType":"geometry.stroke","stylers":[{"color":"#a78bfa"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#111827"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#051126"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#38bdf8"}]}
]
''';

/// Hacking theme + 4px highways for live tracking.
const String hackingLiveTrackMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0a120c"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#3fbf6a"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#050805"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#123a22"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#4fd685"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#2f9c56"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#0e2415"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#14251b"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#1d4a2e"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#54c07f"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#1b3a26"},{"weight":4}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#2a6b41"},{"weight":4}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#132a1c"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#04120a"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#2b8f52"}]}
]
''';
