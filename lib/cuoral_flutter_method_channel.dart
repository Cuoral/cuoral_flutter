import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cuoral_flutter_platform_interface.dart';

/// An implementation of [CuoralFlutterPlatform] that uses method channels.
class MethodChannelCuoralFlutter extends CuoralFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('cuoral_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
