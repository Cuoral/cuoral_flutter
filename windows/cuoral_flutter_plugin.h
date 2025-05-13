#ifndef FLUTTER_PLUGIN_CUORAL_FLUTTER_PLUGIN_H_
#define FLUTTER_PLUGIN_CUORAL_FLUTTER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace cuoral_flutter {

class CuoralFlutterPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  CuoralFlutterPlugin();

  virtual ~CuoralFlutterPlugin();

  // Disallow copy and assign.
  CuoralFlutterPlugin(const CuoralFlutterPlugin&) = delete;
  CuoralFlutterPlugin& operator=(const CuoralFlutterPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace cuoral_flutter

#endif  // FLUTTER_PLUGIN_CUORAL_FLUTTER_PLUGIN_H_
