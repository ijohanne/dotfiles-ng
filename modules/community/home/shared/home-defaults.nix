{ pkgs, lib, user, hmStateVersion ? "22.05", ... }:

{
  home = {
    stateVersion = lib.mkDefault hmStateVersion;
    username = lib.mkDefault user.username;
    homeDirectory = lib.mkDefault (
      if pkgs.stdenv.isDarwin then "/Users/${user.username}" else "/home/${user.username}"
    );
  };
}
