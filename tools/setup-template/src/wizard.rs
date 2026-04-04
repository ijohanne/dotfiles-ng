use anyhow::Result;
use dialoguer::{Confirm, Input, MultiSelect, Select};

use crate::schema::*;

pub fn run_wizard(repo_ref: &str) -> Result<Config> {
    println!("\n  Setup Template Generator");
    println!("  Scaffold a new host + user for the dotfiles flake.\n");

    let user = prompt_user()?;
    let host = prompt_host(&user.username)?;

    Ok(Config {
        version: 1,
        repo_ref: repo_ref.to_string(),
        users: vec![user],
        hosts: vec![host],
    })
}

fn prompt_user() -> Result<UserConfig> {
    println!("--- User ---");

    let username: String = Input::new().with_prompt("Username").interact_text()?;

    let name: String = Input::new().with_prompt("Full name").interact_text()?;

    let email: String = Input::new().with_prompt("Email").interact_text()?;

    let shell_options = &["fish", "zsh", "bash"];
    let shell_idx = Select::new()
        .with_prompt("Shell")
        .items(shell_options)
        .default(0)
        .interact()?;

    let developer = Confirm::new()
        .with_prompt("Developer (enables LSP, dev tools)?")
        .default(true)
        .interact()?;

    let mut ssh_keys = Vec::new();
    loop {
        let key: String = Input::new()
            .with_prompt("SSH public key (empty to finish)")
            .allow_empty(true)
            .interact_text()?;
        if key.is_empty() {
            break;
        }
        ssh_keys.push(key);
    }

    Ok(UserConfig {
        username,
        name,
        email,
        shell: shell_options[shell_idx].to_string(),
        developer,
        ssh_keys,
    })
}

fn prompt_host(default_user: &str) -> Result<HostConfig> {
    println!("\n--- Host ---");

    let name: String = Input::new().with_prompt("Host name").interact_text()?;

    let platform_options = &["linux", "darwin"];
    let platform_idx = Select::new()
        .with_prompt("Platform")
        .items(platform_options)
        .default(0)
        .interact()?;
    let platform = match platform_idx {
        0 => Platform::Linux,
        _ => Platform::Darwin,
    };

    let arch_options = if platform == Platform::Darwin {
        vec!["aarch64", "x86_64"]
    } else {
        vec!["x86_64", "aarch64"]
    };
    let arch_idx = Select::new()
        .with_prompt("Architecture")
        .items(&arch_options)
        .default(0)
        .interact()?;
    let arch = match arch_options[arch_idx] {
        "x86_64" => Arch::X86_64,
        _ => Arch::Aarch64,
    };

    let role = if platform == Platform::Darwin {
        Role::Desktop
    } else {
        let role_options = &["desktop", "server"];
        let role_idx = Select::new()
            .with_prompt("Role")
            .items(role_options)
            .default(0)
            .interact()?;
        match role_idx {
            0 => Role::Desktop,
            _ => Role::Server,
        }
    };

    let nixpkgs_options = &["unstable", "stable"];
    let nixpkgs_idx = Select::new()
        .with_prompt("Nixpkgs channel")
        .items(nixpkgs_options)
        .default(0)
        .interact()?;
    let nixpkgs = match nixpkgs_idx {
        0 => NixpkgsChannel::Unstable,
        _ => NixpkgsChannel::Stable,
    };

    let deploy_mode = if role == Role::Server {
        let dm_options = &["remote", "local"];
        let dm_idx = Select::new()
            .with_prompt("Deploy mode")
            .items(dm_options)
            .default(0)
            .interact()?;
        match dm_idx {
            0 => DeployMode::Remote,
            _ => DeployMode::Local,
        }
    } else {
        DeployMode::Local
    };

    let secrets = Confirm::new()
        .with_prompt("Enable sops-nix secrets?")
        .default(role == Role::Server)
        .interact()?;

    let neovim = Confirm::new()
        .with_prompt("Enable neovim (nixvim)?")
        .default(true)
        .interact()?;

    let lang_options = &["nix", "rust", "lua", "markdown", "flutter"];
    let lang_defaults = &[true, false, false, false, false];
    let lang_indices = MultiSelect::new()
        .with_prompt("Language modules (space to toggle)")
        .items(lang_options)
        .defaults(lang_defaults)
        .interact()?;
    let languages: Vec<String> = lang_indices
        .iter()
        .map(|&i| lang_options[i].to_string())
        .collect();

    Ok(HostConfig {
        name,
        platform,
        arch,
        role,
        nixpkgs,
        deploy_mode,
        primary_user: default_user.to_string(),
        additional_users: vec![],
        modules: ModuleSelections {
            secrets,
            neovim,
            languages,
        },
    })
}
