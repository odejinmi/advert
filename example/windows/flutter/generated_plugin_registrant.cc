//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <advert/advert_plugin_c_api.h>
#include <connectivity_plus/connectivity_plus_windows_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  AdvertPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("AdvertPluginCApi"));
  ConnectivityPlusWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ConnectivityPlusWindowsPlugin"));
}
