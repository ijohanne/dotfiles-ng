//! Renderer contract:
//!
//! Given a validated Config, produce a file tree matching current flake conventions:
//!
//! - `modules/private/inventory/users.nix` — user registry (attrset of { username, email, name, developer, shell, sshKeys })
//! - `hosts/<name>/configuration.nix` — host config using `deploy = modules.public.lib.deploy { inherit pkgs; };`
//!   - desktop/local: `deploy.mkLocalDeployScript { name, host, rebuildCmd }`
//!   - server/remote: `deploy.mkDeployScript { name, host }`
//!   - darwin/local: `deploy.mkLocalDeployScript { name, host, rebuildCmd, useSudo = false }`
//! - `hosts/<name>/home.nix` — home-manager config importing from modules/community/home/{shared,programs,languages}/
//! - Flake snippet (not patched) — ready-to-paste nixosConfigurations/darwinConfigurations block
//!
//! Deterministic: same Config always produces same output (sorted keys, stable ordering).

use std::collections::BTreeMap;
use std::path::{Path, PathBuf};

use anyhow::Result;

use crate::schema::*;

pub struct RenderedOutput {
    pub files: BTreeMap<PathBuf, String>,
    pub flake_snippet: String,
}

pub fn render(config: &Config) -> Result<RenderedOutput> {
    let mut files = BTreeMap::new();

    files.insert(
        PathBuf::from("modules/private/inventory/users.nix"),
        render_users_nix(&config.users),
    );

    for host in &config.hosts {
        let host_dir = PathBuf::from(format!("hosts/{}", host.name));
        files.insert(
            host_dir.join("configuration.nix"),
            render_configuration_nix(host, config),
        );
        files.insert(host_dir.join("home.nix"), render_home_nix(host));
    }

    let flake_snippet = render_flake_snippet(config);

    Ok(RenderedOutput {
        files,
        flake_snippet,
    })
}

fn render_users_nix(users: &[UserConfig]) -> String {
    let mut out = String::from("{\n");
    for user in users {
        out.push_str(&format!("  {} = {{\n", user.username));
        out.push_str(&format!("    username = \"{}\";\n", user.username));
        out.push_str(&format!("    email = \"{}\";\n", user.email));
        out.push_str(&format!("    name = \"{}\";\n", user.name));
        out.push_str(&format!("    developer = {};\n", user.developer));
        out.push_str(&format!("    shell = \"{}\";\n", user.shell));
        out.push_str("    sshKeys = [\n");
        for key in &user.ssh_keys {
            out.push_str(&format!("      \"{}\"\n", key));
        }
        out.push_str("    ];\n");
        out.push_str("  };\n");
    }
    out.push_str("}\n");
    out
}

fn shell_pkg(shell: &str) -> &str {
    match shell {
        "fish" => "pkgs.fish",
        "zsh" => "pkgs.zsh",
        _ => "pkgs.bash",
    }
}

fn render_configuration_nix(host: &HostConfig, config: &Config) -> String {
    let primary_user = config
        .users
        .iter()
        .find(|u| u.username == host.primary_user)
        .unwrap();

    let mut out = String::new();

    if host.platform == Platform::Darwin {
        out.push_str("{ inputs, config, pkgs, user, modules, ... }:\n\n");
    } else {
        out.push_str("{ inputs, config, pkgs, lib, user, modules, ... }:\n\n");
    }

    out.push_str("let\n");
    out.push_str("  deploy = modules.public.lib.deploy { inherit pkgs; };\n");
    out.push_str("in\n{\n");
    out.push_str("  imports = [\n");
    if host.modules.secrets {
        if host.platform == Platform::Darwin {
            out.push_str("    inputs.sops-nix.darwinModules.sops\n");
        }
    }
    out.push_str("  ];\n\n");

    if host.platform == Platform::Linux {
        out.push_str("  boot.loader.systemd-boot.enable = true;\n");
        out.push_str("  boot.loader.efi.canTouchEfiVariables = true;\n\n");
    }

    if host.platform == Platform::Linux {
        out.push_str(&format!("  networking.hostName = \"{}\";\n\n", host.name));
    } else {
        out.push_str(&format!("  networking.hostName = \"{}\";\n\n", host.name));
    }

    out.push_str("  nix.settings = {\n");
    out.push_str("    experimental-features = [ \"nix-command\" \"flakes\" ];\n");
    out.push_str("  };\n\n");

    out.push_str("  time.timeZone = \"UTC\";\n\n");

    if host.platform == Platform::Linux {
        // user definition
        out.push_str(&format!("  users.users.${{user.username}} = {{\n"));
        out.push_str("    isNormalUser = true;\n");
        out.push_str("    description = user.name;\n");
        let groups = if host.role == Role::Desktop {
            "[ \"networkmanager\" \"wheel\" ]"
        } else {
            "[ \"wheel\" ]"
        };
        out.push_str(&format!("    extraGroups = {};\n", groups));
        out.push_str(&format!(
            "    shell = {};\n",
            shell_pkg(&primary_user.shell)
        ));
        out.push_str("    openssh.authorizedKeys.keys = user.sshKeys;\n");
        out.push_str("  };\n\n");

        if primary_user.shell == "fish" {
            out.push_str("  programs.fish.enable = true;\n\n");
        }

        if host.role == Role::Desktop {
            out.push_str("  services.xserver.enable = true;\n");
            out.push_str("  services.displayManager.gdm.enable = true;\n");
            out.push_str("  services.desktopManager.gnome.enable = true;\n\n");
        }

        out.push_str("  nixpkgs.config.allowUnfree = true;\n\n");
    }

    // deploy script
    out.push_str("  environment.systemPackages = [\n");
    match (host.platform, host.deploy_mode) {
        (Platform::Darwin, DeployMode::Local) => {
            out.push_str(&format!(
                "    (deploy.mkLocalDeployScript {{\n\
                 \x20     name = \"deploy-{}\";\n\
                 \x20     host = \"{}\";\n\
                 \x20     rebuildCmd = \"darwin-rebuild switch --flake\";\n\
                 \x20     useSudo = false;\n\
                 \x20   }})\n",
                host.name, host.name
            ));
        }
        (Platform::Linux, DeployMode::Local) => {
            out.push_str(&format!(
                "    (deploy.mkLocalDeployScript {{\n\
                 \x20     name = \"deploy-{}\";\n\
                 \x20     host = \"{}\";\n\
                 \x20     rebuildCmd = \"nixos-rebuild switch --flake\";\n\
                 \x20   }})\n",
                host.name, host.name
            ));
        }
        (_, DeployMode::Remote) => {
            out.push_str(&format!(
                "    (deploy.mkDeployScript {{\n\
                 \x20     name = \"deploy-{}\";\n\
                 \x20     host = \"{}\";\n\
                 \x20   }})\n",
                host.name, host.name
            ));
        }
    }
    out.push_str("  ];\n\n");

    if host.modules.secrets && host.platform == Platform::Linux {
        out.push_str(&format!(
            "  sops = {{\n\
             \x20   defaultSopsFile = ../../secrets/{}.yaml;\n\
             \x20   age = {{\n\
             \x20     sshKeyPaths = [\n\
             \x20       \"/etc/ssh/ssh_host_ed25519_key\"\n\
             \x20     ];\n\
             \x20     keyFile = \"/var/lib/sops-nix/key.txt\";\n\
             \x20     generateKey = true;\n\
             \x20   }};\n\
             \x20 }};\n\n",
            host.name
        ));
    }

    out.push_str("  system.stateVersion = \"25.11\";\n");
    out.push_str("}\n");
    out
}

fn render_home_nix(host: &HostConfig) -> String {
    let is_desktop = host.role == Role::Desktop;
    let mut out = String::new();

    out.push_str("{ pkgs, pkgs-unstable, user, ... }:\n\n");
    out.push_str("{\n");
    out.push_str("  imports = [\n");

    // shared user config
    out.push_str(&format!(
        "    (import ../../modules/community/home/shared/common.nix {{ desktop = {}; }})\n",
        if is_desktop { "true" } else { "false" }
    ));

    // programs
    if is_desktop {
        out.push_str("    ../../modules/community/home/programs/fish\n");
        out.push_str("    ../../modules/community/home/programs/tmux\n");
        out.push_str("    ../../modules/community/home/programs/git\n");
        out.push_str("    ../../modules/community/home/programs/bash\n");
        out.push_str("    ../../modules/community/home/programs/direnv\n");
        out.push_str("    ../../modules/community/home/programs/lazygit\n");
        out.push_str("    ../../modules/community/home/programs/starship\n");
        out.push_str("    ../../modules/community/home/programs/htop\n");
        out.push_str("    ../../modules/community/home/programs/zoxide\n");
        out.push_str("    ../../modules/community/home/programs/delta\n");
    }

    // neovim
    if host.modules.neovim {
        out.push_str("    ../../modules/community/home/programs/neovim\n");
    }

    // languages
    if !host.modules.languages.is_empty() {
        if host.modules.languages.len() == 5 {
            out.push_str("    ../../modules/community/home/languages\n");
        } else {
            for lang in &host.modules.languages {
                out.push_str(&format!(
                    "    ../../modules/community/home/languages/{}\n",
                    lang
                ));
            }
        }
    }

    out.push_str("  ];\n\n");
    out.push_str("  home.stateVersion = \"25.11\";\n");
    out.push_str("}\n");
    out
}

fn system_str(host: &HostConfig) -> String {
    let os = match host.platform {
        Platform::Linux => "linux",
        Platform::Darwin => "darwin",
    };
    format!("{}-{}", host.arch, os)
}

fn render_flake_snippet(config: &Config) -> String {
    let mut out = String::new();
    out.push_str("# ── Paste the following into flake.nix outputs ──\n\n");

    for host in &config.hosts {
        let system = system_str(host);
        let all_users: Vec<&str> = std::iter::once(host.primary_user.as_str())
            .chain(host.additional_users.iter().map(|s| s.as_str()))
            .collect();

        let (pkgs_lib, config_type) = match host.platform {
            Platform::Linux => {
                let pl = match host.nixpkgs {
                    NixpkgsChannel::Unstable => "nixpkgs",
                    NixpkgsChannel::Stable => "nixpkgs-stable",
                };
                (pl, "nixosConfigurations")
            }
            Platform::Darwin => ("nix-darwin", "darwinConfigurations"),
        };

        out.push_str(&format!("    {}.{} = ", config_type, host.name));

        if host.platform == Platform::Darwin {
            out.push_str(&format!(
                "mkDarwinHost {{\n\
                 \x20     system = \"{}\";\n\
                 \x20     primaryUser = \"{}\";\n\
                 \x20     modules = [\n\
                 \x20       ./hosts/{}/configuration.nix\n\
                 \x20     ]\n\
                 \x20     ++ mkHomeManagerModule {{\n\
                 \x20       homeManagerModule = home-manager.darwinModules.home-manager;\n",
                system, host.primary_user, host.name
            ));
        } else {
            out.push_str(&format!(
                "mkNixosHost {{\n\
                 \x20     pkgsLib = {};\n\
                 \x20     system = \"{}\";\n\
                 \x20     primaryUser = \"{}\";\n\
                 \x20     modules = [\n\
                 \x20       ./hosts/{}/configuration.nix\n\
                 \x20     ]\n\
                 \x20     ++ mkHomeManagerModule {{\n\
                 \x20       homeManagerModule = home-manager.nixosModules.home-manager;\n",
                pkgs_lib, system, host.primary_user, host.name
            ));
        }

        // hmUsers
        out.push_str("          hmUsers = {\n");
        for u in &all_users {
            out.push_str(&format!(
                "            {} = [ ./hosts/{}/home.nix ];\n",
                u, host.name
            ));
        }
        out.push_str("          };\n");

        // extraSpecialArgs
        out.push_str(&format!(
            "          extraSpecialArgs = {{ pkgs-unstable = mkPkgsUnstable \"{}\"; }};\n",
            system
        ));

        out.push_str("        };\n");
        out.push_str("    };\n\n");
    }

    out.push_str("# ── End snippet ──\n");
    out
}

pub fn write_files(
    output: &RenderedOutput,
    output_dir: &Path,
    force: bool,
    dry_run: bool,
) -> Result<()> {
    if dry_run {
        println!("\n  Dry run — files that would be generated:\n");
        for (path, content) in &output.files {
            let full = output_dir.join(path);
            let exists = full.exists();
            let marker = if exists { " (overwrite)" } else { "" };
            println!("  {}{}", full.display(), marker);
            for line in content.lines() {
                println!("    {}", line);
            }
            println!();
        }
        println!("  Flake snippet:\n");
        for line in output.flake_snippet.lines() {
            println!("  {}", line);
        }
        return Ok(());
    }

    for (path, content) in &output.files {
        let full = output_dir.join(path);
        if full.exists() && !force {
            anyhow::bail!(
                "file already exists: {} (use --force to overwrite)",
                full.display()
            );
        }
        if let Some(parent) = full.parent() {
            std::fs::create_dir_all(parent)?;
        }
        std::fs::write(&full, content)?;
        println!("  wrote {}", full.display());
    }

    println!("\n  Flake snippet (paste into flake.nix):\n");
    println!("{}", output.flake_snippet);

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_config() -> Config {
        Config {
            version: 1,
            repo_ref: "github:ijohanne/dotfiles-ng".into(),
            users: vec![UserConfig {
                username: "alice".into(),
                name: "Alice Smith".into(),
                email: "alice@example.com".into(),
                shell: "fish".into(),
                developer: true,
                ssh_keys: vec!["ssh-ed25519 AAAA...".into()],
            }],
            hosts: vec![HostConfig {
                name: "workstation".into(),
                platform: Platform::Linux,
                arch: Arch::X86_64,
                role: Role::Desktop,
                nixpkgs: NixpkgsChannel::Unstable,
                deploy_mode: DeployMode::Local,
                primary_user: "alice".into(),
                additional_users: vec![],
                modules: ModuleSelections {
                    secrets: true,
                    neovim: true,
                    languages: vec!["nix".into(), "rust".into()],
                },
            }],
        }
    }

    #[test]
    fn render_produces_expected_files() {
        let output = render(&test_config()).unwrap();
        assert!(output
            .files
            .contains_key(&PathBuf::from("modules/private/inventory/users.nix")));
        assert!(output
            .files
            .contains_key(&PathBuf::from("hosts/workstation/configuration.nix")));
        assert!(output
            .files
            .contains_key(&PathBuf::from("hosts/workstation/home.nix")));
    }

    #[test]
    fn users_nix_contains_user() {
        let output = render(&test_config()).unwrap();
        let users = &output.files[&PathBuf::from("modules/private/inventory/users.nix")];
        assert!(users.contains("alice"));
        assert!(users.contains("alice@example.com"));
        assert!(users.contains("developer = true"));
        assert!(users.contains("ssh-ed25519 AAAA..."));
    }

    #[test]
    fn configuration_uses_local_deploy() {
        let output = render(&test_config()).unwrap();
        let conf = &output.files[&PathBuf::from("hosts/workstation/configuration.nix")];
        assert!(conf.contains("mkLocalDeployScript"));
        assert!(conf.contains("deploy-workstation"));
        assert!(conf.contains("nixos-rebuild switch --flake"));
    }

    #[test]
    fn server_uses_remote_deploy() {
        let mut config = test_config();
        config.hosts[0].role = Role::Server;
        config.hosts[0].deploy_mode = DeployMode::Remote;
        let output = render(&config).unwrap();
        let conf = &output.files[&PathBuf::from("hosts/workstation/configuration.nix")];
        assert!(conf.contains("mkDeployScript"));
    }

    #[test]
    fn darwin_uses_darwin_rebuild() {
        let mut config = test_config();
        config.hosts[0].platform = Platform::Darwin;
        config.hosts[0].arch = Arch::Aarch64;
        let output = render(&config).unwrap();
        let conf = &output.files[&PathBuf::from("hosts/workstation/configuration.nix")];
        assert!(conf.contains("darwin-rebuild switch --flake"));
        assert!(conf.contains("useSudo = false"));
    }

    #[test]
    fn home_nix_imports_languages() {
        let output = render(&test_config()).unwrap();
        let home = &output.files[&PathBuf::from("hosts/workstation/home.nix")];
        assert!(home.contains("modules/community/home/languages/nix"));
        assert!(home.contains("modules/community/home/languages/rust"));
    }

    #[test]
    fn flake_snippet_contains_host() {
        let output = render(&test_config()).unwrap();
        assert!(output
            .flake_snippet
            .contains("nixosConfigurations.workstation"));
        assert!(output.flake_snippet.contains("mkNixosHost"));
        assert!(output.flake_snippet.contains("mkPkgsUnstable"));
    }

    #[test]
    fn render_is_deterministic() {
        let config = test_config();
        let a = render(&config).unwrap();
        let b = render(&config).unwrap();
        assert_eq!(a.files, b.files);
        assert_eq!(a.flake_snippet, b.flake_snippet);
    }

    #[test]
    fn darwin_flake_snippet() {
        let mut config = test_config();
        config.hosts[0].platform = Platform::Darwin;
        config.hosts[0].arch = Arch::Aarch64;
        let output = render(&config).unwrap();
        assert!(output
            .flake_snippet
            .contains("darwinConfigurations.workstation"));
        assert!(output.flake_snippet.contains("mkDarwinHost"));
        assert!(output
            .flake_snippet
            .contains("home-manager.darwinModules.home-manager"));
    }
}
