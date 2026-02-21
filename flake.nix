{
  description = "Ian's dotfiles";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    nixpkgs-stable = {
      url = "github:NixOS/nixpkgs/nixos-25.05";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-stable = {
      url = "github:nix-community/home-manager/release-25.05";
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
      url = "github:anomalyco/opencode/v1.2.6";
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

    claude-code-nix = {
      url = "github:sadjow/claude-code-nix/v2.1.50";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    beads = {
      url = "github:steveyegge/beads/v0.49.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, mac-app-util, nixvim, rust-overlay, flake-utils, opencode, disko, sops-nix, nixpkgs-stable, home-manager-stable, screeny, mercy, grpc-proxier, claude-code-nix, beads, ... } @ inputs:
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
            screeny.nixosModules.default
            mercy.nixosModules.default
            grpc-proxier.nixosModules.default
            { nixpkgs.overlays = [ screeny.overlays.default grpc-proxier.overlays.default ]; }
            ./hosts/pakhet/configuration.nix
            home-manager-stable.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit user inputs; };
              home-manager.users.${user.username} = {
                imports = [
                  ./hosts/pakhet/home.nix
                ];
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
    };
}
