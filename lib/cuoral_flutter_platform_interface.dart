import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'cuoral_flutter_method_channel.dart';

abstract class CuoralFlutterPlatform extends PlatformInterface {
  /// Constructs a CuoralFlutterPlatform.
  CuoralFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static CuoralFlutterPlatform _instance = MethodChannelCuoralFlutter();

  /// The default instance of [CuoralFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelCuoralFlutter].
  static CuoralFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CuoralFlutterPlatform] when
  /// they register themselves.
  static set instance(CuoralFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
