{ lib, stdenvNoCC, fetchurl, unzip }:

stdenvNoCC.mkDerivation rec {
  pname = "impeccable";
  version = "4.7.0";
  engineVersion = "0.1.16";

  src = fetchurl {
    url = "https://github.com/pbakaus/impeccable/releases/download/skill-v${version}/universal.zip";
    hash = "sha256-NYyLa7whE+mRC/StvbpFI2EkU+xY1WpcGxRlRBahP+M=";
  };

  engine = fetchurl {
    url = "https://github.com/pbakaus/impeccable/releases/download/engine-v${engineVersion}/impeccable-darwin-arm64";
    hash = "sha256-XADDEwuWHzqhBm8E7Q4fWOh4CK0VPvoA8cRBhIAAhPI=";
  };

  nativeBuildInputs = [ unzip ];
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  unpackPhase = ''
    runHook preUnpack
    unzip -q "$src" '.agents/*' '.claude/*'
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/impeccable" "$out/bin" "$out/libexec"
    install -m755 "$engine" "$out/libexec/impeccable"
    for provider in agents claude; do
      mkdir -p "$out/share/impeccable/$provider/skills"
      cp -R ".$provider/skills/impeccable" "$out/share/impeccable/$provider/skills/"
      scripts="$out/share/impeccable/$provider/skills/impeccable/scripts"
      test "$(cat "$scripts/VERSION")" = "${engineVersion}"
      chmod +x "$scripts/impeccable"
      mkdir -p "$scripts/bin/darwin-arm64"
      ln -s "$out/libexec/impeccable" "$scripts/bin/darwin-arm64/impeccable"
    done
    cp -R .claude/agents "$out/share/impeccable/claude/"
    cat > "$out/bin/impeccable" <<EOF
    #!${stdenvNoCC.shell}
    exec "$out/share/impeccable/agents/skills/impeccable/scripts/impeccable" "\$@"
    EOF
    chmod +x "$out/bin/impeccable"
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    test "$("$out/bin/impeccable" engine-probe)" = "impeccable-engine ${engineVersion}"
    for provider in agents claude; do
      skill="$out/share/impeccable/$provider/skills/impeccable"
      test -s "$skill/SKILL.md"
      test -s "$skill/reference/audit.md"
      test "$("$skill/scripts/impeccable" engine-probe)" = "impeccable-engine ${engineVersion}"
    done
    runHook postInstallCheck
  '';

  meta = {
    description = "Design skills for AI coding agents with the pinned Impeccable engine";
    homepage = "https://github.com/pbakaus/impeccable";
    license = lib.licenses.asl20;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "impeccable";
  };
}
