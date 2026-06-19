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
      (nvim-treesitter.withPlugins (p: [
        p.rust p.toml p.nix p.lua
        p.yaml p.markdown p.markdown_inline p.bash p.json
      ]))
      # Fuzzy finder inside the editor
      telescope-nvim
      plenary-nvim
      # Theme
      tokyonight-nvim
      # File explorer
      neo-tree-nvim
      nvim-web-devicons
      nui-nvim
      # Git gutter
      gitsigns-nvim
      # Statusline
      lualine-nvim
      # Indentation guides
      indent-blankline-nvim
      # Surround text objects
      nvim-surround
      # Keymap discovery
      which-key-nvim
      # Debugging (DAP)
      nvim-dap
      nvim-dap-ui
      nvim-dap-virtual-text
    ];

    extraLuaConfig = ''
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "

      -- Base options
      vim.opt.number         = true
      vim.opt.relativenumber = true
      vim.opt.expandtab      = true
      vim.opt.shiftwidth     = 4
      vim.opt.tabstop        = 4
      vim.opt.scrolloff      = 8
      vim.opt.signcolumn     = "yes"
      vim.opt.updatetime     = 250
      vim.opt.termguicolors  = true

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

      -- Theme
      vim.cmd.colorscheme('tokyonight')

      -- LSP keymaps (set on attach)
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(ev)
          local opts = { buffer = ev.buf }
          vim.keymap.set('n', 'gd',         vim.lsp.buf.definition,      opts)
          vim.keymap.set('n', 'gD',         vim.lsp.buf.declaration,     opts)
          vim.keymap.set('n', 'gi',         vim.lsp.buf.implementation,  opts)
          vim.keymap.set('n', 'gr',         vim.lsp.buf.references,      opts)
          vim.keymap.set('n', 'K',          vim.lsp.buf.hover,           opts)
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action,     opts)
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename,          opts)
          vim.keymap.set('n', '<leader>f',  vim.lsp.buf.format,          opts)
          vim.keymap.set('n', '[d', function() vim.diagnostic.goto_prev() end, opts)
          vim.keymap.set('n', ']d', function() vim.diagnostic.goto_next() end, opts)
          vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float,    opts)
        end,
      })

      -- Telescope keymaps
      local tb = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', tb.find_files,  { desc = 'Find files' })
      vim.keymap.set('n', '<leader>fg', tb.live_grep,   { desc = 'Live grep' })
      vim.keymap.set('n', '<leader>fb', tb.buffers,     { desc = 'Buffers' })
      vim.keymap.set('n', '<leader>fh', tb.help_tags,   { desc = 'Help tags' })
      vim.keymap.set('n', '<leader>fs', tb.lsp_document_symbols, { desc = 'Symbols' })

      -- Neo-tree
      require('neo-tree').setup({
        window = { width = 30 },
        filesystem = { follow_current_file = { enabled = true } },
      })
      vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', { desc = 'Explorer' })

      -- Gitsigns
      require('gitsigns').setup({
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          local o = { buffer = bufnr }
          vim.keymap.set('n', ']c', gs.next_hunk,          o)
          vim.keymap.set('n', '[c', gs.prev_hunk,          o)
          vim.keymap.set('n', '<leader>hs', gs.stage_hunk, o)
          vim.keymap.set('n', '<leader>hr', gs.reset_hunk, o)
          vim.keymap.set('n', '<leader>hb', gs.blame_line, o)
        end,
      })

      -- Lualine
      require('lualine').setup({ options = { theme = 'tokyonight' } })

      -- Indent blankline
      require('ibl').setup()

      -- Surround
      require('nvim-surround').setup()

      -- Which-key
      require('which-key').setup()

      -- DAP (Debugging)
      local dap = require('dap')
      local dapui = require('dapui')
      require('nvim-dap-virtual-text').setup()
      dapui.setup()
      dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end
      dap.listeners.before.event_terminated['dapui_config'] = function() dapui.close() end
      vim.keymap.set('n', '<F5>',       dap.continue,          { desc = 'DAP Continue' })
      vim.keymap.set('n', '<F10>',      dap.step_over,         { desc = 'DAP Step Over' })
      vim.keymap.set('n', '<F11>',      dap.step_into,         { desc = 'DAP Step Into' })
      vim.keymap.set('n', '<F12>',      dap.step_out,          { desc = 'DAP Step Out' })
      vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'DAP Breakpoint' })
      vim.keymap.set('n', '<leader>du', dapui.toggle,          { desc = 'DAP UI toggle' })
    '';
  };

  # ─── Starship prompt (for ALL shells) ──────────────────────────────
  programs.starship = {
    enable = true;
    settings = {
      format = builtins.concatStringsSep "" [
        "[](color_orange)"
        "$os"
        "$username"
        "[](bg:color_yellow fg:color_orange)"
        "$directory"
        "[](fg:color_yellow bg:color_aqua)"
        "$git_branch"
        "$git_status"
        "[](fg:color_aqua bg:color_blue)"
        "$c"
        "$cpp"
        "$rust"
        "$golang"
        "$nodejs"
        "$bun"
        "$php"
        "$java"
        "$kotlin"
        "$haskell"
        "$python"
        "[](fg:color_blue bg:color_bg3)"
        "$docker_context"
        "$conda"
        "$pixi"
        "[](fg:color_bg3 bg:color_bg1)"
        "$time"
        "[ ](fg:color_bg1)"
        "$line_break$character"
      ];

      palette = "gruvbox_dark";

      palettes.gruvbox_dark = {
        color_fg0   = "#fbf1c7";
        color_bg1   = "#3c3836";
        color_bg3   = "#665c54";
        color_blue  = "#458588";
        color_aqua  = "#689d6a";
        color_green = "#98971a";
        color_orange = "#d65d0e";
        color_purple = "#b16286";
        color_red   = "#cc241d";
        color_yellow = "#d79921";
      };

      profiles.claude-code = "\$claude_model \$git_branch \$claude_context\$claude_cost";

      claude_model = {
        format = "[$symbol$model]($style) ";
        symbol = " ";
        style  = "bold blue";
      };

      claude_context = {
        format               = "[$gauge  $percentage]($style) ";
        gauge_full_symbol    = "▰";
        gauge_partial_symbol = "";
        gauge_empty_symbol   = "▱";
        gauge_width          = 10;
        display = [
          { threshold = 0;  hidden = false; }
          { threshold = 30; style = "bold green"; }
          { threshold = 60; style = "bold yellow"; }
          { threshold = 80; style = "bold red"; }
        ];
      };

      claude_cost = {
        format = "[$symbol$cost]($style) ";
        symbol = "";
      };

      username = {
        show_always = true;
        style_user  = "bg:color_orange fg:color_fg0";
        style_root  = "bg:color_orange fg:color_fg0";
        format      = "[ $user ]($style)";
      };

      directory = {
        style              = "fg:color_fg0 bg:color_yellow";
        format             = "[ $path ]($style)";
        truncation_length  = 3;
        truncation_symbol  = "…/";
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music"     = "󰝚 ";
          "Pictures"  = " ";
          "Developer" = "󰲋 ";
        };
      };

      git_branch = {
        symbol = "";
        style  = "bg:color_aqua";
        format = "[[ $symbol $branch ](fg:color_fg0 bg:color_aqua)]($style)";
      };

      git_status = {
        style  = "bg:color_aqua";
        format = "[[($all_status$ahead_behind )](fg:color_fg0 bg:color_aqua)]($style)";
      };

      time = {
        disabled    = false;
        time_format = "%R";
        style       = "bg:color_bg1";
        format      = "[[  $time ](fg:color_fg0 bg:color_bg1)]($style)";
      };

      line_break.disabled = false;

      character = {
        disabled                  = false;
        success_symbol            = "[](bold fg:color_green)";
        error_symbol              = "[](bold fg:color_red)";
        vimcmd_symbol             = "[](bold fg:color_green)";
        vimcmd_replace_one_symbol = "[](bold fg:color_purple)";
        vimcmd_replace_symbol     = "[](bold fg:color_purple)";
        vimcmd_visual_symbol      = "[](bold fg:color_yellow)";
      };

      os = {
        disabled = false;
        style    = "bg:color_orange fg:color_fg0";
        symbols = {
          Windows          = "󰍲";
          Ubuntu           = "󰕈";
          SUSE             = "";
          Raspbian         = "󰐿";
          Mint             = "󰣭";
          Macos            = "󰀵";
          Manjaro          = "";
          Linux            = "󰌽";
          Gentoo           = "󰣨";
          Fedora           = "󰣛";
          Alpine           = "";
          Amazon           = "";
          Android          = "";
          Arch             = "󰣇";
          Debian           = "󰣚";
          Redhat           = "󱄛";
          RedHatEnterprise = "󱄛";
          Pop              = "";
        };
      };

      nodejs  = { symbol = ""; style = "bg:color_blue"; format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)"; };
      bun     = { symbol = ""; style = "bg:color_blue"; format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)"; };
      c       = { symbol = " "; style = "bg:color_blue"; format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)"; };
      cpp     = { symbol = " "; style = "bg:color_blue"; format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)"; };
      rust    = { symbol = ""; style = "bg:color_blue"; format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)"; };
      golang  = { symbol = ""; style = "bg:color_blue"; format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)"; };
      php     = { symbol = ""; style = "bg:color_blue"; format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)"; };
      java    = { symbol = ""; style = "bg:color_blue"; format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)"; };
      kotlin  = { symbol = ""; style = "bg:color_blue"; format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)"; };
      haskell = { symbol = ""; style = "bg:color_blue"; format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)"; };
      python  = { symbol = ""; style = "bg:color_blue"; format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)"; };

      docker_context = { symbol = ""; style = "bg:color_bg3"; format = "[[ $symbol( $context) ](fg:#83a598 bg:color_bg3)]($style)"; };
      conda          = { style  = "bg:color_bg3"; format = "[[ $symbol( $environment) ](fg:#83a598 bg:color_bg3)]($style)"; };
      pixi           = { style  = "bg:color_bg3"; format = "[[ $symbol( $version)( $environment) ](fg:color_fg0 bg:color_bg3)]($style)"; };
    };
  };

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
