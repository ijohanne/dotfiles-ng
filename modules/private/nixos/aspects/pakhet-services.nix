{ inputs, pkgs, ... }:

{
  imports = [
    ../services/pakhet
  ];

  # Remove this override and the nixpkgs-pakhet-clamav input once the locked
  # nixpkgs-stable ClamAV contains the November 2026 fixes (CVE-2026-76422
  # and related advisories). The first fixed versions are 1.4.7 on 1.4 and
  # 1.5.5 on 1.5. ClamAV 1.5.4 still needs the override.
  services.clamav.package = inputs.nixpkgs-pakhet-clamav.legacyPackages.${pkgs.stdenv.hostPlatform.system}.clamav;
}
