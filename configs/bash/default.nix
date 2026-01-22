{ ... }:

{
  programs.bash = {
    enable = true;
    initExtra = ''
      export EDITOR=nvim
      export VISUAL=nvim
      export PAGER=less
    '';
  };
}
