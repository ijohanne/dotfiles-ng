{ host, sopsFile, installDeployScript ? true }:

import ./managed-remote-host-impl.nix {
  inherit host sopsFile installDeployScript;
}
