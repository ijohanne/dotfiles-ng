# dotfiles

[![CI](https://github.com/ijohanne/dotfiles-ng/actions/workflows/ci.yml/badge.svg)](https://github.com/ijohanne/dotfiles-ng/actions/workflows/ci.yml)

Nix-based dotfiles for managing macOS and Linux configurations.

## Table of Contents

- [Overview](#overview)
  - [Hosts](#hosts)
  - [Structure](#structure)
  - [User Settings](#user-settings)
- [Network](NETWORK.md)
- [Quick Start](#quick-start)
- [Installation](#installation)
  - [macOS Setup](#macos-setup)
  - [Linux Desktop Setup](#linux-desktop-setup)
  - [Anubis (OVH Kimsufi)](#anubis-ovh-kimsufi)
  - [Khosu (netcup VPS)](#khosu-netcup-vps)
  - [Goose (Router)](#goose-router)
  - [Pakhet (Application Server)](#pakhet-application-server)
  - [bhyve VM Images](#bhyve-vm-images)
  - [Raspberry Pi 4 Image](#raspberry-pi-4-image)
  - [RTSP Dev VM](#rtsp-dev-vm)
- [Setup Template Generator](#setup-template-generator)
- [Reference](#reference)
  - [Terminal Tools](#terminal-tools)
  - [Neovim](#neovim)
  - [Tmux](#tmux)
  - [Secrets Management](#secrets-management)

## Overview

### Hosts

- **macbook** — macOS (aarch64-darwin)
- **ij-desktop** — Linux (x86_64-linux)
- **goose** — NixOS router/firewall (x86_64-linux)
- **anubis** — NixOS torrent host on OVH Kimsufi (x86_64-linux)
- **khosu** — NixOS mail relay VPS on netcup (x86_64-linux)
- **pakhet** — NixOS application server (x86_64-linux)
- **bhyve-image** — Minimal bhyve VM image (x86_64-linux)
- **bhyve-image-server** — bhyve VM image with server users and home-manager (x86_64-linux)
- **rpi4-stable** — Raspberry Pi 4 SD card image (aarch64-linux, nixos-25.11)
- **rpi4-unstable** — Raspberry Pi 4 SD card image (aarch64-linux, nixos-unstable)

### Structure

- `hosts/` — Host-specific configurations
- `configs/` — Shared configurations for various programs
- `lib/` — Shared library definitions

### User Settings

User settings are defined in `lib/user.nix`:

```nix
{
  username = "ij";
  email = "ij@opsplaza.com";
  name = "Ian Johannesen";
  developer = true;  # Enable LSP for neovim, lorri daemon, dev packages
}
```

#### Developer Setting

When `developer = true`:
- Neovim LSP is enabled (nixd, rust-analyzer, lua_ls)
- Neovim completion (nvim-cmp) with LSP sources
- LSP keybindings (gd, gr, K, leader ca)
- Lorri daemon service (Linux only)
- Dev language servers (nixd, lua-language-server)

When `developer = false`:
- Basic neovim without LSP
- No completion engine
- No LSP keybindings
- No lorri daemon

## Quick Start

```bash
# macOS
darwin-rebuild switch --flake .#macbook

# Linux (NixOS)
sudo nixos-rebuild switch --flake .#ij-desktop

# goose (router)
sudo nixos-rebuild switch --flake .#goose

# pakhet (application server)
sudo nixos-rebuild switch --flake .#pakhet

# Remote hosts (build on pakhet which has access tokens for private flakes)
nix run nixpkgs#nixos-rebuild -- switch \
  --flake .#anubis \
  --target-host root@anubis.unixpimps.net \
  --build-host root@pakhet.est.unixpimps.net

nix run nixpkgs#nixos-rebuild -- switch \
  --flake .#khosu \
  --target-host root@khosu.unixpimps.net \
  --build-host root@pakhet.est.unixpimps.net
```

## Installation

### macOS Setup

#### Prerequisites

1. Install Nix:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. Enable flakes (if not using Determinate installer):
   ```bash
   mkdir -p ~/.config/nix
   echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
   ```

#### Installation Steps

1. Clone this repository:
   ```bash
   git clone https://github.com/ijohanne/dotfiles-ng.git ~/dotfiles
   cd ~/dotfiles
   ```

2. Edit `lib/user.nix` with your details:
   ```nix
   {
     username = "your-username";
     email = "your@email.com";
     name = "Your Name";
     developer = true;
   }
   ```

3. Bootstrap nix-darwin (first time only):
   ```bash
   nix run nix-darwin -- switch --flake .#macbook
   ```

4. After bootstrap, use darwin-rebuild:
   ```bash
   darwin-rebuild switch --flake .#macbook
   ```

#### First Run

On a fresh setup, pass the Zed binary cache substituters to avoid building Zed from source:

```bash
darwin-rebuild switch --flake .#macbook \
  --option extra-substituters "https://zed.cachix.org https://cache.garnix.io" \
  --option extra-trusted-public-keys "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU= cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
```

After this first rebuild, the substituters are persisted in `nix.settings` and subsequent rebuilds will use the cache automatically.

#### Post-Installation

- Restart your terminal to load fish shell
- Touch ID for sudo is enabled automatically

#### Remote Builder

The macbook is configured to use pakhet (10.255.101.200) as a remote builder for x86_64-linux and aarch64-linux builds.

After deploying the configuration, run the setup script to add the remote builder's SSH host key:

```bash
setup-remote-builder
```

This will:
1. Add pakhet's SSH host key to root's known_hosts
2. Test the connection to verify everything works

### Linux Desktop Setup

The Linux desktop uses disko for declarative disk partitioning with LUKS encryption.

#### Disk Layout

- `/boot` — 512MB EFI System Partition (FAT32)
- LUKS encrypted partition containing LVM:
  - `swap` — 8GB swap with hibernation support
  - `root` — Remaining space as ext4

#### Installation Steps

1. Boot NixOS installer

2. Edit `hosts/ij-desktop/disko.nix` if your disk is not `/dev/nvme0n1`

3. Partition and format the disk:
   ```bash
   sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko ./hosts/ij-desktop/disko.nix
   ```

4. Mount the partitions (disko does this, but verify):
   ```bash
   mount | grep /mnt
   ```

5. Install NixOS:
   ```bash
   sudo nixos-install --flake .#ij-desktop
   ```

6. Set the LUKS password when prompted during first boot

7. After installation, rebuild with:
   ```bash
   sudo nixos-rebuild switch --flake .#ij-desktop
   ```

### Anubis (OVH Kimsufi)

Anubis is a dedicated server on OVH Kimsufi (OVH Eco). It uses disko with mdadm RAID across two disks and is installed via [nixos-anywhere](https://github.com/nix-community/nixos-anywhere).

#### Prerequisites

- An OVH Kimsufi dedicated server
- Boot the server into OVH rescue mode (which provides SSH root access)
- Ensure you can SSH as root to the server IP (`5.196.77.4`)

#### Installation

1. From your local machine (requires `nix_builder_access_tokens` configured locally for private flake inputs):
   ```bash
   nix run github:nix-community/nixos-anywhere -- \
     --flake .#anubis \
     --phases kexec,disko,install \
     root@5.196.77.4
   ```

   **`--phases kexec,disko,install` (no reboot) is mandatory on Kimsufi.** See the warning section below.

2. After nixos-anywhere completes, note the age key it prints. Update `.sops.yaml` with this key and re-encrypt secrets:
   ```bash
   sops updatekeys secrets/anubis.yaml
   ```

3. In the OVH panel, change netboot from "rescue" to "Boot from the hard disk".

4. Reboot the server from the OVH panel.

5. Once NixOS boots, push the updated secrets and deploy (build on pakhet which has `nix_builder_access_tokens` for private flake inputs):
   ```bash
   nix run nixpkgs#nixos-rebuild -- switch \
     --flake .#anubis \
     --target-host root@anubis.unixpimps.net \
     --build-host root@pakhet.est.unixpimps.net
   ```

#### Disk Layout

Defined in `hosts/anubis/disko.nix`:
- 2x 4TB HGST disks (by-id references)
- 512MB EFI System Partition (EF00) on each disk
- mdadm RAID-0 across both disks for root (ext4)
- GRUB EFI with `mirroredBoots` to both ESPs

#### OVH Kimsufi Warnings

Kimsufi servers have a Java-based IP KVM (JNLP), but no standard IPMI. If the system doesn't boot, rescue mode is your primary recovery option. To access the KVM console, download the `.jnlp` file from the OVH panel and run it with the flake's devshell tool:

```bash
jnlp-run /path/to/kvm.jnlp
```

These deployment lessons are hard-won:

- **Always use `--phases kexec,disko,install`** — never let nixos-anywhere reboot the server. Kimsufi rescue mode is netboot-based: every reboot returns to rescue until you explicitly change the boot device in the OVH panel. If nixos-anywhere reboots, you'll land back in rescue instead of NixOS.
- **Disable OVH monitoring before kexec** — the kexec step can trigger OVH's automated monitoring, which logs an "intervention" that temporarily blocks netboot changes in the panel. Disable monitoring in the OVH panel first.
- **`boot.swraid.enable = true` is required for mdadm** — disko creates the RAID arrays but does not set this option. Without it, the initrd won't assemble the arrays and the system won't boot.
- **The age key changes on every nixos-anywhere run** — always update `.sops.yaml` and run `sops updatekeys` after install, before the first real boot.
- **Verify critical boot config before deploying** — use `nix eval .#nixosConfigurations.anubis.config.boot.swraid.enable` and similar checks. Each failed boot costs significant time since you must re-enter rescue mode and re-run nixos-anywhere.
- **UEFI, not BIOS** — Kimsufi servers use UEFI boot. Use EF00 (ESP) partitions, not EF02 (BIOS boot).

### Khosu (netcup VPS)

Khosu is a VPS on netcup running as a mail relay. It uses disko for disk partitioning and is installed via [nixos-anywhere](https://github.com/nix-community/nixos-anywhere).

#### Prerequisites

- A netcup VPS (KVM-based, virtio disk at `/dev/vda`)
- Access to the netcup SCP (Server Control Panel) for VNC console and rescue
- Boot the VPS into a NixOS installer ISO or any Linux with SSH and root access
- Ensure you can SSH as root to the VPS IP (`159.195.24.170`)

#### Installation

1. From your local machine (requires `nix_builder_access_tokens` configured locally for private flake inputs):
   ```bash
   nix run github:nix-community/nixos-anywhere -- --flake .#khosu root@159.195.24.170
   ```

   This will:
   - Partition the disk using `hosts/khosu/disko.nix` (GPT with BIOS boot + ext4 root on `/dev/vda`)
   - Install NixOS with the khosu configuration
   - Set up GRUB bootloader
   - Reboot automatically

2. After installation completes, the VPS will reboot into NixOS. For the first deploy (before sops has decrypted `nix_builder_access_tokens` on the host), build on pakhet:
   ```bash
   nix run nixpkgs#nixos-rebuild -- switch \
     --flake .#khosu \
     --target-host root@khosu.unixpimps.net \
     --build-host root@pakhet.est.unixpimps.net
   ```
   Subsequent deploys can use `ssh khosu.unixpimps.net deploy-khosu`.

#### Disk Layout

Defined in `hosts/khosu/disko.nix`:
- 1MB BIOS boot partition (EF02, for GRUB on GPT)
- Remaining space as ext4 root

#### netcup Notes

netcup is more straightforward than OVH Kimsufi:

- **Automatic reboot is safe** — unlike Kimsufi, netcup doesn't have netboot. The VPS boots from its virtual disk by default, so nixos-anywhere can reboot without issues (no need for `--phases`).
- **VNC console available** — the SCP provides a VNC console for debugging boot issues, so you're not flying blind.
- **BIOS boot, not UEFI** — netcup KVM VPSes use BIOS boot. Use an EF02 partition (not EF00/ESP) with GRUB.
- **virtio disk** — the disk is always `/dev/vda` via virtio-blk. Use `/dev/vda` in disko, not by-id paths.
- **Rescue via ISO mount** — if the VPS doesn't boot, you can mount a rescue ISO from the SCP media panel and access the disk from there.

### Goose (Router)

Goose is a physical x86_64 AMD machine acting as the network router/gateway. It uses systemd-boot with a btrfs root on NVMe.

#### Prerequisites

- Physical access or IPMI/KVM to the machine
- Boot a NixOS installer USB

#### Installation

1. Boot the NixOS installer

2. Partition the disk manually (goose does not use disko):
   ```bash
   # Create GPT partition table on /dev/nvme0n1
   parted /dev/nvme0n1 -- mklabel gpt
   parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
   parted /dev/nvme0n1 -- set 1 esp on
   parted /dev/nvme0n1 -- mkpart primary 512MiB 100%

   # Format
   mkfs.fat -F 32 /dev/nvme0n1p1
   mkfs.btrfs /dev/nvme0n1p2
   mount /dev/nvme0n1p2 /mnt
   btrfs subvolume create /mnt/nixos
   umount /mnt

   # Mount for install
   mount -o subvol=nixos /dev/nvme0n1p2 /mnt
   mkdir -p /mnt/boot
   mount /dev/nvme0n1p1 /mnt/boot
   ```

3. Install NixOS:
   ```bash
   nixos-install --flake github:ijohanne/dotfiles-ng#goose
   ```

4. Reboot and verify network connectivity. After boot, subsequent updates use:
   ```bash
   deploy-goose
   ```

   `deploy-goose` intentionally runs `git add -A` first when it finds a local checkout to
   rebuild from. Pass `--no-local` to skip the local-checkout path and deploy from GitHub.

### Pakhet (Application Server)

Pakhet is a bhyve VM running on fatty (FreeBSD host). It uses GRUB with a simple ext4 root on `/dev/sda`.

#### Prerequisites

- Create a bhyve VM on fatty with a virtual disk and network interface
- Boot a NixOS installer ISO in the VM

#### Installation

1. Boot the NixOS installer in the bhyve VM

2. Partition the disk manually (pakhet does not use disko):
   ```bash
   parted /dev/sda -- mklabel msdos
   parted /dev/sda -- mkpart primary ext4 1MiB 100%

   mkfs.ext4 /dev/sda1
   mount /dev/sda1 /mnt
   ```

3. Install NixOS:
   ```bash
   nixos-install --flake github:ijohanne/dotfiles-ng#pakhet
   ```

4. Reboot. After boot, subsequent updates use:
   ```bash
   deploy-pakhet
   ```

   `deploy-pakhet` intentionally runs `git add -A` first when it finds a local checkout to
   rebuild from. Pass `--no-local` to skip the local-checkout path and deploy from GitHub.

### bhyve VM Images

Pre-built raw disk images for FreeBSD bhyve virtual machines. Two variants are available:

- **bhyve** — Minimal base image (vim, htop, git, SSH with authorized keys for root)
- **bhyve-server** — Full server image with ij + mj users, home-manager configs, fish/zsh, dev tools, sops-nix

Both images use GPT with a BIOS boot partition and ext4 root. The root partition and filesystem automatically expand to fill the virtual disk on first boot.

#### Building the Images

```bash
# Minimal base image
nix build .#images.bhyve

# Server image with users and home-manager
nix build .#images.bhyve-server
```

The output is a raw disk image at `result/main.raw`.

#### Creating a bhyve VM

On the FreeBSD host (fatty):

1. Copy the image and create the VM disk:
   ```bash
   # Create a ZFS volume for the VM (adjust size as needed)
   zfs create -V 20G zroot/vms/my-vm

   # Write the image to the volume
   dd if=main.raw of=/dev/zvol/zroot/vms/my-vm bs=1M

   # Or copy the raw image directly if using file-backed storage
   cp main.raw /vms/my-vm.img
   truncate -s 20G /vms/my-vm.img
   ```

2. Create a `vm-bhyve` configuration (e.g., `/vms/my-vm/my-vm.conf`):
   ```
   loader="grub"
   cpu=2
   memory=2G
   disk0_type="virtio-blk"
   disk0_name="disk0"
   network0_type="virtio-net"
   network0_switch="public"
   grub_run_partition="gpt2"
   ```

3. Start the VM:
   ```bash
   vm start my-vm
   ```

4. SSH into the VM once it boots:
   ```bash
   ssh root@<vm-ip>
   # or (server image)
   ssh ij@<vm-ip>
   ```

#### First Boot

The root partition automatically grows to fill the disk. No manual intervention needed.

After boot, set the hostname and switch to a dedicated flake configuration:

```bash
# Set hostname
sudo hostnamectl set-hostname my-vm

# Switch to a host-specific config (if one exists in the flake)
sudo nixos-rebuild switch --flake github:ijohanne/dotfiles-ng#my-vm
```

### Raspberry Pi 4 Image

The RPi4 images are templates for bootstrapping new NixOS hosts on Raspberry Pi 4. Two variants are available:

- **rpi4-stable** — Uses nixos-25.11 (recommended for production)
- **rpi4-unstable** — Uses nixos-unstable (latest features)

#### Building the Image

```bash
# Stable (recommended)
nix build .#images.rpi4-stable

# Unstable
nix build .#images.rpi4-unstable
```

#### Writing to SD Card

```bash
sudo dd if=result/sd-image/*.img of=/dev/sdX bs=4M status=progress
```

#### First Boot

The image includes:
- SSH enabled with authorized keys from `lib/user.nix`
- Flakes enabled
- A `rebuild` alias for easy updates

After booting, you can update the system directly from this repository:

```bash
rebuild#rpi4-stable
# or
rebuild#rpi4-unstable
```

#### Creating a New Host from Template

To use this as a starting point for a new dedicated host:

1. Copy the template to a new host directory:
   ```bash
   cp -r hosts/rpi4-image/stable hosts/my-new-rpi
   ```

2. Edit `hosts/my-new-rpi/configuration.nix`:
   ```nix
   networking.hostName = lib.mkForce "my-new-rpi";
   ```

3. Add the new host to `flake.nix`:
   ```nix
   nixosConfigurations = {
     my-new-rpi = nixpkgs-stable.lib.nixosSystem {
       system = "aarch64-linux";
       specialArgs = { inherit inputs self user; };
       modules = [
         ./hosts/my-new-rpi/configuration.nix
       ];
     };
   };
   ```

4. Customize the configuration as needed (add packages, services, etc.)

5. After first boot, switch to the new configuration:
   ```bash
   sudo nixos-rebuild switch --flake github:ijohanne/dotfiles-ng#my-new-rpi
   ```

### RTSP Dev VM

A QEMU virtual machine for developing and debugging the `nf_conntrack_rtsp` / `nf_nat_rtsp` kernel modules. Runs natively on Apple Silicon (aarch64-linux) — no emulation overhead.

The RTSP conntrack helper is used on goose to handle Movistar IPTV VOD (Video on Demand) traffic. Live channels use multicast via igmpproxy, but VOD is unicast — the STB (`10.255.101.201` on the wired VLAN) communicates via RTSP (port 554) to set up on-demand streams. The conntrack helper parses RTSP SETUP requests and creates expectations for the dynamically negotiated RTP/RTCP ports, allowing NAT to work correctly for the media streams. The out-of-tree kernel module (`modules/community/packages/rtsp-linux/default.nix`) is old and may need fixes for newer kernels — this VM provides a safe environment to iterate.

#### Building and Running

```bash
nix build .#images.rtsp-dev-vm
result/bin/run-rtsp-dev-vm
```

The VM starts with QEMU and includes:
- Latest Linux kernel with `nf_conntrack_rtsp` and `nf_nat_rtsp` loaded
- nftables with a basic NAT + RTSP conntrack helper ruleset
- `conntrack-tools`, `tcpreplay`, `tcpdump`, `wireshark-cli` (tshark)
- Kernel dev headers for in-VM module rebuilds
- `net.netfilter.nf_conntrack_helper = 1` and IP forwarding enabled

SSH into the VM once booted (QEMU forwards port 2222 by default):

```bash
ssh -p 2222 ij@localhost
```

#### Capturing RTSP Traffic on Goose

The Movistar STB uses RTSP on port 554 for VOD playback. Traffic flows through the `wan` VLAN (253) and gets DNATed to the STB on the `wired` VLAN (101).

To capture a full VOD session with associated RTP streams:

```bash
# On goose — capture all STB traffic (RTSP control + RTP media)
sudo tcpdump -i wired -w /tmp/rtsp-capture.pcap \
  host 10.255.101.201 and '(port 554 or udp portrange 1024-65535)'

# Or capture just RTSP control traffic
sudo tcpdump -i wired -w /tmp/rtsp-control.pcap \
  host 10.255.101.201 and port 554

# Monitor conntrack expectations in real-time while capturing
sudo conntrack -E expect
```

Start a VOD playback on the STB to generate RTSP SETUP/PLAY/TEARDOWN traffic, then stop the capture.

#### Replaying in the VM

1. Copy the pcap to the VM:
   ```bash
   scp -P 2222 /tmp/rtsp-capture.pcap ij@localhost:/tmp/
   ```

2. In the VM, inspect the capture:
   ```bash
   # View RTSP sessions
   tshark -r /tmp/rtsp-capture.pcap -Y rtsp

   # View conntrack helper assignments
   tshark -r /tmp/rtsp-capture.pcap -Y 'tcp.port == 554' -V | grep -A5 SETUP
   ```

3. Replay through the network stack:
   ```bash
   # Replay at original speed
   sudo tcpreplay -i eth0 /tmp/rtsp-capture.pcap

   # Replay slower for debugging
   sudo tcpreplay -i eth0 --multiplier=0.5 /tmp/rtsp-capture.pcap
   ```

4. Monitor conntrack state during replay:
   ```bash
   # Watch expectations being created
   sudo conntrack -E expect

   # List all tracked connections
   sudo conntrack -L

   # Filter for RTSP-related entries
   sudo conntrack -L -p tcp --dport 554
   ```

#### Iterating on the Kernel Module

The RTSP module source is from [maru-sama/rtsp-linux](https://github.com/maru-sama/rtsp-linux) with patches in `modules/community/packages/rtsp-linux/rtsp-linux.patch`. To iterate:

1. Clone the source in the VM:
   ```bash
   git clone https://github.com/maru-sama/rtsp-linux.git
   cd rtsp-linux
   ```

2. Make changes, build against the running kernel:
   ```bash
   make -C /run/booted-system/kernel-modules/lib/modules/$(uname -r)/build M=$(pwd) modules
   ```

3. Reload the modules:
   ```bash
   sudo modprobe -r nf_nat_rtsp nf_conntrack_rtsp
   sudo insmod ./nf_conntrack_rtsp.ko
   sudo insmod ./nf_nat_rtsp.ko
   ```

4. Replay traffic and verify behavior.

## Setup Template Generator

Scaffold new host and user configurations that match the flake architecture.

```bash
# Interactive wizard
nix run .#setup-template -- new

# From a config file
nix run .#setup-template -- generate --config setup.json

# Preview without writing files
nix run .#setup-template -- new --dry-run
```

The generator produces `modules/private/inventory/users.nix`, `hosts/<name>/configuration.nix`, `hosts/<name>/home.nix`, and a ready-to-paste `flake.nix` snippet. See [docs/setup-template-usage.md](docs/setup-template-usage.md) for full details.

## Reference

### Terminal Tools

#### Zoxide — Smart cd

Intelligent directory jumping that learns your most frequently used directories.

```bash
z project-name        # Jump to directory
zoxide query          # Show frecent directories
cd ~/code             # Also works with regular cd (aliased via --cmd cd)
```

#### Lazygit — Git TUI

Feature-rich git terminal UI with Catppuccin Mocha theme.

```bash
lazygit              # Open git TUI
```

**Keybindings:**
- `p` - push
- `P` - pull
- `c` - commit
- `r` - rebase
- `m` - merge

#### Delta — Git Diff Viewer

Syntax-highlighting pager for git diffs.

```bash
git diff             # Automatic when configured as git pager
git log -p           # View diffs in log
```

#### Tealdeer — Quick Command Help

Community-driven command cheatsheets.

```bash
tldr tar             # Show tar cheatsheet
tldr --list          # List all available commands
tldr --update        # Update cache
```

#### Procs — Modern ps Replacement

Colorful process viewer with better formatting.

```bash
procs                # View all processes
procs 8080           # Search by port/PID
procs nginx          # Search by name
ps | procs           # Pipe from ps
```

#### Dog — DNS Client

Modern DNS client with JSON output and DoH/DoT support.

```bash
dog example.com              # Simple lookup
dog example.com MX           # Query MX records
dog example.com --json       # JSON output
dog --reverse 8.8.8.8        # Reverse DNS
```

#### Fish Shell Abbreviations

```bash
tldr <command>     # Quick help (tealdeer)
ps                 # Modern process viewer (procs)
dig <domain>       # DNS lookup (dog)
```

### Neovim

Configured via NixVim with Catppuccin theme. When `developer = true`, includes LSP support for Nix, Rust, Lua, and Markdown.

#### General

- **Leader:** `Space`
- `<leader>w` — Save file
- `<leader>q` — Close buffer
- `<leader>ff` — Find files (Telescope)
- `<leader>fg` — Live grep (Telescope)
- `<leader>fb` — Find buffers (Telescope)
- `<leader>gs` — Git status (Telescope)

#### LSP (developer mode)

- `gd` — Go to definition
- `gr` — Show references
- `K` — Hover documentation
- `gl` — Show diagnostic
- `[d` / `]d` — Previous/next diagnostic
- `<leader>ca` — Code action

#### Completion (developer mode)

- `<Tab>` / `<S-Tab>` — Next/previous item
- `<CR>` — Confirm selection
- `<C-Space>` — Trigger completion
- `<C-e>` — Abort completion
- `<C-b>` / `<C-f>` — Scroll docs

### Tmux

- **Prefix:** `C-a` (instead of default `C-b`)
- **Keybindings:**
  - `C-a r` — Reload config
  - `hjkl` — Navigate panes
  - `C-a =` — Split horizontal
  - `C-a -` — Split vertical
  - `C-a e/f` — Previous/next window
  - `C-a E/F` — Swap windows

### Secrets Management

Secrets are managed using [sops-nix](https://github.com/Mic92/sops-nix) with age encryption.

#### File Structure

Secrets are organized per-host for isolation:

- `secrets/macbook.yaml` — macbook-only secrets
- `secrets/pakhet.yaml` — pakhet-only secrets

Each file is encrypted with only the keys that need access, configured in `.sops.yaml`.

#### Key Locations

sops-nix tries these keys in order:
1. `/etc/ssh/ssh_host_ed25519_key` — SSH host key (preferred)
2. `/etc/ssh/ssh_host_rsa_key` — SSH host key (fallback)
3. `~/.config/sops/age/keys.txt` — Personal age key

#### Setup

1. Generate a personal age key (if not using SSH host keys):
   ```bash
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   ```

2. Get your public key:
   ```bash
   # From age key
   age-keygen -y ~/.config/sops/age/keys.txt

   # From SSH host key
   ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub
   ```

3. Add the public key to `.sops.yaml`:
   ```yaml
   keys:
     - &mykey age1...your-public-key...
   
   creation_rules:
     - path_regex: secrets/myhost\.(yaml|json|env|ini)$
       key_groups:
         - age:
             - *mykey
   ```

#### Usage

```bash
# Edit host-specific secrets
sops secrets/macbook.yaml
sops secrets/pakhet.yaml

# View decrypted secrets
sops -d secrets/macbook.yaml
```

#### Adding New Secrets

1. Edit the appropriate secrets file:
   ```bash
   sops secrets/macbook.yaml  # for macbook
   sops secrets/pakhet.yaml   # for pakhet
   ```

2. Add your secret:
   ```yaml
   my_api_key: supersecretvalue
   ```

3. Reference in nix config:
   ```nix
   # In modules/private/shared/workstation-secrets.nix (for macbook/ij-desktop)
   sops.secrets.my_api_key = {};
   
   # Or in host-specific config (for pakhet)
   sops.secrets.my_api_key = {};
   ```

4. Use the secret path in your configuration:
   ```nix
   # The decrypted secret is available at:
   # config.sops.secrets.my_api_key.path
   # Which resolves to: /run/secrets/my_api_key
   ```

#### Private Flake Access Tokens

All remote hosts have `nix_builder_access_tokens` in their sops secrets, which provides GitHub PATs for fetching private flake inputs. This is configured via `nix.extraOptions` with `!include`.

**Bootstrap problem:** A new host can't decrypt its `nix_builder_access_tokens` until it has been deployed with the sops config, but it can't build the config without the tokens. Solution: use `--build-host root@pakhet.est.unixpimps.net` for the first deploy, since pakhet already has decrypted tokens.

#### Adding a New Host

1. Get the new host's age key (from inside the devshell):
   ```bash
   ssh-to-age-remote root@<host-ip>
   ```

2. Add to `.sops.yaml`:
   ```yaml
   keys:
     - &newhost age1...public-key...
   
   creation_rules:
     - path_regex: secrets/newhost\.(yaml|json|env|ini)$
       key_groups:
         - age:
             - *ij
             - *newhost
   ```

3. Create the secrets file:
   ```bash
   sops secrets/newhost.yaml
   ```
