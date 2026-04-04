{ host, sopsFile, installDeployScript ? true }:

import ../../../../configs/managed-remote-host.nix {
  inherit host sopsFile installDeployScript;
}
