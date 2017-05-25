{ config, lib, pkgs, ... }:

let

localPackages = (import ./pkgs/all-packages.nix) {
    inherit config lib pkgs;
};

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
    msmtp
    nix-repl
    nixops
    notmuch
    openssh
    pass
    pwgen
    reattach-to-user-namespace
    rsync
    sift
    silver-searcher
    stow
    syncthing
    tmux
    tree
    unrar
    unzip
    wget
    which

    # not supported on darwin?
    # mopidy
    # mopidy-spotify
    # mopidy-youtube
    # mopidy-soundcloud
    mpv

    apacheHttpd
    flow
    jekyll
    lftp
    localPackages.nodePackages."@jasondibenedetto/plop"
    localPackages.nodePackages.eslint-cli
    localPackages.nodePackages.flow-typed
    localPackages.nodePackages.grunt-cli
    localPackages.nodePackages.imapnotify
    localPackages.nodePackages.react-native-cli
    localPackages.nodePackages.tern
    localPackages.nodePackages.webpack
    localPackages.nodePackages.wscat
    localPackages.nodePackages.yarn
    localPackages.scss-lint
    nodePackages_6_x.node2nix
    nodejs-7_x
    php
    php70Packages.composer
    php70Packages.phpcbf
    php70Packages.phpcs
    watchman
  ];

  nixpkgs.config.allowBroken = true;

  # https://github.com/benhutchins/.dotfiles/blob/master/Mac.md#fix-mac-issues

  # environment.variables = {
  #   # this is the key to getting aspell to shut up?
  #   # nix-repl> "${pkgs.aspellDicts.en}/lib/aspell"
  #   # "/nix/store/6523yd8172rghf51vcknhrrvpd24sg45-aspell-dict-en-2016.06.26-0/lib/aspell"
  #   ASPELL_CONF = "data-dir ${pkgs.aspellDicts.en}/lib/aspell";
  # };

  environment.shellAliases = {
    emacs = "$(dirname $(dirname $(readlink -f $(which Emacs))))/Applications/Emacs.app/Contents/MacOS/Emacs";
  };

  # Create /etc/bashrc that loads the nix-darwin environment.
  # programs.bash.enable = true;

  programs.zsh = {
    enable = true;
    enableFzfCompletion = true;
    enableFzfGit = true;
    enableFzfHistory = true;
  };

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
      version = "0.47.0";

      src = fetchurl {
        url = "https://github.com/facebook/flow/releases/download/v${version}/${name}-osx-v${version}.zip";
        sha256 = "08wr9dl9rr6qaf6x4wpwiq0pvll5spyxg0i5nmj1np8p7xjl1wzv";
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
      version = "0.14.27";

      src = fetchurl {
        url = "https://github.com/syncthing/syncthing/releases/download/v${version}/syncthing-macosx-amd64-v${version}.tar.gz";
        sha256 = "1ami5d1p6cws2m0va7fjqpzbg7rbkxiiv7y7is1h5pgwp302ky1a";
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
