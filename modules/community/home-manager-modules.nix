{
  programs = {
    agentSkillsCli = ../../configs/programs/agent-skills-cli;
    bash = ../../configs/programs/bash;
    bat = ../../configs/programs/bat;
    callis = ../../configs/programs/callis;
    claudeCode = ../../configs/programs/claude-code;
    codexCli = ../../configs/programs/codex-cli;
    delta = ../../configs/programs/delta;
    direnv = ../../configs/programs/direnv;
    eza = ../../configs/programs/eza;
    fd = ../../configs/programs/fd;
    fish = ../../configs/programs/fish;
    ghostty = ../../configs/programs/ghostty;
    git = ../../configs/programs/git;
    htop = ../../configs/programs/htop;
    kitty = ../../configs/programs/kitty;
    lazygit = ../../configs/programs/lazygit;
    leita = ../../configs/programs/leita;
    lorri = ../../configs/programs/lorri;
    neovim = ../../configs/programs/neovim;
    opencode = ../../configs/programs/opencode;
    procs = ../../configs/programs/procs;
    ssh = ../../configs/programs/ssh;
    starship = ../../configs/programs/starship;
    t3code = ../../configs/programs/t3code;
    t3codeCli = ../../configs/programs/t3code-cli;
    tmux = ../../configs/programs/tmux;
    vardrun = ../../configs/programs/vardrun;
    vim = ../../configs/programs/vim;
    zed = ../../configs/programs/zed;
    zoxide = ../../configs/programs/zoxide;
    zsh = ../../configs/programs/zsh;
  };

  languages = {
    default = ../../configs/dev/languages;
    flutter = ../../configs/dev/languages/flutter;
    lua = ../../configs/dev/languages/lua;
    markdown = ../../configs/dev/languages/markdown;
    nix = ../../configs/dev/languages/nix;
    rust = ../../configs/dev/languages/rust;
  };

  aspects = {
    cliBase = ./home/aspects/cli-base.nix;
    developerBase = ./home/aspects/developer-base.nix;
  };
}
