//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <advert/advert_plugin_c_api.h>
#include <hx_liftoff_ads/hx_liftoff_ads_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  AdvertPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("AdvertPluginCApi"));
  HxLiftoffAdsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("HxLiftoffAdsPluginCApi"));
}
