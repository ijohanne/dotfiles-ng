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
      url = "github:sadjow/claude-code-nix/v2.1.72";
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

    themailer-wrapper = {
      url = "github:ijohanne/themailer-wrapper";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    perlpimpnet = {
      url = "github:ijohanne/perlpimpnet";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    proton-port-sync = {
      url = "github:ijohanne/proton-port-sync";
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
      themailer-wrapper,
      perlpimpnet,
      proton-port-sync,
      ...
    }@inputs:
    let
      users = import ./configs/users.nix;

      mkPkgsUnstable = system: import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };
        overlays = [ rust-overlay.overlays.default ];
      };

      mkNixosHost = { pkgsLib, system, modules, primaryUser ? "ij" }:
        pkgsLib.nixosSystem {
          inherit system modules;
          specialArgs = { inherit inputs self users; user = users.${primaryUser}; };
        };

      mkDarwinHost = { system, modules, primaryUser ? "ij" }:
        nix-darwin.lib.darwinSystem {
          inherit system modules;
          specialArgs = { inherit inputs self users; user = users.${primaryUser}; };
        };

      mkHomeManagerModule = {
        homeManagerModule,
        hmUsers,
        backupFileExtension ? null,
        extraSpecialArgs ? {},
      }:
        [
          homeManagerModule
          ({ ... }: {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit users inputs; } // extraSpecialArgs;
              users = nixpkgs.lib.mapAttrs (username: imports: {
                imports = imports ++ [
                  { _module.args.user = users.${username}; }
                ];
              }) hmUsers;
            }
            // nixpkgs.lib.optionalAttrs (backupFileExtension != null) {
              inherit backupFileExtension;
            };
          })
        ];
    in
    {
      nixosConfigurations = {
        ij-desktop = mkNixosHost {
          pkgsLib = nixpkgs.lib;
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            ./hosts/ij-desktop/disko.nix
            ./hosts/ij-desktop/configuration.nix
          ] ++ mkHomeManagerModule {
            homeManagerModule = home-manager.nixosModules.home-manager;
            extraSpecialArgs = { pkgs-unstable = mkPkgsUnstable "x86_64-linux"; };
            hmUsers.${users.ij.username} = [
              ./hosts/ij-desktop/home.nix
              inputs.nixvim.homeModules.nixvim
            ];
          };
        };

        pakhet = mkNixosHost {
          pkgsLib = nixpkgs-stable.lib;
          system = "x86_64-linux";
          modules = [
            sops-nix.nixosModules.sops
            nixos-mailserver.nixosModules.default
            screeny.nixosModules.default
            mercy.nixosModules.default
            grpc-proxier.nixosModules.default
            pdf-detective.nixosModules.default
            shouldidrinktoday.nixosModules.default
            unixpimpsnet.nixosModules.default
            themailer-wrapper.nixosModules.default
            perlpimpnet.nixosModules.default
            {
              nixpkgs.overlays = [
                screeny.overlays.default
              ];
            }
            ./hosts/pakhet/configuration.nix
          ] ++ mkHomeManagerModule {
            homeManagerModule = home-manager-stable.nixosModules.home-manager;
            extraSpecialArgs = { pkgs-unstable = mkPkgsUnstable "x86_64-linux"; };
            hmUsers = {
              ${users.ij.username} = [
                ./hosts/pakhet/home-ij.nix
                inputs.nixvim.homeModules.nixvim
              ];
              ${users.mj.username} = [ ./hosts/pakhet/home-mj.nix ];
            };
          };
        };

        goose = mkNixosHost {
          pkgsLib = nixpkgs-stable.lib;
          system = "x86_64-linux";
          modules = [
            sops-nix.nixosModules.sops
            ijohanne-nur.nixosModules.multicast-relay
            ijohanne-nur.nixosModules.prometheus-hue-exporter
            ijohanne-nur.nixosModules.prometheus-nftables-exporter
            ijohanne-nur.nixosModules.prometheus-tplink-p110-exporter
            ./hosts/goose/configuration.nix
          ] ++ mkHomeManagerModule {
            homeManagerModule = home-manager-stable.nixosModules.home-manager;
            backupFileExtension = "bak";
            extraSpecialArgs = { pkgs-unstable = mkPkgsUnstable "x86_64-linux"; };
            hmUsers = {
              ${users.ij.username} = [
                ./hosts/goose/home-ij.nix
                inputs.nixvim.homeModules.nixvim
              ];
              ${users.mj.username} = [ ./hosts/goose/home-mj.nix ];
            };
          };
        };

        anubis = mkNixosHost {
          pkgsLib = nixpkgs-stable.lib;
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            proton-port-sync.nixosModules.default
            ./hosts/anubis/disko.nix
            ./hosts/anubis/configuration.nix
          ];
        };

        khosu = mkNixosHost {
          pkgsLib = nixpkgs-stable.lib;
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            ./hosts/khosu/disko.nix
            ./hosts/khosu/configuration.nix
          ] ++ mkHomeManagerModule {
            homeManagerModule = home-manager-stable.nixosModules.home-manager;
            extraSpecialArgs = { pkgs-unstable = mkPkgsUnstable "x86_64-linux"; };
            hmUsers = {
              ${users.ij.username} = [
                ./hosts/khosu/home-ij.nix
                inputs.nixvim.homeModules.nixvim
              ];
              ${users.mj.username} = [ ./hosts/khosu/home-mj.nix ];
            };
          };
        };

        bhyve-image = mkNixosHost {
          pkgsLib = nixpkgs-stable.lib;
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            ./hosts/bhyve-image/disko.nix
            ./hosts/bhyve-image/configuration.nix
          ];
        };

        bhyve-image-server = mkNixosHost {
          pkgsLib = nixpkgs-stable.lib;
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            ./hosts/bhyve-image/disko.nix
            ./hosts/bhyve-image/configuration-server.nix
          ] ++ mkHomeManagerModule {
            homeManagerModule = home-manager-stable.nixosModules.home-manager;
            extraSpecialArgs = { pkgs-unstable = mkPkgsUnstable "x86_64-linux"; };
            hmUsers = {
              ${users.ij.username} = [
                ./hosts/bhyve-image/home-ij.nix
                inputs.nixvim.homeModules.nixvim
              ];
              ${users.mj.username} = [ ./hosts/bhyve-image/home-mj.nix ];
            };
          };
        };

        rtsp-dev-vm = mkNixosHost {
          pkgsLib = nixpkgs.lib;
          system = "aarch64-linux";
          modules = [
            ./hosts/rtsp-dev-vm/configuration.nix
          ];
        };

        rpi4-stable = mkNixosHost {
          pkgsLib = nixpkgs-stable.lib;
          system = "aarch64-linux";
          modules = [
            ./hosts/rpi4-image/stable/configuration.nix
          ];
        };

        rpi4-unstable = mkNixosHost {
          pkgsLib = nixpkgs.lib;
          system = "aarch64-linux";
          modules = [
            ./hosts/rpi4-image/unstable/configuration.nix
          ];
        };
      };

      images = {
        rpi4-stable = self.nixosConfigurations.rpi4-stable.config.system.build.sdImage;
        rpi4-unstable = self.nixosConfigurations.rpi4-unstable.config.system.build.sdImage;
        bhyve = self.nixosConfigurations.bhyve-image.config.system.build.diskoImages;
        bhyve-server = self.nixosConfigurations.bhyve-image-server.config.system.build.diskoImages;
        rtsp-dev-vm = self.nixosConfigurations.rtsp-dev-vm.config.system.build.vm;
      };

      darwinConfigurations = {
        macbook = mkDarwinHost {
          system = "aarch64-darwin";
          modules = [
            mac-app-util.darwinModules.default
            sops-nix.darwinModules.sops
            ./hosts/macbook/configuration.nix
          ] ++ mkHomeManagerModule {
            homeManagerModule = home-manager.darwinModules.home-manager;
            backupFileExtension = "backup";
            extraSpecialArgs = { pkgs-unstable = mkPkgsUnstable "aarch64-darwin"; };
            hmUsers.${users.ij.username} = [
              mac-app-util.homeManagerModules.default
              ./hosts/macbook/home.nix
              inputs.nixvim.homeModules.nixvim
            ];
          };
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
        nix-repl-unstable = pkgs.writeShellScriptBin "nix-repl-unstable" ''
          exec nix repl --expr "import (builtins.getFlake \"${nixpkgs}\") { system = \"${system}\"; config.allowUnfree = true; }"
        '';
        nix-repl-stable = pkgs.writeShellScriptBin "nix-repl-stable" ''
          exec nix repl --expr "import (builtins.getFlake \"${nixpkgs-stable}\") { system = \"${system}\"; config.allowUnfree = true; }"
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
        jnlp-jdk = if pkgs.stdenv.isDarwin then pkgs.zulu8 else pkgs.jdk8;
        jnlp-run = pkgs.writeShellScriptBin "jnlp-run" ''
          export PATH="${pkgs.lib.makeBinPath [ jnlp-jdk pkgs.xmlstarlet pkgs.curl pkgs.coreutils ]}"

          if [ -z "$1" ]; then
            echo "Usage: jnlp-run <file.jnlp>" >&2
            exit 1
          fi

          jnlp="$1"

          codebase=$(xml sel -t -v '/jnlp/@codebase' "$jnlp")
          jar_href=$(xml sel -t -v '/jnlp/resources/jar/@href' "$jnlp")
          jar_url="''${codebase}/''${jar_href}"

          os=$(uname -s)
          arch=$(uname -m)
          case "''${os}-''${arch}" in
            Linux-x86_64)  native_href=$(xml sel -t -v '//resources[@os="Linux" and (@arch="x86_64" or @arch="amd64")]/nativelib/@href' "$jnlp" 2>/dev/null) ;;
            Linux-i*86)    native_href=$(xml sel -t -v '//resources[@os="Linux" and (@arch="x86" or @arch="i386")]/nativelib/@href' "$jnlp" 2>/dev/null) ;;
            *)             native_href="" ;;
          esac

          mapfile -t args < <(xml sel -t -v '/jnlp/application-desc/argument' -n "$jnlp")

          tmpdir=$(mktemp -d)
          trap 'rm -rf "$tmpdir"' EXIT

          echo "Downloading $jar_url ..."
          curl -ksSL -o "$tmpdir/app.jar" "$jar_url"

          if [ -n "$native_href" ]; then
            native_url="''${codebase}/''${native_href}"
            echo "Downloading native lib $native_url ..."
            curl -ksSL -o "$tmpdir/native.jar" "$native_url"
            (cd "$tmpdir" && jar xf native.jar)
          fi

          echo "Launching with $(java -version 2>&1 | head -1) ..."
          exec java -Djava.library.path="$tmpdir" -jar "$tmpdir/app.jar" "''${args[@]}"
        '';
        pkgsWithRust = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };
        rustToolchain = pkgsWithRust.rust-bin.stable.latest.default;
        setup-template = pkgs.rustPlatform.buildRustPackage {
          pname = "setup-template";
          version = "0.1.0";
          src = ./tools/setup-template;
          cargoLock.lockFile = ./tools/setup-template/Cargo.lock;
          nativeBuildInputs = [ rustToolchain ];
        };
      in
      {
        packages.setup-template = setup-template;

        apps.setup-template = {
          type = "app";
          program = "${setup-template}/bin/setup-template";
        };

        checks.setup-template = setup-template.overrideAttrs (old: {
          doCheck = true;
        });

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nixpkgs-fmt
            sops
            age
            nix-output-monitor
            bd
            bd-init
            ssh-to-age-remote
            nix-repl-unstable
            nix-repl-stable
            jnlp-run
          ] ++ [
            rustToolchain
            pkgsWithRust.rust-bin.stable.latest.rust-analyzer
          ];
          shellHook = ''
            echo ""
            echo "dotfiles-ng dev shell"
            echo "─────────────────────────────────────────────"
            echo "  nix-repl-unstable     nixpkgs unstable repl"
            echo "  nix-repl-stable       nixpkgs stable repl"
            echo "  bd ready              available issues"
            echo "  bd list               all issues"
            echo "  jnlp-run <file.jnlp>  launch Kimsufi IP KVM"
            echo "  sops <file>           edit encrypted secret"
            echo "  ssh-to-age-remote     convert SSH host key to age"
            echo "  nix flake check       validate all configs"
            echo ""
          '';
        };
      }
    );
}
