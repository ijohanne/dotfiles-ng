{ desktop ? false }:
{ ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      forwardAgent = desktop;
      extraOptions =
        if desktop then {
          PubkeyAuthentication = "unbound";
        } else { };
    };
  };
}
