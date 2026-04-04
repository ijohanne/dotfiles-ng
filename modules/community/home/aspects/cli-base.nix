{ desktop ? false }:
{
  imports = [
    (import ../../../../configs/users/common.nix { inherit desktop; })
  ];
}
