{ network, ... }:

{ ... }:

{
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "${network.hosts.wg-goose.ip}/24" ];
      listenPort = 51820;
      privateKeyFile = "/run/secrets/wireguard_private_key";

      peers = [
        {
          publicKey = "mZHS9vjE3fKHMN+a2wTx4Zo0NQsWMqcUGQAaH2qQdAY=";
          allowedIPs = [ "${network.hosts.wg-peer-2.ip}/32" ];
        }
        {
          publicKey = "LsjFCqeOnJvjM2Xo2jUKbnHjii6Mjm5UP9qEPCVLVFg=";
          allowedIPs = [ "${network.hosts.wg-peer-3.ip}/32" ];
        }
        {
          publicKey = "hyZuVr+T+FD0uVYtMvTr+XMkIrcdRPhjKC+Y9zbFPFs=";
          allowedIPs = [ "${network.hosts.wg-peer-4.ip}/32" ];
        }
        {
          publicKey = "AzcORdSkMEKnh5dVRdsXm0UNBF6/99GkiFwQER88f2I=";
          allowedIPs = [ "${network.hosts.wg-peer-5.ip}/32" ];
        }
        {
          publicKey = "/S12fraeoJml9vnDOtyE5DXui00pdiD7Obr36s+pLhk=";
          allowedIPs = [ "${network.hosts.wg-peer-6.ip}/32" ];
        }
        {
          publicKey = "/O5FtOl5bYFlpM7T/oQNOpMh4sXlkQLypHoOlSmud1I=";
          allowedIPs = [ "${network.hosts.wg-peer-7.ip}/32" ];
        }
        {
          # khosu (mail relay VPS)
          publicKey = "5Z+G9RwfwJXFFy9E/nFg6eRi416G+J3eWwptkxXXZzY=";
          allowedIPs = [ "${network.hosts.wg-khosu.ip}/32" ];
        }
      ];
    };
  };
}
