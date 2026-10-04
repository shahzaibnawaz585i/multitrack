import 'dart:collection';

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// One smooth transition from the marker's current position toward [waypoints].
class MarkerMotionSegment {
  const MarkerMotionSegment({
    required this.waypoints,
    required this.duration,
    required this.moving,
  });

  final List<LatLng> waypoints;
  final Duration duration;
  final bool moving;
}

/// FIFO queue of incoming GPS targets — drained one segment at a time.
class MarkerMotionQueue {
  MarkerMotionQueue({this.maxDepth = 12});

  final int maxDepth;
  final Queue<MarkerMotionSegment> _pending = Queue<MarkerMotionSegment>();

  bool get isEmpty => _pending.isEmpty;
  int get length => _pending.length;

  void enqueue(MarkerMotionSegment segment) {
    if (segment.waypoints.length < 2) {
      return;
    }
    _pending.addLast(segment);
    while (_pending.length > maxDepth) {
      _pending.removeFirst();
    }
  }

  MarkerMotionSegment? peek() =>
      _pending.isEmpty ? null : _pending.first;

  MarkerMotionSegment? dequeue() {
    if (_pending.isEmpty) {
      return null;
    }
    return _pending.removeFirst();
  }

  void clear() => _pending.clear();
}
