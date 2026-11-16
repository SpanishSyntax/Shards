{
  description = "Stowaway - Wayland clipboard & character picker overlay";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    forAllSystems = fn:
      nixpkgs.lib.genAttrs nixpkgs.lib.platforms.linux (
        system: fn nixpkgs.legacyPackages.${system}
      );
  in {
    packages = forAllSystems (pkgs: rec {
      stowaway = pkgs.callPackage ./nix {};
      default = stowaway;
    });

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          cmake
          ninja
          pkg-config
          qt6.qtbase
          qt6.qtdeclarative
          qt6.qtsvg
          quickshell
          wtype
          wl-clipboard
          cliphist
        ];
      };
    });

    homeManagerModules.default = { config, lib, pkgs, ... }:
      with lib;
      let
        pkg = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
        stowawayCfg = config.programs.stowaway;
        shardsCfg = config.programs.shards;
        enabled = stowawayCfg.enable || shardsCfg.enable;
        activeCfg = if stowawayCfg.enable then stowawayCfg else shardsCfg;
      in {
        options.programs.stowaway = {
          enable = mkEnableOption "Stowaway Wayland clipboard & emoji overlay";
          package = mkOption {
            type = types.package;
            default = pkg;
            description = "The stowaway package to use.";
          };
          daemon = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Whether to run Stowaway as a background daemon for instant overlay (<10ms).";
            };
          };
        };

        options.programs.shards = {
          enable = mkEnableOption "Alias for programs.stowaway";
          package = mkOption {
            type = types.package;
            default = pkg;
            description = "The stowaway package to use.";
          };
          daemon = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Whether to run Stowaway as a background daemon for instant overlay (<10ms).";
            };
          };
        };

        config = mkIf enabled {
          home.packages = [ activeCfg.package ];

          systemd.user.services.stowaway = mkIf activeCfg.daemon.enable {
            Unit = {
              Description = "Stowaway Wayland Clipboard Daemon";
              PartOf = [ "graphical-session.target" ];
              After = [ "graphical-session.target" ];
            };
            Service = {
              ExecStart = "${activeCfg.package}/bin/stowaway --daemon --foreground";
              Restart = "on-failure";
              RestartSec = "1s";
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
          };
        };
      };
  };
}
