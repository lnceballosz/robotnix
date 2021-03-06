# SPDX-FileCopyrightText: 2020 Daniel Fullmer and robotnix contributors
# SPDX-License-Identifier: MIT

{ config, pkgs, lib, ... }:
with lib;
let
  grapheneOSRelease = "${config.apv.buildID}.2021.01.23.03";

  phoneDeviceFamilies = [ "crosshatch" "bonito" "coral" "sunfish" ];
  supportedDeviceFamilies = phoneDeviceFamilies ++ [ "generic" ];

in mkIf (config.flavor == "grapheneos") (mkMerge [
{
  # This a default datetime for robotnix that I update manually whenever
  # significant a change is made to anything the build depends on. It does not
  # match the datetime used in the GrapheneOS build above.
  buildDateTime = mkDefault 1611467048;

  source.dirs = lib.importJSON (./. + "/repo-${grapheneOSRelease}.json");

  apv.enable = mkIf (elem config.deviceFamily phoneDeviceFamilies) (mkDefault true);
  apv.buildID = mkDefault (
    if (elem config.deviceFamily [ "sunfish" "bonito"]) then "RQ1A.210105.002"
    else "RQ1A.210105.003"
  );

  # Not strictly necessary for me to set these, since I override the source.dirs above
  source.manifest.url = mkDefault "https://github.com/GrapheneOS/platform_manifest.git";
  source.manifest.rev = mkDefault "refs/tags/${grapheneOSRelease}";

  warnings = (optional ((config.device != null) && !(elem config.deviceFamily supportedDeviceFamilies))
    "${config.device} is not a supported device for GrapheneOS")
    ++ (optional (config.androidVersion != 11) "Unsupported androidVersion (!= 11) for GrapheneOS");
}
{
  # Disable setting SCHED_BATCH in soong. Brings in a new dependency and the nix-daemon could do that anyway.
  source.dirs."build/soong".patches = [
    (pkgs.fetchpatch {
      url = "https://github.com/GrapheneOS/platform_build_soong/commit/76723b5745f08e88efa99295fbb53ed60e80af92.patch";
      sha256 = "0vvairss3h3f9ybfgxihp5i8yk0rsnyhpvkm473g6dc49lv90ggq";
      revert = true;
    })
  ];

  # No need to include these in AOSP build source since we build separately
  source.dirs."kernel/google/marlin".enable = false;
  source.dirs."kernel/google/wahoo".enable = false;
  source.dirs."kernel/google/crosshatch".enable = false;
  source.dirs."kernel/google/bonito".enable = false;
  source.dirs."kernel/google/coral".enable = false;
  source.dirs."kernel/google/sunfish".enable = false;

  # Enable Vanadium (GraphaneOS's chromium fork).
  apps.vanadium.enable = mkDefault true;
  webview.vanadium.enable = mkDefault true;
  webview.vanadium.availableByDefault = mkDefault true;

  apps.seedvault.enable = mkDefault true;

  # Remove upstream prebuilt versions from build. We build from source ourselves.
  removedProductPackages = [ "TrichromeWebView" "TrichromeChrome" "webview" "Seedvault" ];
  source.dirs."external/vanadium".enable = false;
  source.dirs."external/seedvault".enable = false;
  source.dirs."vendor/android-prepare-vendor".enable = false; # Use our own pinned version

  # GrapheneOS just disables apex updating wholesale
  signing.apex.enable = false;

  # Don't include updater by default since it would download updates signed with grapheneos's keys.
  # TODO: Encourage user to set apps.updater.enable
  source.dirs."packages/apps/Updater".enable = false;

  # Leave the existing auditor in the build--just in case the user wants to
  # audit devices using the official upstream build
}
(mkIf (elem config.deviceFamily [ "crosshatch" "bonito" "coral" "sunfish" ]) {
  kernel.useCustom = mkDefault true;
  kernel.src = mkDefault config.source.dirs."kernel/google/${config.kernel.name}".src;
  kernel.configName = config.device;
  kernel.relpath = "device/google/${config.device}-kernel";
})
(mkIf (elem config.deviceFamily [ "crosshatch" "bonito" ]) {
  # Hack for crosshatch/bonito since they use submodules and repo2nix doesn't support that yet.
  kernel.src = pkgs.fetchFromGitHub {
    owner = "GrapheneOS";
    repo = "kernel_google_crosshatch";
    rev = grapheneOSRelease;
    sha256 = "0nh7j70vjldfx9l612f6mv704dj25gsjbgxyk9gqawymhckqyzc0";
    fetchSubmodules = true;
  };
})
(mkIf (config.device == "sargo") { # TODO: Ugly hack
  kernel.configName = mkForce "bonito";
  kernel.relpath = mkForce "device/google/bonito-kernel";
})
(mkIf (config.device == "blueline") { # TODO: Ugly hack
  kernel.relpath = mkForce "device/google/blueline-kernel";
})
(mkIf (config.deviceFamily == "coral") {
  kernel.configName = mkForce "floral";
  kernel.src = pkgs.fetchFromGitHub {
    owner = "GrapheneOS";
    repo = "kernel_google_coral";
    rev = grapheneOSRelease;
    sha256 = "06klgyb3rh5awghrzr04msmpglbvlp2ldvkr9q6w6kxwlcf4bkmg";
    fetchSubmodules = true;
  };
})
(mkIf (config.deviceFamily == "sunfish") {
  kernel.src = pkgs.fetchFromGitHub {
    owner = "GrapheneOS";
    repo = "kernel_google_sunfish";
    rev = grapheneOSRelease;
    sha256 = "1in37ycdis4pqmp3xin5m4zxwn1g12kpn5ps8lm5lqj0n0cigis6";
    fetchSubmodules = true;
  };
})
])
