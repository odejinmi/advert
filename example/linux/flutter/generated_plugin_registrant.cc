//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <advert/advert_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) advert_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "AdvertPlugin");
  advert_plugin_register_with_registrar(advert_registrar);
}
