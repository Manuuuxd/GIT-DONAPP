import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:onesignal_flutter/onesignal_flutter.dart';

Future<void> initNotifications() async {
  if (kIsWeb) {
    print('Skipping OneSignal init on web.');
    return;
  }

  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize('608bb723-bb79-4000-a2d0-2498b0818337');
  OneSignal.Notifications.requestPermission(true);
}
