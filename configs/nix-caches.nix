{ ... }:

{
  nix.settings = {
    substituters = [
      "https://cache.garnix.io"
      "https://codex-cli.cachix.org"
      "https://cache.numtide.com"
      "https://nix-cache.unixpimps.net/ijohanne"
    ];
    trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "codex-cli.cachix.org-1:1Br3H1hHoRYG22n//cGKJOk3cQXgYobUel6O8DgSing="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "ijohanne:55EJTBFbq5pCYx2tf+aR8pmVPvCmP7QlafHH90/kikw="
    ];
  };
}
