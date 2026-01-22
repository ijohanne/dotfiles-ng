{ config, pkgs, user, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = user.name;
      user.email = user.email;
      init.defaultBranch = "master";
      pull.rebase = true;
      diff.color = "auto";
      status.submodule = "summary";
      lfs.enable = true;
      commit.gpgsign = true;
      extraConfig = { pull = { ff = "only"; }; };
    };
  };
}
