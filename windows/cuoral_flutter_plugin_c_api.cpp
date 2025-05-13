#include "include/cuoral_flutter/cuoral_flutter_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "cuoral_flutter_plugin.h"

void CuoralFlutterPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  cuoral_flutter::CuoralFlutterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
