{ automatic ? true, dates ? null, options ? null }:

{ lib, ... }:

{
  nix.gc =
    { inherit automatic; }
    // lib.optionalAttrs (dates != null) { inherit dates; }
    // lib.optionalAttrs (options != null) { inherit options; };
}
