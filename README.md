<div align="center">

# ❄️ NixOS-WSL — Rust & Podman Dev Environment

**A declarative, reproducible NixOS configuration for WSL2 —
built for Rust development, containerised with Podman.**

[![NixOS](https://img.shields.io/badge/NixOS-flake-5277C3?logo=nixos&logoColor=white)](https://nixos.org)
[![WSL2](https://img.shields.io/badge/WSL2-ready-0078D6?logo=windows&logoColor=white)](https://learn.microsoft.com/windows/wsl/)
[![Rust](https://img.shields.io/badge/Rust-fenix-CE412B?logo=rust&logoColor=white)](https://github.com/nix-community/fenix)
[![Podman](https://img.shields.io/badge/Podman-rootless-892CA0?logo=podman&logoColor=white)](https://podman.io)

</div>

---

A complete, version-controlled development machine that you can rebuild from
scratch on any Windows box in minutes. No imperative setup, no snowflake
configs — everything is declared in Nix and reproducible from this repo.

## ✨ Highlights

- **Fully declarative** — the entire system lives in three `.nix` files.
- **Reproducible** — pinned inputs via a flake; `nixos-rebuild` gives the same
  result every time.
- **Rust-first** — fenix toolchain, `rust-analyzer`, and a curated set of
  cargo tooling, with `mold` + `sccache` wired in for fast builds.
- **Podman, not Docker** — rootless containers with a `docker` compatibility
  shim, so `docker run …` still works.
- **Batteries included** — modern terminal tooling (Starship, fzf, zoxide,
  yazi, zellij, …) configured and auto-activated via Home-Manager.

## 📁 Layout

| File | Responsibility |
|------|----------------|
| `flake.nix` | Entry point. Pins `nixpkgs`, `NixOS-WSL`, `home-manager`, `fenix`. |
| `configuration.nix` | System layer — WSL integration, Podman, user account. |
| `home.nix` | User layer (Home-Manager) — shells, prompt, Rust, all tooling. |

## 📦 What's inside

<details open>
<summary><strong>System</strong></summary>

- WSL2 integration with native systemd
- Podman with Docker-compatibility (`docker` → `podman`)
- `podman-compose`, `dive`
- Automatic store GC and image pruning

</details>

<details open>
<summary><strong>Shells &amp; terminal</strong></summary>

- **Shells:** bash, zsh, fish — all three configured
- **Prompt:** Starship (every shell)
- **Navigation:** fzf, zoxide (smart `cd`), fd, ripgrep, yazi, broot
- **Quality-of-life:** eza, bat, dust, duf, procs, btop, jq, tree, tealdeer

</details>

<details open>
<summary><strong>Rust toolchain (via fenix)</strong></summary>

| Category | Tools |
|----------|-------|
| Toolchain | `cargo`, `rustc`, `clippy`, `rustfmt`, `rust-src`, `rust-analyzer` |
| Workflow | `cargo-watch`, `cargo-nextest`, `cargo-edit`, `bacon` |
| Performance | `mold` (linker), `sccache` (cache), `cargo-flamegraph`, `hyperfine`, `cargo-expand` |
| Quality | `cargo-audit`, `cargo-deny`, `cargo-outdated` |
| Editor | Neovim + `rustaceanvim` + LSP + completion + Treesitter + Telescope |
| Workspace | `zellij`, `just`, `watchexec`, `delta` |

`mold` and `sccache` are enabled globally for noticeably faster (re)builds.

</details>

## 🚀 Getting started

### 1. Import NixOS into WSL

Grab the latest `nixos.wsl` tarball from the
[NixOS-WSL releases](https://github.com/nix-community/NixOS-WSL/releases),
then in PowerShell:

```powershell
wsl --install --from-file nixos.wsl
wsl -d NixOS
```

### 2. Apply this configuration

Clone the repo and build:

```bash
git clone <your-repo-url> nixos-config
cd nixos-config
sudo nixos-rebuild switch --flake .#ethereon
```

> [!TIP]
> Building from inside the WSL filesystem (e.g. `~/nixos-config`) is faster
> than building from a mounted Windows path, since Nix performs many small
> file operations across the filesystem bridge.

### 3. Done

Restart the instance so the configured user and shells take effect:

```powershell
wsl --shutdown
wsl -d NixOS
```

## 🔧 Daily use

```bash
# Rebuild & activate after editing any .nix file
sudo nixos-rebuild switch --flake .#ethereon

# Dry-run without making it the boot default
sudo nixos-rebuild test --flake .#ethereon

# Update pinned inputs (nixpkgs, fenix, …)
nix flake update

# Verify containers work
podman run --rm hello-world
docker run --rm hello-world   # works via the compatibility shim
```

## 🎛️ Customising

- **Personal config** — copy `local.nix.example` to `local.nix` and fill in
  your name and email. `local.nix` is gitignored and never committed.
- **Add packages** — `home.packages` in `home.nix` (user) or
  `environment.systemPackages` in `configuration.nix` (system).
- **Switch to nightly Rust** — change `stable.withComponents` to
  `complete.withComponents` in `home.nix`, or drop a `rust-toolchain.toml`
  into a project (fenix honours it).
- **Pin a stable channel** — change `nixos-unstable` to e.g. `nixos-24.11`
  in `flake.nix`.

## 📝 Notes

- The configuration name is `ethereon` (see `flake.nix`); adjust the
  `--flake .#<name>` argument if you rename it.
- Before first use, set a password for your user as root if `sudo` requires
  one: `wsl -d NixOS -u root` then `passwd <user>`.

---

<div align="center">
<sub>Built declaratively with <a href="https://nixos.org">Nix</a> ·
Container runtime by <a href="https://podman.io">Podman</a> ·
Rust toolchain by <a href="https://github.com/nix-community/fenix">fenix</a> ·
<a href="ACKNOWLEDGEMENTS.md">Acknowledgements</a> ·
<a href="LICENSE">MIT License</a></sub>
</div>
