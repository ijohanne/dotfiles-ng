{ automatic ? true, dates ? "weekly", options ? "--delete-older-than 30d" }:

{ lib, ... }:

{
  nix.gc =
    { inherit automatic; }
    // lib.optionalAttrs (dates != null) { inherit dates; }
    // lib.optionalAttrs (options != null) { inherit options; };
}
