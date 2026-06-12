{ config, lib, pkgs, fenix, ... }:

let
  # ─── Rust toolchain via fenix ──────────────────────────────────────
  # Stable with standard components. For nightly: fenix...complete
  # or use a per-project rust-toolchain.toml instead.
  rustToolchain = fenix.packages.${pkgs.system}.stable.withComponents [
    "cargo"
    "clippy"
    "rust-src"     # required for rust-analyzer (std sources)
    "rustc"
    "rustfmt"
  ];
  rustAnalyzer = fenix.packages.${pkgs.system}.rust-analyzer;

  # Shared aliases for all three shells (defined once, used three times)
  sharedAliases = {
    ls = "eza --icons --group-directories-first";
    ll = "eza -la --icons --group-directories-first";
    cat = "bat";
    lg = "lazygit";
    gu = "gitui";
    y = "yazi";
    cw = "cargo watch -x check";
    cn = "cargo nextest run";
  };

  # ─── Local config (not versioned) ─────────────────────────────────
  # Copy local.nix.example to local.nix and fill in your values.
  local = import ./local.nix;
in
{
  # ─── Home Manager basics ───────────────────────────────────────────
  home.username = "eyu";
  home.homeDirectory = "/home/eyu";

  # Do NOT change after installation — controls HM migrations.
  home.stateVersion = "24.11";

  # Home Manager manages itself.
  programs.home-manager.enable = true;

  # ─── Packages (user-scoped) ────────────────────────────────────────
  home.packages = with pkgs; [
    # ── Rust toolchain (fenix) ──
    rustToolchain
    rustAnalyzer

    # ── Rust core ──
    cargo-watch      # rebuild on change (`cargo watch -x test`)
    cargo-edit       # `cargo add/rm/upgrade` from the CLI
    cargo-nextest    # faster, prettier test runner
    bacon            # background compiler TUI, shows errors live

    # ── Rust performance ──
    mold             # fast linker (see ~/.cargo/config.toml below)
    sccache          # compile cache, speeds up rebuilds
    cargo-flamegraph # profiling → flamegraph
    hyperfine        # CLI benchmark tool
    cargo-expand     # inspect expanded macros

    # ── Rust quality ──
    cargo-audit      # check deps against security advisories
    cargo-deny       # license / dependency policy checks
    cargo-outdated   # find outdated dependencies

    # ── Build helpers required by mold/Rust ──
    clang            # provides a C compiler/linker frontend for mold

    # ── Terminal workspace ──
    zellij           # modern terminal multiplexer (Rust)
    broot            # tree navigation + fuzzy jump
    just             # command runner (justfile) — common in Rust projects
    watchexec        # run X on file change
    tealdeer         # `tldr` — concise example man pages (Rust)

    # ── Search & navigation ──
    fd               # better `find`
    ripgrep          # better `grep` (rg)
    yazi             # fast TUI file manager (Rust)

    # ── Git TUIs ──
    gitui            # Git TUI (Rust, fast on large repos)
    tig              # lightweight Git log viewer

    # ── Pretty & useful ──
    bat              # `cat` with syntax highlighting
    eza              # modern `ls` replacement
    dust             # visual `du`
    duf              # pretty `df`
    procs            # modern `ps`
    btop             # resource monitor
    jq               # JSON in the shell
    tree
    curl
    wget
  ];

  # ─── Cargo: mold as linker + sccache as wrapper ────────────────────
  # Global config. Override per project via local .cargo/config.toml.
  home.file.".cargo/config.toml".text = ''
    [build]
    rustc-wrapper = "${pkgs.sccache}/bin/sccache"

    [target.x86_64-unknown-linux-gnu]
    linker = "${pkgs.clang}/bin/clang"
    rustflags = ["-C", "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"]
  '';

  # ─── Git ───────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    userName  = local.git.userName;
    userEmail = local.git.userEmail;
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
    # delta — syntax-highlighted diffs
    delta.enable = true;
  };

  programs.lazygit.enable = true;

  # ─── Neovim with Rust LSP ──────────────────────────────────────────
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      # LSP
      nvim-lspconfig
      # Rust-specific: better integration than plain lspconfig
      rustaceanvim
      # Completion engine + sources
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip
      cmp_luasnip
      # Treesitter (syntax / highlighting)
      (nvim-treesitter.withPlugins (p: [ p.rust p.toml p.nix p.lua ]))
      # Fuzzy finder inside the editor
      telescope-nvim
      plenary-nvim
      # Theme
      tokyonight-nvim
    ];

    extraLuaConfig = ''
      -- Make rust-analyzer path from Nix known
      vim.g.rustaceanvim = {
        server = {
          cmd = { "${rustAnalyzer}/bin/rust-analyzer" },
        },
      }

      -- Completion (nvim-cmp)
      local cmp = require('cmp')
      cmp.setup({
        snippet = {
          expand = function(args) require('luasnip').lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>']      = cmp.mapping.confirm({ select = true }),
          ['<Tab>']     = cmp.mapping.select_next_item(),
          ['<S-Tab>']   = cmp.mapping.select_prev_item(),
        }),
        sources = {
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' },
        },
      })

      -- Treesitter
      require('nvim-treesitter.configs').setup({
        highlight = { enable = true },
      })

      -- Theme and editor settings
      vim.cmd.colorscheme('tokyonight')
      vim.opt.number         = true
      vim.opt.relativenumber = true
      vim.opt.expandtab      = true
      vim.opt.shiftwidth     = 4
    '';
  };

  # ─── Starship prompt (for ALL shells) ──────────────────────────────
  programs.starship.enable = true;

  # ─── fzf — fuzzy finder ────────────────────────────────────────────
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration  = true;
    enableFishIntegration = true;
  };

  # ─── zoxide — smart `cd` ───────────────────────────────────────────
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration  = true;
    enableFishIntegration = true;
    options = [ "--cmd cd" ];
  };

  # ─── Shells — all three prepared ───────────────────────────────────
  programs.bash = {
    enable = true;
    shellAliases = sharedAliases;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = sharedAliases;
  };

  programs.fish = {
    enable = true;
    shellAliases = sharedAliases;
  };
}
