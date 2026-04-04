{ desktop ? false }:
{ pkgs, lib, inputs, modules, ... }:
{
  imports = [
    modules.public.homeManager.programs.bat
    modules.public.homeManager.programs.claudeCode
    modules.public.homeManager.programs.codexCli
    modules.public.homeManager.programs.opencode
    modules.public.homeManager.programs.t3codeCli
    modules.public.homeManager.programs.eza
    modules.public.homeManager.programs.fd
  ];

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    zip
    unzip
    sqlite
    ripgrep
    openssl
    fzf
    difftastic
    nushell
    atuin
    python3
    jq
    yq
    wget
    shellcheck
    gnupg
    tealdeer
    procs
    doggo
    bottom
    dust
    gping
    httpie
    glow
  ] ++ lib.optionals desktop [
    nerd-fonts.jetbrains-mono
    yubikey-manager
    yubikey-agent
    age-plugin-yubikey
  ];
}
