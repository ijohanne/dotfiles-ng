{ config, pkgs, lib, user, modules, ... }:

{
  imports = [
    (import modules.private.home.users.ij { desktop = true; })
  ];
}
