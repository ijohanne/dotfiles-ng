{ ... }:
{ user, ... }:
{
  programs.gh.enable = true;

  programs.git = {
    enable = true;
    settings = {
      user.name = user.name;
      user.email = user.email;
      init.defaultBranch = "master";
      pull.rebase = true;
      pull.ff = "only";
      status.submodule = "summary";
      commit.gpgsign = true;
      merge.conflictstyle = "diff3";
      diff.color = "auto";
      diff.mnemonicPrefix = true;
      diff.relativeDate = true;
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
    };
    lfs.enable = true;
  };
}
