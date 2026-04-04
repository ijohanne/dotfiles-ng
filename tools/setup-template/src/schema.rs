use serde::{Deserialize, Serialize};
use std::path::Path;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    #[serde(default = "default_version")]
    pub version: u32,
    #[serde(default = "default_repo_ref")]
    pub repo_ref: String,
    pub users: Vec<UserConfig>,
    pub hosts: Vec<HostConfig>,
}

fn default_version() -> u32 {
    1
}

fn default_repo_ref() -> String {
    "github:ijohanne/dotfiles-ng".to_string()
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserConfig {
    pub username: String,
    pub name: String,
    pub email: String,
    #[serde(default = "default_shell")]
    pub shell: String,
    #[serde(default)]
    pub developer: bool,
    #[serde(default)]
    pub ssh_keys: Vec<String>,
}

fn default_shell() -> String {
    "fish".to_string()
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Platform {
    Linux,
    Darwin,
}

impl std::fmt::Display for Platform {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Platform::Linux => write!(f, "linux"),
            Platform::Darwin => write!(f, "darwin"),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Role {
    Desktop,
    Server,
}

impl std::fmt::Display for Role {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Role::Desktop => write!(f, "desktop"),
            Role::Server => write!(f, "server"),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Arch {
    #[serde(rename = "x86_64")]
    X86_64,
    #[serde(rename = "aarch64")]
    Aarch64,
}

impl std::fmt::Display for Arch {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Arch::X86_64 => write!(f, "x86_64"),
            Arch::Aarch64 => write!(f, "aarch64"),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum NixpkgsChannel {
    Stable,
    Unstable,
}

impl std::fmt::Display for NixpkgsChannel {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            NixpkgsChannel::Stable => write!(f, "stable"),
            NixpkgsChannel::Unstable => write!(f, "unstable"),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum DeployMode {
    Local,
    Remote,
}

impl std::fmt::Display for DeployMode {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            DeployMode::Local => write!(f, "local"),
            DeployMode::Remote => write!(f, "remote"),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HostConfig {
    pub name: String,
    pub platform: Platform,
    pub arch: Arch,
    pub role: Role,
    #[serde(default = "default_nixpkgs")]
    pub nixpkgs: NixpkgsChannel,
    pub deploy_mode: DeployMode,
    pub primary_user: String,
    #[serde(default)]
    pub additional_users: Vec<String>,
    #[serde(default)]
    pub modules: ModuleSelections,
}

fn default_nixpkgs() -> NixpkgsChannel {
    NixpkgsChannel::Unstable
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ModuleSelections {
    #[serde(default)]
    pub secrets: bool,
    #[serde(default)]
    pub neovim: bool,
    #[serde(default)]
    pub languages: Vec<String>,
}

impl Config {
    pub fn load(path: &Path) -> anyhow::Result<Self> {
        let content = std::fs::read_to_string(path)?;
        let ext = path.extension().and_then(|e| e.to_str()).unwrap_or("");
        match ext {
            "json" => Ok(serde_json::from_str(&content)?),
            "toml" => Ok(toml::from_str(&content)?),
            _ => anyhow::bail!("unsupported config format: .{ext} (use .json or .toml)"),
        }
    }

    pub fn validate(&self) -> anyhow::Result<()> {
        if self.users.is_empty() {
            anyhow::bail!("at least one user is required");
        }
        if self.hosts.is_empty() {
            anyhow::bail!("at least one host is required");
        }
        let usernames: Vec<&str> = self.users.iter().map(|u| u.username.as_str()).collect();
        for host in &self.hosts {
            if host.name.is_empty() {
                anyhow::bail!("host name cannot be empty");
            }
            if !usernames.contains(&host.primary_user.as_str()) {
                anyhow::bail!(
                    "host '{}': primary_user '{}' not found in users list",
                    host.name,
                    host.primary_user
                );
            }
            for au in &host.additional_users {
                if !usernames.contains(&au.as_str()) {
                    anyhow::bail!(
                        "host '{}': additional_user '{}' not found in users list",
                        host.name,
                        au
                    );
                }
            }
            if host.platform == Platform::Darwin && host.role == Role::Server {
                anyhow::bail!("host '{}': darwin hosts cannot have server role", host.name);
            }
            for lang in &host.modules.languages {
                let valid = ["rust", "nix", "lua", "markdown", "flutter"];
                if !valid.contains(&lang.as_str()) {
                    anyhow::bail!(
                        "host '{}': unknown language module '{}' (valid: {})",
                        host.name,
                        lang,
                        valid.join(", ")
                    );
                }
            }
        }
        for user in &self.users {
            if user.username.is_empty() {
                anyhow::bail!("username cannot be empty");
            }
            if user.email.is_empty() {
                anyhow::bail!("user '{}': email cannot be empty", user.username);
            }
            let valid_shells = ["fish", "zsh", "bash"];
            if !valid_shells.contains(&user.shell.as_str()) {
                anyhow::bail!(
                    "user '{}': unknown shell '{}' (valid: {})",
                    user.username,
                    user.shell,
                    valid_shells.join(", ")
                );
            }
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn minimal_config() -> Config {
        Config {
            version: 1,
            repo_ref: default_repo_ref(),
            users: vec![UserConfig {
                username: "test".into(),
                name: "Test User".into(),
                email: "test@example.com".into(),
                shell: "fish".into(),
                developer: true,
                ssh_keys: vec![],
            }],
            hosts: vec![HostConfig {
                name: "myhost".into(),
                platform: Platform::Linux,
                arch: Arch::X86_64,
                role: Role::Desktop,
                nixpkgs: NixpkgsChannel::Unstable,
                deploy_mode: DeployMode::Local,
                primary_user: "test".into(),
                additional_users: vec![],
                modules: ModuleSelections {
                    secrets: true,
                    neovim: true,
                    languages: vec!["nix".into()],
                },
            }],
        }
    }

    #[test]
    fn valid_config_passes() {
        minimal_config().validate().unwrap();
    }

    #[test]
    fn empty_users_fails() {
        let mut c = minimal_config();
        c.users.clear();
        assert!(c.validate().is_err());
    }

    #[test]
    fn empty_hosts_fails() {
        let mut c = minimal_config();
        c.hosts.clear();
        assert!(c.validate().is_err());
    }

    #[test]
    fn missing_primary_user_fails() {
        let mut c = minimal_config();
        c.hosts[0].primary_user = "nonexistent".into();
        assert!(c.validate().is_err());
    }

    #[test]
    fn darwin_server_fails() {
        let mut c = minimal_config();
        c.hosts[0].platform = Platform::Darwin;
        c.hosts[0].role = Role::Server;
        assert!(c.validate().is_err());
    }

    #[test]
    fn invalid_language_fails() {
        let mut c = minimal_config();
        c.hosts[0].modules.languages = vec!["cobol".into()];
        assert!(c.validate().is_err());
    }

    #[test]
    fn json_roundtrip() {
        let c = minimal_config();
        let json = serde_json::to_string_pretty(&c).unwrap();
        let loaded: Config = serde_json::from_str(&json).unwrap();
        loaded.validate().unwrap();
    }

    #[test]
    fn toml_roundtrip() {
        let c = minimal_config();
        let t = toml::to_string_pretty(&c).unwrap();
        let loaded: Config = toml::from_str(&t).unwrap();
        loaded.validate().unwrap();
    }
}
