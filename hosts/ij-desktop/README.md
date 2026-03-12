# ij-desktop

## Bootstrap (Fresh Install)

Boot from the NixOS minimal installer USB. Once booted:

```bash
# 1. Connect to the internet (ethernet recommended, or use iwctl for wifi)

# 2. Clone the repo
nix-shell -p git
git clone https://github.com/ijohanne/dotfiles-ng.git
cd dotfiles-ng

# 3. Import GPG public key (needed to decrypt the LUKS passphrase)
gpg --import secrets/ij-public-key.gpg

# 4. Partition and format the disk with disko
#    Insert YubiKey — disko will prompt for the LUKS passphrase.
#    Decrypt it first, then paste when prompted:
gpg --decrypt hosts/ij-desktop/luks-passphrase.gpg
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
    --mode disko hosts/ij-desktop/disko.nix

# 5. Install NixOS
sudo nixos-install --flake .#ij-desktop --no-root-passwd

# 6. Reboot — insert YubiKey, enter GPG PIN at boot to unlock LUKS
reboot
```

After first boot, clone the repo again under your user and rebuild:

```bash
mkdir -p ~/git/private
cd ~/git/private
git clone https://github.com/ijohanne/dotfiles-ng.git
cd dotfiles-ng
sudo nixos-rebuild switch --flake .#ij-desktop
```

## Disk Layout

NixOS lives on `/dev/nvme0n1` (LUKS-encrypted BTRFS), Windows on a separate disk.

### Partitions (nvme0n1)

| Partition | Size | Type | Content |
|-----------|------|------|---------|
| ESP | 1G | EF00 | systemd-boot (`/boot`) |
| luks | remainder | LUKS2 | BTRFS |

### BTRFS Subvolumes

| Subvolume | Mountpoint | Options |
|-----------|------------|---------|
| `@` | `/` | compress=zstd, noatime |
| `@home` | `/home` | compress=zstd, noatime |
| `@nix` | `/nix` | compress=zstd, noatime |
| `@log` | `/var/log` | compress=zstd, noatime |
| `@swap` | `/.swap` | 8G swapfile |

## YubiKey LUKS Enrollment

The LUKS passphrase is encrypted with GPG and decrypted at boot using the YubiKey's smartcard interface. The initrd prompts for your YubiKey PIN to unlock.

### Prerequisites

- YubiKey with GPG keys loaded (encryption subkey `9CA0EF672EDF5C4C`)
- GPG public key already in repo at `secrets/ij-public-key.gpg`

### Generate the encrypted passphrase

```bash
# Generate a strong random passphrase
dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64 > /tmp/luks-passphrase.txt

# Encrypt it with the YubiKey's GPG encryption subkey
gpg --recipient 9CA0EF672EDF5C4C \
    --output hosts/ij-desktop/luks-passphrase.gpg \
    --encrypt /tmp/luks-passphrase.txt

# Shred the plaintext
shred -u /tmp/luks-passphrase.txt
```

### Provision the disk

```bash
# From the NixOS installer (with dotfiles repo cloned):
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
    --mode disko hosts/ij-desktop/disko.nix

# The LUKS passphrase must be entered in plaintext during initial disko provisioning.
# Retrieve it temporarily:
gpg --decrypt hosts/ij-desktop/luks-passphrase.gpg

# After disko completes, install NixOS:
sudo nixos-install --flake .#ij-desktop
```

### Boot flow

1. BIOS/UEFI loads systemd-boot from ESP
2. Initrd detects LUKS volume and waits for YubiKey
3. PIN prompt appears — enter YubiKey GPG PIN
4. GPG decrypts `luks-passphrase.gpg` using the smartcard
5. Decrypted passphrase unlocks LUKS
6. BTRFS subvolumes are mounted and boot continues

### Re-enrolling with a new YubiKey

```bash
# Re-encrypt the passphrase with the new key
gpg --decrypt hosts/ij-desktop/luks-passphrase.gpg > /tmp/luks-passphrase.txt
gpg --recipient <new-encryption-subkey-id> \
    --output hosts/ij-desktop/luks-passphrase.gpg \
    --encrypt /tmp/luks-passphrase.txt
shred -u /tmp/luks-passphrase.txt

# Update secrets/ij-public-key.gpg if the master key changed
gpg --export <new-key-id> > secrets/ij-public-key.gpg

# Rebuild
sudo nixos-rebuild switch --flake .#ij-desktop
```

## Windows Dual Boot

Windows is installed on a separate physical disk. systemd-boot automatically detects the Windows Boot Manager if the Windows disk's ESP contains `EFI/Microsoft/Boot/bootmgfw.efi`.

### Setup

1. Install Windows on the second disk first (or independently)
2. Ensure the BIOS boot order has the NixOS NVMe first
3. systemd-boot scans all ESPs by default and adds a "Windows Boot Manager" entry

If Windows is not auto-detected, mount the Windows ESP and copy its boot files:

```bash
# Find the Windows ESP (e.g. /dev/sda1)
lsblk -f | grep -i vfat

# Mount and copy Windows boot entry to NixOS ESP
mount /dev/sda1 /mnt/win-esp
cp -r /mnt/win-esp/EFI/Microsoft /boot/EFI/Microsoft
umount /mnt/win-esp
```

Alternatively, add to `configuration.nix`:

```nix
boot.loader.systemd-boot.extraEntries."windows.conf" = ''
  title Windows
  efi /EFI/Microsoft/Boot/bootmgfw.efi
'';
```

At boot, press a key or use the systemd-boot menu to select between NixOS and Windows.
