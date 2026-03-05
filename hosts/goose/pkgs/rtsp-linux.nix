{ stdenv, lib, fetchFromGitHub, kernel }:

stdenv.mkDerivation rec {
  pname = "rtsp-linux";
  version = "unstable-2024-05-02";

  src = fetchFromGitHub {
    owner = "maru-sama";
    repo = "rtsp-linux";
    rev = "5aeee02947c0fad8351e6bf67a6d458488c00250";
    hash = "sha256-qRdi6UHkoRQLdztb1eqUcu0h4ANbL16GSyZdRrDLF2Q=";
  };

  hardeningDisable = [ "pic" ];
  nativeBuildInputs = kernel.moduleBuildDependencies;

  patches = [ ./rtsp-linux.patch ];

  makeFlags = [
    "TARGET=${kernel.modDirVersion}"
    "KERNEL_MODULES=${kernel.dev}/lib/modules/${kernel.modDirVersion}"
    "MODDESTDIR=$(out)/lib/modules/${kernel.modDirVersion}/kernel/net/ipv4/netfilter"
  ];

  meta = with lib; {
    description = "RTSP conntrack/NAT netfilter kernel module";
    homepage = "https://github.com/maru-sama/rtsp-linux";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
