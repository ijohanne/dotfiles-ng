{
  shared = {
    common = ./home/shared/common.nix;
    homeDefaults = ./home/shared/home-defaults.nix;
  };

  programs = {
    agentSkillsCli = ./home/programs/agent-skills-cli;
    bash = ./home/programs/bash;
    bat = ./home/programs/bat;
    callis = ./home/programs/callis;
    claudeCode = ./home/programs/claude-code;
    codexCli = ./home/programs/codex-cli;
    delta = ./home/programs/delta;
    direnv = ./home/programs/direnv;
    eza = ./home/programs/eza;
    fd = ./home/programs/fd;
    fish = ./home/programs/fish;
    ghostty = ./home/programs/ghostty;
    git = ./home/programs/git;
    htop = ./home/programs/htop;
    kitty = ./home/programs/kitty;
    lazygit = ./home/programs/lazygit;
    leita = ./home/programs/leita;
    neovim = ./home/programs/neovim;
    opencode = ./home/programs/opencode;
    procs = ./home/programs/procs;
    ssh = ./home/programs/ssh;
    starship = ./home/programs/starship;
    t3code = ./home/programs/t3code;
    t3codeCli = ./home/programs/t3code-cli;
    tmux = ./home/programs/tmux;
    vardrun = ./home/programs/vardrun;
    vim = ./home/programs/vim;
    zed = ./home/programs/zed;
    zoxide = ./home/programs/zoxide;
    zsh = ./home/programs/zsh;
  };

  languages = {
    default = ./home/languages;
    flutter = ./home/languages/flutter;
    lua = ./home/languages/lua;
    markdown = ./home/languages/markdown;
    nix = ./home/languages/nix;
    rust = ./home/languages/rust;
  };

  aspects = {
    cliBase = ./home/aspects/cli-base.nix;
    developerBase = ./home/aspects/developer-base.nix;
  };
}
