# rv32-nn

## Nixos part

```
nix repl -f '<nixpkgs>' -I nixpkgs=channel:nixos-unstable
```

```
nix-repl> pkgsCross 
{
  riscv32 = { ... };
  riscv32-embedded = { ... };
  riscv64 = { ... };
  riscv64-embedded = { ... };
}
```

```
nix-shell shell.nix
```
