{ config, lib, pkgs, ... }:

let

  localPackages = (import ./pkgs/all-packages.nix) {
  inherit config lib pkgs;
};

# TODO: pin to a specific version of nixpkgs like this:
# nixpkgsMaster = import ((import <nixpkgs> { }).fetchFromGitHub {
#   owner = "NixOS";
#   repo = "nixpkgs";
#   rev = "fd22d671ecad983fbbbd92c4626204f09c9af8ff";
#   sha256 = "0pn8w5v2b7c82nr0zbb91bfzylr97hq3knwhlc8xhzibhp0d723a";
# }) { config = { }; };
# then, for example: nixpkgsMaster.pkgs.nodejs-8_x

in {
  imports = [
    ./pkgs/overrides.nix
    ./httpd.nix
  ];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    aspell
    aspellDicts.en
    bind
    coreutils
    curl
    direnv
    emacs
    ffmpeg
    file
    findutils
    fzf
    gitAndTools.git-crypt
    gitAndTools.gitFull
    gnumake
    gnupg
    gnused
    gnutar
    haskellPackages.ShellCheck
    htop
    isync
    localPackages.nodePackages.reddit-oauth-helper
    msmtp
    mu
    nix-prefetch-scripts
    nix-repl
    nixops
    openssh
    pass
    pwgen
    reattach-to-user-namespace
    rsync
    sift
    silver-searcher
    socat
    stow
    syncthing
    tmux
    tree
    unrar
    unzip
    wget
    which

    # mpv

    apacheHttpd
    awsebcli
    flow
    jekyll
    lftp
    localPackages.fontcustom
    localPackages.nodePackages."@jasondibenedetto/plop"
    localPackages.nodePackages.eslint-cli
    localPackages.nodePackages.flow-typed
    localPackages.nodePackages.grunt-cli
    localPackages.nodePackages.imapnotify
    localPackages.nodePackages.prettier-eslint-cli
    localPackages.nodePackages.react-native-cli
    localPackages.nodePackages.tern
    localPackages.nodePackages.wscat
    localPackages.nodePackages.yarn
    localPackages.scss-lint
    nodePackages_6_x.node2nix
    nodejs-8_x
    php
    php70Packages.composer
    php70Packages.phpcbf
    php70Packages.phpcs
    watchman
  ];

  nixpkgs.config.allowBroken = true;

  # https://github.com/benhutchins/.dotfiles/blob/master/Mac.md#fix-mac-issues

  environment.variables = {
    # If you don't do this, Emacs will throw errors like this because it can't
    # find the dictionary files:
    # Starting new Ispell process /run/current-system/sw/bin/aspell with english dictionary...
    # Error enabling Flyspell mode:
    # (Error: The file "/nix/store/ ... /lib/aspell/english" can not be opened for reading.)
    ASPELL_CONF = "data-dir /run/current-system/sw/lib/aspell";
  };

  environment.shellAliases = {
    emacs = "$(dirname $(dirname $(readlink -f $(which Emacs))))/Applications/Emacs.app/Contents/MacOS/Emacs";
  };

  programs.zsh = {
    enable = true;
    enableFzfCompletion = true;
    enableFzfGit = true;
    enableFzfHistory = true;
  };

  environment.pathsToLink = [
    "/share/emacs"   # Necessary for emacs support files (mu4e)
  ];

  environment.etc."ssl/certs/ca-certificates.crt".source =
    "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  nixpkgs.config.allowUnfree = true;

  # github.com/facebook/react-native/issues/9309#issuecomment-238966924
  environment.etc."sysctl.conf" = {
    text = ''
      kern.maxfiles=10485760
      kern.maxfilesperproc=1048576
    '';
  };

  nixpkgs.config.packageOverrides = pkgs: {
    sift = lib.overrideDerivation pkgs.sift (attrs: {
      postInstall = ''
        install_name_tool -delete_rpath $out/lib -add_rpath $bin $bin/bin/sift
      '';
    });

    # Flow is in nixpkgs but compilation fails at the moment due to a problem
    # with ocaml on Darwin.
    flow = with pkgs; stdenv.mkDerivation rec {
      name = "flow";
      version = "0.53.1";

      src = fetchurl {
        url = "https://github.com/facebook/flow/releases/download/v${version}/${name}-osx-v${version}.zip";
        sha256 = "0y2qkq2ba904pd5rri7b9943z8nw1886h61ny9a467g1d2w6q26x";
      };

      buildInputs = [ unzip ];

      dontBuild = true;

      installPhase = ''
        mkdir -p "$out/tmp";
        unzip -d $out/tmp ${src}
        mkdir -p "$out/bin";
        mv $out/tmp/flow/flow $out/bin
        rm -rf "$out/tmp"
      '';
    };

    syncthing = with pkgs; stdenv.mkDerivation rec {
      name = "syncthing";
      version = "0.14.32";

      src = fetchurl {
        url = "https://github.com/syncthing/syncthing/releases/download/v${version}/syncthing-macosx-amd64-v${version}.tar.gz";
        sha256 = "0588xc7s3q68znxdvgysyvprdr13pmmwnj1sy5qms50hqizyima9";
      };

      buildInputs = [ gnutar ];

      dontBuild = true;

      installPhase = ''
        mkdir -p "$out/tmp";
        tar xf ${src} -C "$out/tmp" --strip-components 1
        mkdir -p "$out/bin";
        mv "$out/tmp/syncthing" "$out/bin"
        rm -rf "$out/tmp"
      '';
    };

    emacs = lib.overrideDerivation
      (pkgs.emacs.override { srcRepo = true; }) (attrs: {
      name = "emacs-git";
      src = pkgs.fetchgit {
        url = "git://git.sv.gnu.org/emacs.git";
        sha256 = "1424jc12qq2fhcf10rh0m0ssznr5v3p284xi9aw6fpnni969cr8f";
        rev = "273f4bde39af5d87f10fd58f35b666dfa8a996a3";
      };
      patches = [];
    });

    nodejs-8_x = pkgs.nodejs-8_x.overrideAttrs (attrs: rec {
      name = "nodejs-${version}";
      version = "8.3.0";
      src = pkgs.fetchurl {
        url = "https://nodejs.org/download/release/v${version}/node-v${version}.tar.xz";
        sha256 = "0lbfp7j73ig0xa3gh8wnl4g3lji7lm34l0ybfys4swl187c3da63";
      };
    });
  };

  launchd.user.agents.syncthing = {
    serviceConfig.ProgramArguments = [ "${pkgs.syncthing}/bin/syncthing" "-no-browser" "-no-restart" ];
    serviceConfig.EnvironmentVariables = {
      HOME = "/Users/rkm";
      STNOUPGRADE = "1"; # disable spammy automatic upgrade check
    };
    serviceConfig.KeepAlive = true;
    serviceConfig.ProcessType = "Background";
    serviceConfig.StandardOutPath = "/Users/rkm/Library/Logs/Syncthing.log";
    serviceConfig.StandardErrorPath = "/Users/rkm/Library/Logs/Syncthing-Errors.log";
    serviceConfig.LowPriorityIO = true;
  };

  services.httpd.enable = true;

  # Recreate /run/current-system symlink after boot.
  services.activate-system.enable = true;
}
