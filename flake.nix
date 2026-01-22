{
  description = "Ian's dotfiles";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
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
      url = "github:anomalyco/opencode/v1.1.31";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, mac-app-util, nixvim, rust-overlay, flake-utils, opencode, ... } @ inputs:
    let
      user = import ./lib/user.nix;
    in
    {
      nixosConfigurations = {
        ij-desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs self user; };
          modules = [
            ./hosts/ij-desktop/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit user inputs; };
              home-manager.users.${user.username} = {
                imports = [ ./hosts/ij-desktop/home.nix ];
              };
            }
          ];
        };
      };

      darwinConfigurations = {
        macbook = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit inputs self user; };
          modules = [
            mac-app-util.darwinModules.default
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
        x86_64-linux = {
          nixos = self.nixosConfigurations.ij-desktop.config.system.build.toplevel;
        };
        aarch64-darwin = {
          darwin = self.darwinConfigurations.macbook.system;
        };
      };
    };
}
