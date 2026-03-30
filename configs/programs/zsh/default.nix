{ ... }:
{ pkgs, ... }:
{
  programs.zsh = {
    initExtra = ''
      export EDITOR=nvim
      export VISUAL=nvim
      export PAGER=less

      tldr() {
        ${pkgs.tealdeer}/bin/tldr "$@"
        local tealdeer_status=$?
        if [ "$tealdeer_status" -eq 0 ]; then
          return 0
        fi

        if [ "$#" -eq 0 ]; then
          return "$tealdeer_status"
        fi

        if [[ "$1" == -* ]]; then
          return "$tealdeer_status"
        fi

        local joined="$1"
        if [ "$#" -gt 1 ]; then
          joined=$(IFS=-; printf '%s' "$*")
        fi

        local page
        for page in "$joined" "$1"; do
          if man -w "$page" >/dev/null 2>&1; then
            command man "$page"
            return $?
          fi
        done

        return "$tealdeer_status"
      }
    '';
  };
}
