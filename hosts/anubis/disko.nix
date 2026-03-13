{
  disko.devices = {
    disk = {
      disk0 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-HGST_HUS726T4TALA6L1_V6GXVWPS";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
            };
            mdadm-boot = {
              size = "512M";
              content = {
                type = "mdraid";
                name = "boot";
              };
            };
            mdadm-root = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "root";
              };
            };
          };
        };
      };
      disk1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-HGST_HUS726T4TALA6L1_V6GEAMHS";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
            };
            mdadm-boot = {
              size = "512M";
              content = {
                type = "mdraid";
                name = "boot";
              };
            };
            mdadm-root = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "root";
              };
            };
          };
        };
      };
    };
    mdadm = {
      boot = {
        type = "mdadm";
        level = 1;
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/boot";
        };
      };
      root = {
        type = "mdadm";
        level = 0;
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/";
        };
      };
    };
  };
}
