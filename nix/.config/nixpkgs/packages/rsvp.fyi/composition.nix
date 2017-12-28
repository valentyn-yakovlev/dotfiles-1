# This file has been generated by node2nix 1.1.1. Do not edit!

{pkgs ? import <nixpkgs> {
    inherit system;
  }, system ? builtins.currentSystem, nodejs ? pkgs."nodejs-5_x"}:

let
  globalBuildInputs = pkgs.lib.attrValues (import ./supplement.nix {
    inherit nodeEnv;
    inherit (pkgs) fetchurl fetchgit;
  });
  nodeEnv = import ../node-packages/node-env.nix {
    inherit (pkgs) stdenv python2 utillinux runCommand writeTextFile;
    inherit nodejs;
  };
in
import ./node-packages.nix {
  inherit (pkgs) fetchurl fetchgit;
  inherit nodeEnv globalBuildInputs;
}