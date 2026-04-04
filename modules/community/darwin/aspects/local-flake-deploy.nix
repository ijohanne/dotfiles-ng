{ name, host, rebuildCmd ? "darwin-rebuild switch --flake", useSudo ? true, gitAdd ? true }:

{ pkgs, modules, ... }:

let
  deploy = modules.public.lib.deploy { inherit pkgs; };
in
{
  environment.systemPackages = [
    (deploy.mkLocalDeployScript {
      inherit name host rebuildCmd useSudo gitAdd;
    })
  ];
}
