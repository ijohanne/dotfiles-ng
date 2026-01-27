{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.local.dock;
  inherit (pkgs) stdenv dockutil;
in
{
  options = {
    local.dock = {
      enable = mkOption {
        description = "Enable dock";
        default = stdenv.isDarwin;
      };

      entries = mkOption {
        description = "Entries on the Dock";
        type =
          with types;
          listOf (submodule {
            options = {
              path = lib.mkOption { type = str; };
              section = lib.mkOption {
                type = str;
                default = "apps";
              };
              options = lib.mkOption {
                type = str;
                default = "";
              };
            };
          });
        readOnly = true;
      };

      username = mkOption {
        description = "Username to apply the dock settings to";
        type = types.str;
      };
    };
  };

  config = mkIf cfg.enable (
    let
      normalize = path: if hasSuffix ".app" path then path + "/" else path;
      entryURI =
        path:
        "file://"
        + (builtins.replaceStrings
          [ " " "!" "\"" "#" "$" "%" "&" "'" "(" ")" ]
          [ "%20" "%21" "%22" "%23" "%24" "%25" "%26" "%27" "%28" "%29" ]
          (normalize path)
        );
      wantURIs = concatMapStrings (entry: "${entryURI entry.path}\n") cfg.entries;
      plist = "/Users/${cfg.username}/Library/Preferences/com.apple.dock.plist";
      createEntries =
        concatMapStrings
          (entry:
            "${dockutil}/bin/dockutil --no-restart --add '${entry.path}' --section ${entry.section} ${entry.options} ${plist}\n"
          )
          cfg.entries;
      dockSetupScript = pkgs.writeShellScript "dock-setup" ''
        echo >&2 "Resetting Dock."
        ${dockutil}/bin/dockutil --no-restart --remove all ${plist}
        ${createEntries}
        killall Dock
        echo >&2 "Dock setup complete."
      '';
    in
    {
      system.activationScripts.postActivation.text = ''
        echo >&2 "Setting up the Dock for ${cfg.username}..."
        sudo -u ${cfg.username} ${dockSetupScript}
      '';
    }
  );
}
