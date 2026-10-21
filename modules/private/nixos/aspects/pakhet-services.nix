{ lib, ... }:

let
  patchPhp = package: version: hash:
    if lib.versionAtLeast package.version version then package
    else
      (package.buildEnv { inherit version hash; }).withExtensions
        ({ enabled, ... }:
          map
            (extension:
              if extension.extensionName != "filter" then extension
              else
                extension.overrideAttrs (old: {
                  # CGI subprocesses started with -n must load Nix's shared extension.
                  postPatch = (old.postPatch or "") + ''
                    substituteInPlace \
                      ext/filter/tests/oom_filter_default_encoded.phpt \
                      ext/filter/tests/oom_filter_input.phpt \
                      ext/filter/tests/oom_filter_input_array.phpt \
                      --replace-fail "getenv('TEST_PHP_CGI_EXECUTABLE'), '-n'," \
                        "getenv('TEST_PHP_CGI_EXECUTABLE'), '-n', '-d', 'extension=' . __DIR__ . '/../modules/filter.so',"
                  '';
                }))
            enabled);
in
{
  imports = [
    ../services/pakhet
  ];

  # CVE-2026-109618 and CVE-2026-109619; defer to Nixpkgs once its fixes land.
  nixpkgs.overlays = [
    (final: prev: {
      php83 = patchPhp prev.php83 "8.3.36" "sha256-RvS0XjaI7SsYGQFae1MsFbUcwFW907E/0A3f7r7tzV8=";
      php84 = patchPhp prev.php84 "8.4.27" "sha256-slMKh3xyL0sIyeF0owywi6wrfhkD7m6eMV8KqfX4LCQ=";
    })
  ];
}
