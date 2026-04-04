{ pkgs, lib, user, ... }:
let
  isDeveloper = user.developer or false;
in
{
  systemd.user.services.lorri = lib.mkIf (pkgs.stdenv.isLinux && isDeveloper) {
    Unit = {
      Description = "Lorri Nix shell env daemon";
      After = [ "nix-daemon.socket" ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      ExecStart = "${pkgs.lorri}/bin/lorri daemon";
      Restart = "on-failure";
    };
  };
}
