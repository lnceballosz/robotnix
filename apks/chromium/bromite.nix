# SPDX-FileCopyrightText: 2020 Daniel Fullmer and robotnix contributors
# SPDX-License-Identifier: MIT

{ chromium, fetchFromGitHub, git, python3 }:

let
  version = "88.0.4324.95";

  bromite_src = fetchFromGitHub {
    owner = "bromite";
    repo = "bromite";
    rev = version;
    sha256 = "0qwfv4m4mfmb30r2yz7yq0lybznqp5w3yyy37qr75jharxw429a3";
  };

in (chromium.override {
  name = "bromite";
  displayName = "Bromite";
  inherit version;
  enableRebranding = true;
  customGnFlags = { # From bromite/build/GN_ARGS
    blink_symbol_level=1;
    dcheck_always_on=false;
    debuggable_apks=false;
    dfmify_dev_ui=false;
    disable_android_lint=true;
    disable_autofill_assistant_dfm=true;
    disable_tab_ui_dfm=true;
    enable_av1_decoder=true;
    enable_dav1d_decoder=true;
    enable_gvr_services=false;
    enable_hangout_services_extension=false;
    enable_iterator_debugging=false;
    enable_mdns=false;
    enable_mse_mpeg2ts_stream_parser=true;
    enable_nacl=false;
    enable_nacl_nonsfi=false;
    enable_platform_dolby_vision=true;
    enable_platform_hevc=true;
    enable_remoting=false;
    enable_reporting=true; # Otherwise, fails with undefined symbol: content::CrossOriginEmbedderPolicyReporter::CrossOriginEmbedderPolicyReporter
    enable_vr=false;
    fieldtrial_testing_like_official_build=true;
    icu_use_data_file=true;
    is_component_build=false;
    is_debug=false;
    is_official_build=true;
    rtc_build_examples=false;
    safe_browsing_mode=0;
    symbol_level=1;
    use_debug_fission=true;
    use_errorprone_java_compiler=false;
    use_official_google_api_keys=false;
    use_openh264=true;
    chrome_pgo_phase=0;
    use_sysroot=false;
    webview_includes_weblayer=false;

    # XXX: Hack. Not sure why it's not being set correctly when building webview
    rtc_use_x11=false;
    rtc_use_x11_extensions=false;
    rtc_use_pipewire=false;
  };
}).overrideAttrs (attrs: {
  postPatch = ''
    ( cd src
      cat ${bromite_src}/build/bromite_patches_list.txt | while read patchfile; do
        echo Applying $patchfile
        ${git}/bin/git apply --unsafe-paths "${bromite_src}/build/patches/$patchfile"
      done
    )
  '' + attrs.postPatch;
})
