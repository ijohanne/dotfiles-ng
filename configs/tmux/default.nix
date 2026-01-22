{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    shell = "${pkgs.fish}/bin/fish";
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      sensible
      yank
    ];
    extraConfig = ''
      set -g mouse on
      set -g escape-time 10
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"
    '';
  };
}
