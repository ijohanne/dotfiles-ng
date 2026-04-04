{ desktop ? false }:
{
  imports = [
    (import ../shared/common.nix { inherit desktop; })
  ];
}
