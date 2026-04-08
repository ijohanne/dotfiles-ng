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
      url = "github:ijohanne/grpc-proxier/fix-hostplatform-system";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    pdf-detective = {
      url = "github:ijohanne/pdf-detective/fix-hostplatform-system";
    };

    claude-code-nix = {
      url = "github:sadjow/claude-code-nix/v2.1.84";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents-nix = {
      url = "github:numtide/llm-agents.nix";
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

    vardrun = {
      url = "github:uptimeplaza/vardrun";
    };

    leita = {
      url = "github:uptimeplaza/leita";
    };

    callis = {
      url = "github:Uptimeplaza/callis";
    };

    t3code-nix = {
      url = "github:Sawrz/t3code-nix";
    };

    uptimeplaza-checker-dns = {
      url = "github:Uptimeplaza/checker-dns";
      flake = false;
    };

    uptimeplaza-checker-fping = {
      url = "github:Uptimeplaza/checker-fping";
      flake = false;
    };

    uptimeplaza-checker-ping = {
      url = "github:Uptimeplaza/checker-ping";
      flake = false;
    };

    uptimeplaza-checker-ssl = {
      url = "github:Uptimeplaza/checker-ssl";
      flake = false;
    };

    uptimeplaza-checker-http = {
      url = "github:Uptimeplaza/checker-http";
      flake = false;
    };

    uptimeplaza-checker-website-screenshot = {
      url = "github:Uptimeplaza/checker-website-screenshot";
      flake = false;
    };
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , nix-darwin
    , mac-app-util
    , nixvim
    , rust-overlay
    , flake-utils
    , disko
    , sops-nix
    , nixpkgs-stable
    , home-manager-stable
    , screeny
    , mercy
    , grpc-proxier
    , pdf-detective
    , claude-code-nix
    , llm-agents-nix
    , ijohanne-nur
    , nixos-mailserver
    , shouldidrinktoday
    , unixpimpsnet
    , themailer-wrapper
    , perlpimpnet
    , proton-port-sync
    , vardrun
    , leita
    , callis
    , ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      communityModules = import ./modules/community;
      privateModules = import ./modules/private;
      moduleRegistry = {
        public = communityModules;
        private = privateModules;
      };
      flatHomeManagerModules =
        communityModules.homeManager.shared
        // communityModules.homeManager.programs
        // communityModules.homeManager.languages
        // communityModules.homeManager.aspects;
      flatNixosModules =
        communityModules.nixos.shared
        // communityModules.nixos.profiles.system
        // communityModules.nixos.services
        // communityModules.nixos.aspects;
      flatDarwinModules =
        communityModules.darwin.shared
        // communityModules.darwin.aspects;
      users = import ./modules/private/inventory/users.nix;
      hmUser = imports: withNixvim: {
        inherit imports withNixvim;
      };

      channels = {
        unstable = {
          pkgsLib = nixpkgs.lib;
          homeManagerModules = {
            nixos = home-manager.nixosModules.home-manager;
            darwin = home-manager.darwinModules.home-manager;
          };
        };
        stable = {
          pkgsLib = nixpkgs-stable.lib;
          homeManagerModules = {
            nixos = home-manager-stable.nixosModules.home-manager;
          };
        };
      };

      hosts = {
        ij-desktop = {
          kind = "nixos";
          channel = "unstable";
          system = "x86_64-linux";
          hmStateVersion = "23.05";
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            ./hosts/ij-desktop/disko.nix
            ./hosts/ij-desktop/configuration.nix
          ];
          hmUsers = {
            ${users.ij.username} = hmUser [ ./hosts/ij-desktop/home.nix ] true;
          };
        };

        pakhet = {
          kind = "nixos";
          channel = "stable";
          system = "x86_64-linux";
          modules = [
            sops-nix.nixosModules.sops
            nixos-mailserver.nixosModules.default
            ijohanne-nur.nixosModules.hrafnsyn
            ijohanne-nur.nixosModules.pg-exporter
            ijohanne-nur.nixosModules.zot
            screeny.nixosModules.default
            mercy.nixosModules.default
            grpc-proxier.nixosModules.default
            pdf-detective.nixosModules.default
            shouldidrinktoday.nixosModules.default
            unixpimpsnet.nixosModules.default
            themailer-wrapper.nixosModules.default
            perlpimpnet.nixosModules.default
            vardrun.nixosModules.default
            ./hosts/pakhet/configuration.nix
          ];
          hmUsers = {
            ${users.ij.username} = hmUser [ (import privateModules.home.users.ij { }) ] true;
            ${users.mj.username} = hmUser [ privateModules.home.users.mj ] false;
          };
        };

        goose = {
          kind = "nixos";
          channel = "stable";
          system = "x86_64-linux";
          modules = [
            sops-nix.nixosModules.sops
            ijohanne-nur.nixosModules.multicast-relay
            ijohanne-nur.nixosModules.prometheus-hue-exporter
            ijohanne-nur.nixosModules.prometheus-nftables-exporter
            ijohanne-nur.nixosModules.prometheus-tplink-p110-exporter
            ijohanne-nur.nixosModules.prometheus-ecowitt-exporter
            ijohanne-nur.nixosModules.prometheus-gardena-exporter
            ijohanne-nur.nixosModules.prometheus-gpsd-exporter
            ./hosts/goose/configuration.nix
          ];
          backupFileExtension = "bak";
          hmUsers = {
            ${users.ij.username} = hmUser [ (import privateModules.home.users.ij { }) ] true;
            ${users.mj.username} = hmUser [ privateModules.home.users.mj ] false;
          };
        };

        anubis = {
          kind = "nixos";
          channel = "stable";
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            proton-port-sync.nixosModules.default
            ./hosts/anubis/disko.nix
            ./hosts/anubis/configuration.nix
          ];
          backupFileExtension = "bak";
          hmUsers = {
            ${users.ij.username} = hmUser [ (import privateModules.home.users.ij { }) ] true;
            ${users.mj.username} = hmUser [ privateModules.home.users.mj ] false;
          };
        };

        khosu = {
          kind = "nixos";
          channel = "stable";
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            ./hosts/khosu/disko.nix
            ./hosts/khosu/configuration.nix
          ];
          hmUsers = {
            ${users.ij.username} = hmUser [ (import privateModules.home.users.ij { }) ] true;
            ${users.mj.username} = hmUser [ privateModules.home.users.mj ] false;
          };
        };

        bhyve-image = {
          kind = "nixos";
          channel = "stable";
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            ./hosts/bhyve-image/disko.nix
            ./hosts/bhyve-image/configuration.nix
          ];
          imageName = "bhyve";
          imageBuilder = "diskoImages";
        };

        bhyve-image-server = {
          kind = "nixos";
          channel = "stable";
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            ./hosts/bhyve-image/disko.nix
            ./hosts/bhyve-image/configuration-server.nix
          ];
          hmUsers = {
            ${users.ij.username} = hmUser [ (import privateModules.home.users.ij { }) ] true;
            ${users.mj.username} = hmUser [ privateModules.home.users.mj ] false;
          };
          imageName = "bhyve-server";
          imageBuilder = "diskoImages";
        };

        rtsp-dev-vm = {
          kind = "nixos";
          channel = "unstable";
          system = "aarch64-linux";
          modules = [
            ./hosts/rtsp-dev-vm/configuration.nix
          ];
          imageBuilder = "vm";
        };

        rpi4-stable = {
          kind = "nixos";
          channel = "stable";
          system = "aarch64-linux";
          modules = [
            ./hosts/rpi4-image/stable/configuration.nix
          ];
          imageBuilder = "sdImage";
        };

        rpi4-unstable = {
          kind = "nixos";
          channel = "unstable";
          system = "aarch64-linux";
          modules = [
            ./hosts/rpi4-image/unstable/configuration.nix
          ];
          imageBuilder = "sdImage";
        };

        bastet = {
          kind = "nixos";
          channel = "stable";
          system = "aarch64-linux";
          modules = [
            sops-nix.nixosModules.sops
            ./hosts/bastet/configuration.nix
          ];
          imageBuilder = "sdImage";
        };

        macbook = {
          kind = "darwin";
          channel = "unstable";
          system = "aarch64-darwin";
          hmStateVersion = "23.05";
          modules = [
            mac-app-util.darwinModules.default
            sops-nix.darwinModules.sops
            ./hosts/macbook/configuration.nix
          ];
          backupFileExtension = "backup";
          hmUsers = {
            ${users.ij.username} = hmUser [
              mac-app-util.homeManagerModules.default
              ./hosts/macbook/home.nix
            ]
              true;
          };
        };
      };

      nixosHosts = lib.filterAttrs (_: host: host.kind == "nixos") hosts;
      darwinHosts = lib.filterAttrs (_: host: host.kind == "darwin") hosts;

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
          modules = [
            { nixpkgs.hostPlatform = system; }
          ] ++ modules;
          specialArgs = { inherit inputs self users moduleRegistry; modules = moduleRegistry; user = users.${primaryUser}; };
        };

      mkDarwinHost = { system, modules, primaryUser ? "ij" }:
        nix-darwin.lib.darwinSystem {
          modules = [
            { nixpkgs.hostPlatform = system; }
          ] ++ modules;
          specialArgs = { inherit inputs self users moduleRegistry; modules = moduleRegistry; user = users.${primaryUser}; };
        };

      mkHomeManagerModule =
        { system
        , kind
        , channel
        , hmUsers
        , backupFileExtension ? null
        , extraSpecialArgs ? { }
        ,
        }:
        let
          homeManagerModule = channels.${channel}.homeManagerModules.${kind};
        in
        [
          homeManagerModule
          ({ ... }: {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs =
                {
                  inherit users inputs;
                  modules = moduleRegistry;
                  moduleRegistry = moduleRegistry;
                  pkgs-unstable = mkPkgsUnstable system;
                  hmStateVersion = extraSpecialArgs.hmStateVersion or "22.05";
                }
                // lib.removeAttrs extraSpecialArgs [ "hmStateVersion" ];
              users = lib.mapAttrs
                (username: hmUserConfig: {
                  imports = [
                    ./modules/community/home/shared/home-defaults.nix
                  ] ++ hmUserConfig.imports ++ lib.optional hmUserConfig.withNixvim inputs.nixvim.homeModules.nixvim ++ [
                    { _module.args.user = users.${username}; }
                  ];
                })
                hmUsers;
            }
            // lib.optionalAttrs (backupFileExtension != null) {
              inherit backupFileExtension;
            };
          })
        ];

      mkHostModules = host:
        host.modules
        ++ lib.optionals (host ? hmUsers) (mkHomeManagerModule {
          inherit (host) system kind channel hmUsers;
          backupFileExtension = host.backupFileExtension or null;
          extraSpecialArgs = (host.extraSpecialArgs or { }) // {
            hmStateVersion = host.hmStateVersion or "22.05";
          };
        });
    in
    {
      moduleTrees = communityModules;
      homeManagerModules = flatHomeManagerModules;
      nixosModules = flatNixosModules;
      darwinModules = flatDarwinModules;

      nixosConfigurations = lib.mapAttrs
        (
          _: host:
            mkNixosHost {
              pkgsLib = channels.${host.channel}.pkgsLib;
              system = host.system;
              modules = mkHostModules host;
              primaryUser = host.primaryUser or "ij";
            }
        )
        nixosHosts;

      images = lib.mapAttrs'
        (
          name: host:
            lib.nameValuePair (host.imageName or name) (
              lib.getAttrFromPath [ "config" "system" "build" host.imageBuilder ] self.nixosConfigurations.${name}
            )
        )
        (lib.filterAttrs (_: host: host ? imageBuilder) nixosHosts);

      darwinConfigurations = lib.mapAttrs
        (
          _: host:
            mkDarwinHost {
              system = host.system;
              modules = mkHostModules host;
              primaryUser = host.primaryUser or "ij";
            }
        )
        darwinHosts;

      checks = { };
    }
    // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-stable = nixpkgs-stable.legacyPackages.${system};
      formatter = pkgs.nixpkgs-fmt;
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
      raspberry-pi-provision-image = pkgs.writeShellScriptBin "raspberry-pi-provision-image" ''
        set -euo pipefail

        export PATH="${pkgs.lib.makeBinPath [
          pkgs.coreutils
          pkgs.findutils
          pkgs.jq
          pkgs.util-linux
          pkgs.zstd
          pkgs.sops
          pkgs.openssh
          pkgs.e2fsprogs
          pkgs.nix
        ]}"

        if [ $# -ne 2 ]; then
          echo "Usage: raspberry-pi-provision-image <host> <output-path-or-directory>" >&2
          exit 1
        fi

        repo_root="''${DOTFILES_NG_ROOT:-$PWD}"
        if [ ! -f "$repo_root/flake.nix" ]; then
          echo "Could not find flake.nix in $repo_root. Run from the repo root or set DOTFILES_NG_ROOT." >&2
          exit 1
        fi

        host="$1"
        target="$2"
        secret_file="$repo_root/secrets/$host.yaml"
        if [ ! -f "$secret_file" ]; then
          echo "Missing host secret file at $secret_file" >&2
          exit 1
        fi

        build_out="$(nix build --print-out-paths --no-link "$repo_root#images.$host")"
        readarray -t built_images < <(find "$build_out/sd-image" -maxdepth 1 -type f \( -name '*.img' -o -name '*.img.zst' \) | sort)

        if [ "''${#built_images[@]}" -ne 1 ]; then
          echo "Expected exactly one image for $host under $build_out/sd-image" >&2
          exit 1
        fi

        source_image="''${built_images[0]}"
        destination="$target"
        if [ -d "$destination" ]; then
          destination="$destination/$(basename "$source_image")"
        fi

        mkdir -p "$(dirname "$destination")"
        rm -f "$destination"
        cp "$source_image" "$destination"
        chmod u+w "$destination"

        if [[ "$destination" == *.zst ]]; then
          zstd -d --rm "$destination"
          destination="''${destination%.zst}"
          chmod u+w "$destination"
        fi

        tmpdir="$(mktemp -d)"
        trap 'rm -rf "$tmpdir"' EXIT

        private_key="$tmpdir/ssh_host_ed25519_key"
        public_key="$tmpdir/ssh_host_ed25519_key.pub"
        wifi_secrets="$tmpdir/wpa_supplicant-secrets.conf"
        root_fs="$tmpdir/rootfs.img"
        partition_json="$tmpdir/partitions.json"

        sops decrypt --extract '["ssh_host_ed25519_key"]' "$secret_file" > "$private_key"
        chmod 600 "$private_key"
        ssh-keygen -y -f "$private_key" > "$public_key"
        if sops decrypt --extract '["wifi_psk"]' "$secret_file" > "$tmpdir/wifi_psk" 2>/dev/null; then
          printf 'wifi_psk=%s\n' "$(cat "$tmpdir/wifi_psk")" > "$wifi_secrets"
          chmod 400 "$wifi_secrets"
        fi

        sfdisk --json "$destination" > "$partition_json"
        root_start="$(jq -er '.partitiontable.partitions[1].start' "$partition_json")"
        root_size="$(jq -er '.partitiontable.partitions[1].size' "$partition_json")"

        dd if="$destination" of="$root_fs" bs=512 skip="$root_start" count="$root_size" status=none

        debugfs_write() {
          debugfs -w -R "$1" "$root_fs" >/dev/null 2>&1
        }

        debugfs_write "mkdir /etc/wpa_supplicant" || true
        debugfs_write "rm /etc/ssh/ssh_host_ed25519_key" || true
        debugfs_write "rm /etc/ssh/ssh_host_ed25519_key.pub" || true
        debugfs_write "write $private_key /etc/ssh/ssh_host_ed25519_key"
        debugfs_write "write $public_key /etc/ssh/ssh_host_ed25519_key.pub"
        debugfs_write "set_inode_field /etc/ssh/ssh_host_ed25519_key mode 0100600"
        debugfs_write "set_inode_field /etc/ssh/ssh_host_ed25519_key uid 0"
        debugfs_write "set_inode_field /etc/ssh/ssh_host_ed25519_key gid 0"
        debugfs_write "set_inode_field /etc/ssh/ssh_host_ed25519_key.pub mode 0100644"
        debugfs_write "set_inode_field /etc/ssh/ssh_host_ed25519_key.pub uid 0"
        debugfs_write "set_inode_field /etc/ssh/ssh_host_ed25519_key.pub gid 0"
        if [ -f "$wifi_secrets" ]; then
          debugfs_write "rm /etc/wpa_supplicant/secrets.conf" || true
          debugfs_write "write $wifi_secrets /etc/wpa_supplicant/secrets.conf"
          debugfs_write "set_inode_field /etc/wpa_supplicant/secrets.conf mode 0100400"
          debugfs_write "set_inode_field /etc/wpa_supplicant/secrets.conf uid 0"
          debugfs_write "set_inode_field /etc/wpa_supplicant/secrets.conf gid 0"
        fi

        dd if="$root_fs" of="$destination" bs=512 seek="$root_start" count="$root_size" conv=notrunc status=none

        set -- $(ssh-keygen -lf "$public_key")
        fingerprint="$2"
        echo "Provisioned $host image written to $destination"
        echo "Injected SSH host key fingerprint: $fingerprint"
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

      pgUpgradeScripts = pkgs.lib.optionalAttrs (system == "x86_64-linux") (
        let
          pg14 = pkgs-stable.postgresql_14;
          pg18 = pkgs-stable.postgresql_18;
          oldDir = "/var/lib/postgresql/14";
          newDir = "/var/lib/postgresql/18";
        in
        {
          postgresql-upgrade-14-18-step1 = pkgs.writeShellScriptBin "postgresql-upgrade-14-18-step1" ''
            set -euo pipefail

            echo "=== Step 1: Backup and preflight check ==="

            [[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }

            echo "Checking current checksum status..."
            sudo -u postgres ${pg14}/bin/pg_controldata ${oldDir} | grep -i checksum

            echo ""
            echo "Checking for MD5 passwords..."
            sudo -u postgres ${pg14}/bin/psql -c "SELECT rolname, CASE WHEN rolpassword LIKE 'md5%' THEN 'MD5 (migrate to SCRAM!)' ELSE 'OK' END AS auth FROM pg_authid WHERE rolpassword IS NOT NULL;"

            echo ""
            echo "Checking for expression indexes..."
            sudo -u postgres ${pg14}/bin/psql -At -c "SELECT schemaname || '.' || indexname || ': ' || indexdef FROM pg_indexes WHERE indexdef ~ '\\(.*\\('" 2>/dev/null || true

            echo ""
            echo "Checking for FTS indexes..."
            sudo -u postgres ${pg14}/bin/psql -At -c "SELECT schemaname || '.' || indexname FROM pg_indexes WHERE indexdef LIKE '%tsvector%' OR indexdef LIKE '%gin%' OR indexdef LIKE '%gist%'" 2>/dev/null || true

            echo ""
            echo "Taking pg_dumpall backup..."
            mkdir -p /var/backup
            sudo -u postgres ${pg14}/bin/pg_dumpall > "/var/backup/postgresql-14-pre-upgrade-$(date +%Y%m%d).sql"
            echo "Backup saved to /var/backup/"

            echo ""
            echo "Listing databases for reference..."
            sudo -u postgres ${pg14}/bin/psql -l

            echo ""
            echo "Stopping PostgreSQL..."
            systemctl stop postgresql.service

            echo "Creating socket directory..."
            mkdir -p /var/run/postgresql
            chown postgres:postgres /var/run/postgresql

            checksum_status=$(sudo -u postgres ${pg14}/bin/pg_controldata ${oldDir} | grep "Data page checksum" | awk '{print $NF}')
            initdb_flags=""
            if [ "$checksum_status" = "0" ] || echo "$checksum_status" | grep -qi "off\|disabled"; then
              echo "Old cluster has checksums DISABLED — passing --no-data-checksums to initdb"
              initdb_flags="--no-data-checksums"
            fi

            echo "Initializing new data directory..."
            sudo -u postgres ${pg18}/bin/initdb $initdb_flags -D ${newDir}

            echo "Running pg_upgrade --check (dry run)..."
            cd /var/lib/postgresql
            sudo -u postgres ${pg18}/bin/pg_upgrade \
              --socketdir=/var/run/postgresql \
              --old-bindir=${pg14}/bin \
              --new-bindir=${pg18}/bin \
              --old-datadir=${oldDir} \
              --new-datadir=${newDir} \
              --check

            echo ""
            echo "=== Preflight passed. Proceed to step 2. ==="
            echo "NOTE: PostgreSQL is stopped. If aborting, run: rm -rf ${newDir} && systemctl start postgresql.service"
          '';

          postgresql-upgrade-14-18-step2 = pkgs.writeShellScriptBin "postgresql-upgrade-14-18-step2" ''
            set -euo pipefail

            echo "=== Step 2: Run pg_upgrade ==="

            [[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }

            echo "Ensuring PostgreSQL is stopped..."
            systemctl stop postgresql.service 2>/dev/null || true

            mkdir -p /var/run/postgresql
            chown postgres:postgres /var/run/postgresql

            echo "Running pg_upgrade..."
            cd /var/lib/postgresql
            sudo -u postgres ${pg18}/bin/pg_upgrade \
              --socketdir=/var/run/postgresql \
              --old-bindir=${pg14}/bin \
              --new-bindir=${pg18}/bin \
              --old-datadir=${oldDir} \
              --new-datadir=${newDir}

            echo ""
            echo "=== pg_upgrade completed. ==="
            echo ""
            echo "Next steps:"
            echo "  1. Update modules/private/nixos/services/pakhet/postgresql.nix to set package = pkgs.postgresql_18"
            echo "  2. Commit, push, deploy-pakhet"
            echo "  3. Run step 3 for post-upgrade verification"
          '';

          postgresql-upgrade-14-18-step3 = pkgs.writeShellScriptBin "postgresql-upgrade-14-18-step3" ''
            set -euo pipefail

            echo "=== Step 3: Post-upgrade verification ==="

            [[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }

            echo "Checking PostgreSQL service status..."
            systemctl status postgresql.service --no-pager

            echo ""
            echo "Checking PostgreSQL version..."
            sudo -u postgres ${pg18}/bin/psql -c "SELECT version();"

            echo ""
            echo "Listing databases..."
            sudo -u postgres ${pg18}/bin/psql -l

            if [ -f /var/lib/postgresql/update_extensions.sql ]; then
              echo ""
              echo "Applying extension updates..."
              sudo -u postgres ${pg18}/bin/psql -f /var/lib/postgresql/update_extensions.sql
            fi

            echo ""
            echo "Reindexing all databases (required for FTS collation changes in PG18)..."
            for db in $(sudo -u postgres ${pg18}/bin/psql -At -c "SELECT datname FROM pg_database WHERE datistemplate = false;"); do
              echo "  Reindexing $db..."
              sudo -u postgres ${pg18}/bin/reindexdb "$db" || echo "  WARNING: reindex of $db failed"
            done

            echo ""
            echo "Checking for MD5 passwords (deprecated in PG18)..."
            sudo -u postgres ${pg18}/bin/psql -c "SELECT rolname, CASE WHEN rolpassword LIKE 'md5%' THEN 'MD5 — MIGRATE TO SCRAM!' ELSE 'SCRAM (ok)' END AS auth FROM pg_authid WHERE rolpassword IS NOT NULL;"

            echo ""
            echo "Running ANALYZE on all databases..."
            sudo -u postgres ${pg18}/bin/vacuumdb --all --analyze-only

            echo ""
            echo "Checking all dependent services are healthy..."
            for svc in screeny-k111-agw screeny-k111-test screeny-k131-god screeny-geoip vardrun-unixpimps vardrun-opsplaza plausible; do
              status=$(systemctl is-active "$svc" 2>/dev/null || echo "not found")
              printf "  %-25s %s\n" "$svc" "$status"
            done

            echo ""
            echo "=== Verification complete ==="
            echo ""
            echo "If everything looks good:"
            echo "  1. Remove old data directory: rm -rf ${oldDir}"
            echo "  2. Delete pg_upgrade logs/scripts in /var/lib/postgresql/ (delete_old_cluster.sh, etc.)"
            echo "  3. If MD5 passwords were found, migrate them to SCRAM-SHA-256"
          '';
        }
      );

      checks =
        {
          setup-template = setup-template.overrideAttrs (_: {
            doCheck = true;
          });
        };
    in
    {
      inherit formatter;

      packages = {
        setup-template = setup-template;
        raspberry-pi-provision-image = raspberry-pi-provision-image;
      } // pgUpgradeScripts;

      apps = {
        setup-template = {
          type = "app";
          program = "${setup-template}/bin/setup-template";
          meta = {
            description = "Scaffold new host and user configs for the dotfiles flake";
          };
        };
        raspberry-pi-provision-image = {
          type = "app";
          program = "${raspberry-pi-provision-image}/bin/raspberry-pi-provision-image";
          meta = {
            description = "Build, copy, and provision a Raspberry Pi image with its SSH host key";
          };
        };
      } // builtins.mapAttrs
        (name: pkg: {
          type = "app";
          program = "${pkg}/bin/${name}";
        })
        pgUpgradeScripts;

      inherit checks;

      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          formatter
          sops
          age
          nix-output-monitor
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
          echo "  raspberry-pi-provision-image <host> <path>  build and provision a Raspberry Pi image"
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
