{ config, lib, pkgs, fenix, ... }:

let
  rustAnalyzer = fenix.packages.${pkgs.stdenv.hostPlatform.system}.rust-analyzer;

  # Build neovim with plugins via pkgs.neovim directly — avoids HM plugin
  # schema breakage in nixpkgs-unstable (plugin-submodule.nix schema change).
  neovimWithPlugins = pkgs.neovim.override {
    configure = {
      customRC = "";  # lua config written via xdg.configFile below
      packages.myPlugins.start = with pkgs.vimPlugins; [
        nvim-lspconfig
        rustaceanvim
        nvim-cmp
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        luasnip
        cmp_luasnip
        (nvim-treesitter.withPlugins (p: with p; [
          rust toml nix lua yaml markdown markdown_inline bash json
        ]))
        telescope-nvim
        plenary-nvim
        tokyonight-nvim
        neo-tree-nvim
        nvim-web-devicons
        nui-nvim
        gitsigns-nvim
        lualine-nvim
        indent-blankline-nvim
        nvim-surround
        which-key-nvim
        nvim-dap
        nvim-dap-ui
        nvim-dap-virtual-text
      ];
    };
  };
in
{
  home.packages = [ neovimWithPlugins ];

  home.sessionVariables.EDITOR = "nvim";

  # vi / vim aliases
  home.shellAliases = { vi = "nvim"; vim = "nvim"; };

  # Lua config written to ~/.config/nvim/init.lua
  xdg.configFile."nvim/init.lua".text = ''
    vim.g.mapleader      = " "
    vim.g.maplocalleader = " "

    vim.opt.number         = true
    vim.opt.relativenumber = true
    vim.opt.expandtab      = true
    vim.opt.shiftwidth     = 4
    vim.opt.tabstop        = 4
    vim.opt.scrolloff      = 8
    vim.opt.signcolumn     = "yes"
    vim.opt.updatetime     = 250
    vim.opt.termguicolors  = true

    vim.g.rustaceanvim = {
      server = { cmd = { "${rustAnalyzer}/bin/rust-analyzer" } },
    }

    -- Completion
    local cmp = require('cmp')
    cmp.setup({
      snippet = { expand = function(args) require('luasnip').lsp_expand(args.body) end },
      mapping = cmp.mapping.preset.insert({
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>']      = cmp.mapping.confirm({ select = true }),
        ['<Tab>']     = cmp.mapping.select_next_item(),
        ['<S-Tab>']   = cmp.mapping.select_prev_item(),
      }),
      sources = {
        { name = 'nvim_lsp' }, { name = 'luasnip' },
        { name = 'buffer' },   { name = 'path' },
      },
    })

    require('nvim-treesitter.configs').setup({ highlight = { enable = true } })
    vim.cmd.colorscheme('tokyonight')

    -- LSP keymaps
    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(ev)
        local o = { buffer = ev.buf }
        vim.keymap.set('n', 'gd',         vim.lsp.buf.definition,     o)
        vim.keymap.set('n', 'gD',         vim.lsp.buf.declaration,    o)
        vim.keymap.set('n', 'gi',         vim.lsp.buf.implementation, o)
        vim.keymap.set('n', 'gr',         vim.lsp.buf.references,     o)
        vim.keymap.set('n', 'K',          vim.lsp.buf.hover,          o)
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action,    o)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename,         o)
        vim.keymap.set('n', '<leader>f',  vim.lsp.buf.format,         o)
        vim.keymap.set('n', '[d', function() vim.diagnostic.goto_prev() end, o)
        vim.keymap.set('n', ']d', function() vim.diagnostic.goto_next() end, o)
        vim.keymap.set('n', '<leader>d',  vim.diagnostic.open_float,  o)
      end,
    })

    -- Telescope
    local tb = require('telescope.builtin')
    vim.keymap.set('n', '<leader>ff', tb.find_files,           { desc = 'Find files' })
    vim.keymap.set('n', '<leader>fg', tb.live_grep,            { desc = 'Live grep' })
    vim.keymap.set('n', '<leader>fb', tb.buffers,              { desc = 'Buffers' })
    vim.keymap.set('n', '<leader>fh', tb.help_tags,            { desc = 'Help tags' })
    vim.keymap.set('n', '<leader>fs', tb.lsp_document_symbols, { desc = 'Symbols' })

    -- Neo-tree
    require('neo-tree').setup({
      window     = { width = 30 },
      filesystem = { follow_current_file = { enabled = true } },
    })
    vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', { desc = 'Explorer' })

    -- Gitsigns
    require('gitsigns').setup({
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local o  = { buffer = bufnr }
        vim.keymap.set('n', ']c',         gs.next_hunk,  o)
        vim.keymap.set('n', '[c',         gs.prev_hunk,  o)
        vim.keymap.set('n', '<leader>hs', gs.stage_hunk, o)
        vim.keymap.set('n', '<leader>hr', gs.reset_hunk, o)
        vim.keymap.set('n', '<leader>hb', gs.blame_line, o)
      end,
    })

    require('lualine').setup({ options = { theme = 'tokyonight' } })
    require('ibl').setup()
    require('nvim-surround').setup()
    require('which-key').setup()

    -- DAP
    local dap   = require('dap')
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
}
