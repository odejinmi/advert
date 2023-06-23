#include "include/advert/advert_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "advert_plugin.h"

void AdvertPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  advert::AdvertPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
