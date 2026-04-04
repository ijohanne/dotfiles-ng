{ automatic ? true, interval ? null, options ? null }:

{ lib, ... }:

{
  nix.gc =
    { inherit automatic; }
    // lib.optionalAttrs (interval != null) { inherit interval; }
    // lib.optionalAttrs (options != null) { inherit options; };
}
