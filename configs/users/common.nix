{ desktop ? false }:
{ pkgs, lib, inputs, ... }:
{
  imports = [
    ../programs/bat
    ../programs/eza
    ../programs/fd
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
    inputs.leita.packages.${pkgs.system}.leita
  ] ++ lib.optionals desktop [
    nerd-fonts.jetbrains-mono
    yubikey-manager
    yubikey-agent
    age-plugin-yubikey
    inputs.claude-code-nix.packages.${pkgs.system}.claude-code
  ];
}
