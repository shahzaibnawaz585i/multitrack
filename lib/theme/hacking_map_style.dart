/// Dark map style with a subtle green tint, used when the hacking theme is on.
const String hackingMapStyle = '''
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
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#1b3a26"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#2a6b41"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#132a1c"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#04120a"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#2b8f52"}]}
]
''';
