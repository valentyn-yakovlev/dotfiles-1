{ config, lib, pkgs, ... }:

{
  imports = [
    "${((import <nixpkgs> {}).callPackage ../lib/home-manager.nix {})}/nixos"
  ];

  home-manager = {
    users = {
      eqyiel = lib.mkMerge [
        {
          # https://github.com/rycee/home-manager/issues/254
          manual.manpages.enable = false;
        }
        (import ../../../../home/config/syncthing {
          inherit lib pkgs;
          actualHostname = config.networking.hostName;
        })
          (import ../../../../home/config/urlwatch)
        ];
    };
  };
}
