import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  await [
    Permission.camera,
    Permission.storage,
    Permission.photos,
  ].request();
}

Future<bool> checkCameraPermission() async {
  var status = await Permission.camera.status;
  return status.isGranted;
}

Future<bool> requestCameraPermission() async {
  var status = await Permission.camera.request();
  return status.isGranted;
}