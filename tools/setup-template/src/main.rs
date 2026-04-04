mod render;
mod schema;
mod wizard;

use std::path::PathBuf;

use anyhow::Result;
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(
    name = "setup-template",
    about = "Scaffold new host/user configs for the dotfiles flake"
)]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    /// Interactive wizard to create a new host + user config
    New {
        /// Output directory (defaults to current directory)
        #[arg(long, default_value = ".")]
        output: PathBuf,

        /// Accept defaults without prompting
        #[arg(long)]
        yes: bool,

        /// Show what would be generated without writing files
        #[arg(long)]
        dry_run: bool,

        /// Flake reference for the repo
        #[arg(long, default_value = "github:ijohanne/dotfiles-ng")]
        repo_ref: String,
    },

    /// Generate from a config file
    Generate {
        /// Path to config file (JSON or TOML)
        #[arg(long)]
        config: PathBuf,

        /// Output directory (defaults to current directory)
        #[arg(long, default_value = ".")]
        output: PathBuf,

        /// Overwrite existing files
        #[arg(long)]
        force: bool,

        /// Show what would be generated without writing files
        #[arg(long)]
        dry_run: bool,
    },
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Command::New {
            output,
            yes,
            dry_run,
            repo_ref,
        } => {
            let config = if yes {
                default_config(&repo_ref)
            } else {
                wizard::run_wizard(&repo_ref)?
            };
            config.validate()?;

            let rendered = render::render(&config)?;
            render::write_files(&rendered, &output, false, dry_run)?;

            if !dry_run {
                print_next_steps(&config);
            }
        }
        Command::Generate {
            config: config_path,
            output,
            force,
            dry_run,
        } => {
            let config = schema::Config::load(&config_path)?;
            config.validate()?;

            let rendered = render::render(&config)?;
            render::write_files(&rendered, &output, force, dry_run)?;

            if !dry_run {
                print_next_steps(&config);
            }
        }
    }

    Ok(())
}

fn default_config(repo_ref: &str) -> schema::Config {
    schema::Config {
        version: 1,
        repo_ref: repo_ref.to_string(),
        users: vec![schema::UserConfig {
            username: "user".into(),
            name: "New User".into(),
            email: "user@example.com".into(),
            shell: "fish".into(),
            developer: true,
            ssh_keys: vec![],
        }],
        hosts: vec![schema::HostConfig {
            name: "myhost".into(),
            platform: schema::Platform::Linux,
            arch: schema::Arch::X86_64,
            role: schema::Role::Desktop,
            nixpkgs: schema::NixpkgsChannel::Unstable,
            deploy_mode: schema::DeployMode::Local,
            primary_user: "user".into(),
            additional_users: vec![],
            modules: schema::ModuleSelections {
                secrets: true,
                neovim: true,
                languages: vec!["nix".into()],
            },
        }],
    }
}

fn print_next_steps(config: &schema::Config) {
    println!("\n  Next steps:\n");
    println!("  1. Review the generated files");
    println!("  2. Add the flake snippet above to flake.nix");
    println!("  3. Update configs/users.nix (merge with existing if needed)");

    for host in &config.hosts {
        if host.modules.secrets {
            println!(
                "  4. Create secrets/{}.yaml and update .sops.yaml with the host's age key",
                host.name
            );
            println!("     - Get the age key: ssh-to-age-remote <host-ssh-pubkey>");
            println!("     - Add to .sops.yaml creation_rules");
            println!("     - Run: sops secrets/{}.yaml", host.name);
        }
    }

    println!("  5. Add the host to configs/network.nix (if on the local network)");
    println!("  6. Build and test:");
    for host in &config.hosts {
        match host.platform {
            schema::Platform::Darwin => {
                println!("     nix build .#darwinConfigurations.{}.system", host.name);
                println!("     darwin-rebuild switch --flake .#{}", host.name);
            }
            schema::Platform::Linux => {
                println!(
                    "     nix build .#nixosConfigurations.{}.config.system.build.toplevel",
                    host.name
                );
                match host.deploy_mode {
                    schema::DeployMode::Local => {
                        println!("     sudo nixos-rebuild switch --flake .#{}", host.name);
                    }
                    schema::DeployMode::Remote => {
                        println!("     git push && ssh <host> deploy-{}", host.name);
                    }
                }
            }
        }
    }
    println!();
}
