import 'package:flutter_test/flutter_test.dart';
import 'package:cuoral_flutter/cuoral_flutter.dart';
import 'package:cuoral_flutter/cuoral_flutter_platform_interface.dart';
import 'package:cuoral_flutter/cuoral_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCuoralFlutterPlatform
    with MockPlatformInterfaceMixin
    implements CuoralFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final CuoralFlutterPlatform initialPlatform = CuoralFlutterPlatform.instance;

  test('$MethodChannelCuoralFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCuoralFlutter>());
  });

  test('getPlatformVersion', () async {
    CuoralFlutter cuoralFlutterPlugin = CuoralFlutter();
    MockCuoralFlutterPlatform fakePlatform = MockCuoralFlutterPlatform();
    CuoralFlutterPlatform.instance = fakePlatform;

    expect(await cuoralFlutterPlugin.getPlatformVersion(), '42');
  });
}
