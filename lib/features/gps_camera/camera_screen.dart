import 'package:flutter/material.dart';

/// Camera tab. Owned by the gps-camera feature developer.
///
/// Planned flow (packages already in pubspec):
///   1. `camera` captures the photo to a temp file.
///   2. `geolocator` reads the current position + timestamp.
///   3. `photo_store.dart` (sqflite via `path_provider`) saves the
///      file path + lat/lng + timestamp row. On-device only, no upload.
class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GPS Camera')),
      body: const Center(
        child: Text('Camera preview and capture button go here.'),
      ),
      floatingActionButton: FloatingActionButton(
        // TODO(gps-camera): capture photo, tag location + time, save locally.
        onPressed: null,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
