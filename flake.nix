{
  description = "Ian's dotfiles";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    nixpkgs-stable = {
      url = "github:NixOS/nixpkgs/nixos-25.11";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-stable = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util = {
      url = "github:hraban/mac-app-util";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fish-eza = {
      url = "github:givensuman/fish-eza";
      flake = false;
    };

    opencode = {
      url = "github:anomalyco/opencode/v1.2.15";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    screeny = {
      url = "github:ijohanne/screeny";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    mercy = {
      url = "github:ijohanne/mercy";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    grpc-proxier = {
      url = "github:ijohanne/grpc-proxier";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    pdf-detective = {
      url = "github:ijohanne/pdf-detective";
    };

    claude-code-nix = {
      url = "github:sadjow/claude-code-nix/v2.1.56";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    beads = {
      url = "github:steveyegge/beads/v0.49.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ijohanne-nur = {
      url = "github:ijohanne/nur-packages";
    };

    nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    shouldidrinktoday = {
      url = "github:ijohanne/shouldidrinktoday";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    unixpimpsnet = {
      url = "github:ijohanne/unixpimpsnet";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      mac-app-util,
      nixvim,
      rust-overlay,
      flake-utils,
      opencode,
      disko,
      sops-nix,
      nixpkgs-stable,
      home-manager-stable,
      screeny,
      mercy,
      grpc-proxier,
      pdf-detective,
      claude-code-nix,
      beads,
      ijohanne-nur,
      nixos-mailserver,
      shouldidrinktoday,
      unixpimpsnet,
      ...
    }@inputs:
    let
      user = import ./lib/user.nix;
    in
    {
      nixosConfigurations = {
        ij-desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs self user; };
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            ./hosts/ij-desktop/disko.nix
            ./hosts/ij-desktop/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit user inputs; };
              home-manager.users.${user.username} = {
                imports = [
                  ./hosts/ij-desktop/home.nix
                  inputs.nixvim.homeModules.nixvim
                ];
              };
            }
          ];
        };

        pakhet = nixpkgs-stable.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs self user; };
          modules = [
            sops-nix.nixosModules.sops
            nixos-mailserver.nixosModules.default
            screeny.nixosModules.default
            mercy.nixosModules.default
            grpc-proxier.nixosModules.default
            pdf-detective.nixosModules.default
            shouldidrinktoday.nixosModules.default
            unixpimpsnet.nixosModules.default
            {
              nixpkgs.overlays = [
                screeny.overlays.default
                grpc-proxier.overlays.default
              ];
            }
            ./hosts/pakhet/configuration.nix
            home-manager-stable.nixosModules.home-manager
            ({ config, pkgs, ... }: {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit user inputs; };
              home-manager.users.${user.username} = {
                imports = [
                  ./hosts/pakhet/home.nix
                ];
              };
              home-manager.users.mj = {
                imports = [ ./configs/users/mj.nix ];
                home.packages = [
                  (pkgs.writeShellScriptBin "nixos-rebuild" ''
                    cd ~/git/dotfiles-ng && git add -A && sudo nixos-rebuild switch --flake .#${config.networking.hostName}
                  '')
                ];
              };
            })
          ];
        };

        goose = nixpkgs-stable.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs self user; };
          modules = [
            sops-nix.nixosModules.sops
            ijohanne-nur.nixosModules.multicast-relay
            #ijohanne-nur.nixosModules.prometheus-hue-exporter
            #ijohanne-nur.nixosModules.prometheus-nftables-exporter
            #ijohanne-nur.nixosModules.prometheus-netatmo-exporter
            #ijohanne-nur.nixosModules.prometheus-teamspeak3-exporter
            {
              nixpkgs.overlays = [
                ijohanne-nur.overlays.default
              ];
            }
            ./hosts/goose/configuration.nix
            home-manager-stable.nixosModules.home-manager
            ({ config, pkgs, ... }: {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit user inputs; };
              home-manager.users.${user.username} = {
                imports = [
                  ./hosts/goose/home.nix
                ];
              };
              home-manager.users.mj = {
                imports = [ ./configs/users/mj.nix ];
                home.packages = [
                  (pkgs.writeShellScriptBin "nixos-rebuild" ''
                    cd ~/git/dotfiles-ng && git add -A && sudo nixos-rebuild switch --flake .#${config.networking.hostName}
                  '')
                ];
              };
            })
          ];
        };

        khosu = nixpkgs-stable.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs self user; };
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            ./hosts/khosu/disko.nix
            ./hosts/khosu/configuration.nix
            home-manager-stable.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit user inputs; };
              home-manager.users.${user.username} = {
                imports = [ ./hosts/khosu/home.nix ];
              };
            }
          ];
        };

        rpi4-stable = nixpkgs-stable.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs self user; };
          modules = [
            ./hosts/rpi4-image/stable/configuration.nix
          ];
        };

        rpi4-unstable = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs self user; };
          modules = [
            ./hosts/rpi4-image/unstable/configuration.nix
          ];
        };
      };

      images = {
        rpi4-stable = self.nixosConfigurations.rpi4-stable.config.system.build.sdImage;
        rpi4-unstable = self.nixosConfigurations.rpi4-unstable.config.system.build.sdImage;
      };

      darwinConfigurations = {
        macbook = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit inputs self user; };
          modules = [
            mac-app-util.darwinModules.default
            sops-nix.darwinModules.sops
            ./hosts/macbook/configuration.nix
            ./hosts/macbook/software.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = { inherit user inputs; };
              home-manager.users.${user.username} = {
                imports = [
                  mac-app-util.homeManagerModules.default
                  ./hosts/macbook/home.nix
                  inputs.nixvim.homeModules.nixvim
                ];
              };
            }
          ];
        };
      };

      checks = {
        aarch64-darwin = {
          darwin = self.darwinConfigurations.macbook.system;
        };
      };
    }
    // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        bd = beads.packages.${system}.default;
        bd-init = pkgs.writeShellScriptBin "bd-init" ''
          set -euo pipefail
          ${bd}/bin/bd init --branch beads-sync "$@"
          rm -f AGENTS.md
        '';
        ssh-to-age-remote = pkgs.writeShellScriptBin "ssh-to-age-remote" ''
          set -euo pipefail
          if [ $# -ne 1 ]; then
            echo "Usage: ssh-to-age-remote <user@host>" >&2
            exit 1
          fi
          ${pkgs.openssh}/bin/ssh-keyscan "$1" 2>/dev/null \
            | ${pkgs.ssh-to-age}/bin/ssh-to-age 2>/dev/null
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nixpkgs-fmt
            sops
            age
            nix-output-monitor
            bd
            bd-init
            ssh-to-age-remote
          ];
        };
      }
    );
}
