{ name, host, rebuildCmd ? "nixos-rebuild switch --flake", useSudo ? true, gitAdd ? true }:

{ pkgs, ... }:

let
  deploy = import ../../../../configs/deploy { inherit pkgs; };
in
{
  environment.systemPackages = [
    (deploy.mkLocalDeployScript {
      inherit name host rebuildCmd useSudo gitAdd;
    })
  ];
}
