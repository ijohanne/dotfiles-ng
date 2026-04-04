# Private Modules

This directory holds internal-only dendritic modules used by this repository's own
host and user assembly.

These modules are not exported through public flake outputs. They may depend on:

- repository-private structure or host inventory
- secret wiring
- internal-only composition choices
- git inputs that are private or not intended as stable public dependencies

The repository passes this tree to internal modules through
`specialArgs.modules.private`.

It also now owns the host-specific service trees that used to live under
`hosts/*/services`.
