{ pkgs }:
{
  mkDeployScript =
    { name
    , host
    , repoName ? "dotfiles-ng"
    , githubRef ? "github:ijohanne/dotfiles-ng"
    , localCheckoutGlobs ? [
        "/home/*/git/${repoName}"
        "/root/git/${repoName}"
      ]
    ,
    }:
    pkgs.writeShellScriptBin name ''
      set -euo pipefail

        if [ "''${1:-}" != "--no-local" ]; then
          for dir in ${builtins.concatStringsSep " " localCheckoutGlobs}; do
            if [ -d "$dir/.git" ]; then
              # Intentionally stage all local changes before rebuilding from a local checkout.
              git -C "$dir" add -A
              exec sudo nixos-rebuild switch --flake "$dir#${host}"
            fi
        done
      fi

      exec sudo nixos-rebuild switch --flake "${githubRef}#${host}" --refresh
    '';

  mkLocalDeployScript =
    { name
    , host
    , rebuildCmd
    , useSudo ? true
    , gitAdd ? true
    , githubRef ? "github:ijohanne/dotfiles-ng"
    , repoCandidates ? [
        "git/private/dotfiles-ng"
        "git/dotfiles-ng"
      ]
    ,
    }:
    pkgs.writeShellScriptBin name ''
      set -euo pipefail

      invoker="''${SUDO_USER:-$USER}"
      invoker_home="$(eval echo "~$invoker")"
      if [[ "$invoker_home" == "~"* ]]; then
        invoker_home="$HOME"
      fi

      if [ "''${1:-}" != "--no-local" ]; then
        selected=""
        checked=""
        for rel in ${builtins.concatStringsSep " " repoCandidates}; do
          candidate="$invoker_home/$rel"
          checked="$checked $candidate"
          if [ -d "$candidate/.git" ]; then
            selected="$candidate"
            break
          fi
        done

        if [ -n "$selected" ]; then
          # Intentionally stage all local changes before rebuilding from a local checkout.
          ${if gitAdd then "git -C \"$selected\" add -A" else ":"}
          exec ${if useSudo then "sudo " else ""}${rebuildCmd} "$selected#${host}"
        fi
      fi

      if ${if useSudo then "sudo " else ""}${rebuildCmd} "${githubRef}#${host}" --refresh; then
        exit 0
      fi

      echo "Failed to deploy ${host}."
      echo "Checked local paths:$checked"
      echo "Fallback reference: ${githubRef}#${host}"
      exit 1
    '';
}
