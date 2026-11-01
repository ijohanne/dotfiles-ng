{ lib, buildGoModule, fetchurl }:
let
  revision = "3c32125946ecd58db2c30349d3a3ff459fa22ad8";
  docsRevision = "bd8a3f4fe92454ea0709895d6d9c771b8e86e710";
  docs = fetchurl {
    url = "https://github.com/prometheus/docs/archive/${docsRevision}.tar.gz";
    hash = "sha256-vll6C6ald2VKTFngV8SB0qNGyGxEnkYnFfiagQSy4ZY=";
  };
in
buildGoModule {
  pname = "prometheus-mcp";
  version = "0.19.0-dev-${builtins.substring 0 7 revision}";
  src = fetchurl {
    url = "https://github.com/prometheus/prometheus-mcp/archive/${revision}.tar.gz";
    hash = "sha256-ktvUktF2o67zksEcNw/+StTcHETu+ruftlWe+4KwOE0=";
  };
  patches = [ ./oauth-and-external-skills.patch ];
  vendorHash = "sha256-h4YgBzLTD2sWIy85ntDMlYvVeNk1AHZ1Btr2Srlk8aw=";
  postPatch = ''
    mkdir -p cmd/prometheus-mcp/external/docs
    tar -xzf ${docs} --strip-components=1 -C cmd/prometheus-mcp/external/docs
    echo ${docsRevision} > cmd/prometheus-mcp/external/docs/COMMIT_HASH
  '';
  subPackages = [ "cmd/prometheus-mcp" ];
  checkPhase = ''
    runHook preCheck
    go test ./cmd/prometheus-mcp ./pkg/mcp
    runHook postCheck
  '';
  ldflags = [ "-s" "-w" "-X github.com/prometheus/common/version.Revision=${revision}" ];
  meta = {
    description = "Prometheus MCP with OAuth resource protection, TOON and service skills";
    homepage = "https://github.com/prometheus/prometheus-mcp";
    license = lib.licenses.asl20;
    mainProgram = "prometheus-mcp";
  };
}
