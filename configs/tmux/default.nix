{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    shell = "${pkgs.fish}/bin/fish";
    mouse = true;
    baseIndex = 1;
    escapeTime = 10;

    plugins = with pkgs.tmuxPlugins; [
      catppuccin
      sensible
      vim-tmux-navigator
      yank
      resurrect
      battery
      cpu
      prefix-highlight
    ];

    extraConfig = ''
      unbind C-b
      set -g prefix C-a
      bind C-a send-prefix

      bind r source-file ~/.tmux.conf \; display "Config reloaded"

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      bind e previous-window
      bind f next-window
      bind E swap-window -t -1
      bind F swap-window -t +1

      bind = split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      bind a last-window

      set -g status-interval 5
      set -g status-left-length 100
      set -g status-right-length 100
      set -g status-left ""
      set -g status-right "#{E:@catppuccin_status_application}"
      set -agF status-right "#{E:@catppuccin_status_cpu}"
      set -ag status-right "#{E:@catppuccin_status_session}"
      set -ag status-right "#{E:@catppuccin_status_uptime}"
      set -agF status-right "#{E:@catppuccin_status_battery}"

      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"

      set -g set-titles on
      set -g set-titles-string "#S:#I:#W - #T"

      setw -g monitor-activity on
      set -g visual-activity on

      set -g @catppuccin_flavor "mocha"
      set -g @catppuccin_window_status_style "rounded"
      set -g @catppuccin_pane_border_status "off"
      set -g @catppuccin_pane_active_border_style "fg=#{thm_peach}"
      set -g @catppuccin_pane_border_style "fg=#{thm_surface2}"

      set -g @resurrect-dir "~/.tmux/resurrect"
      set -g @resurrect-restore-environment "on"

      set -g @prefix_highlight_show_copy_mode "on"
      set -g @prefix_highlight_copy_mode_attr "fg=white,bg=blue"

      set -g pane-base-index 1
    '';
  };
}
