# Neovim — declarative port of github.com/dkopka/neovim-config
#
# Packer is GONE: every plugin below is a Nix store path, pinned by flake.lock.
# No bootstrap clone, no :PackerSync, no ~/.local/share/nvim state to drift.
# The Lua is carried over verbatim except where noted (see "Deviations" at the
# bottom of this file).
#
# Layout reproduced in the store, added to 'runtimepath':
#   lua/{opts,keys,filetype,plug,autocommands}.lua
#   after/plugin/00-init.lua   ← sources the lua/ modules once plugins are loaded
#   after/plugin/*.lua         ← per-plugin setup, same filenames as the repo
{ config, lib, pkgs, ... }:

let
  ##########################################################################
  # lua/ — core settings, sourced by after/plugin/00-init.lua
  ##########################################################################
  optsLua = ''
    local opt = vim.opt
    -- [[ Context ]]
    opt.colorcolumn = '0'            -- str:  Show col for max line length
    opt.number = true                -- bool: Show line numbers
    opt.relativenumber = false       -- bool: Show relative line numbers
    opt.tabstop = 4
    opt.scrolloff = 4                -- int:  Min num lines of context
    opt.shiftwidth = 4
    opt.signcolumn = "yes"           -- str:  Show the sign column
    opt.wrap = false                 -- bool: Disable line wrapping
    opt.mouse = ""                   -- str:  Disable mouse integration
    opt.foldmethod = "indent"
    opt.foldenable = false
    opt.foldlevel = 2

    -- [[ Filetypes ]]
    opt.encoding = 'utf8'
    opt.fileencoding = 'utf8'

    -- [[ Theme ]]
    opt.syntax = "ON"
    opt.termguicolors = true
    opt.background = "dark"

    -- [[ Search ]]
    opt.ignorecase = true
    opt.smartcase = true
    opt.incsearch = true
    opt.hlsearch = true

    -- [[ Whitespace ]]
    opt.expandtab = true
    opt.shiftwidth = 4
    opt.softtabstop = 4
    opt.tabstop = 4

    -- [[ Splits ]]
    opt.splitright = true
    opt.splitbelow = true

    -- Completion experience (:help completeopt)
    opt.completeopt = { 'menuone', 'noselect', 'noinsert' }
    opt.shortmess = opt.shortmess + { c = true }
    opt.updatetime = 300             -- was nvim_set_option(), deprecated

    -- Fixed diagnostics column + autodiagnostic popup on CursorHold
    vim.cmd([[
    set signcolumn=yes
    autocmd CursorHold * lua vim.diagnostic.open_float(nil, { focusable = false })
    ]])

    -- Neovim 0.11 made the virtual_text diagnostic handler opt-in; without
    -- this, errors show only as a gutter sign plus an underline and the
    -- message appears solely in the CursorHold float. Restores the inline
    -- end-of-line message the pre-0.11 setup had.
    vim.diagnostic.config({
      virtual_text = true,
      underline = true,
      signs = true,
      severity_sort = true,   -- errors win over warnings on the same line
    })

    -- Vimspector options
    vim.cmd([[
    let g:vimspector_sidebar_width = 85
    let g:vimspector_bottombar_height = 15
    let g:vimspector_terminal_maxwidth = 70
    ]])
  '';

  keysLua = ''
    vim.g.mapleader = ","
    vim.g.localleader = "\\"
    -- move around splits within neovim
    vim.keymap.set('n', '<C-h>', ':wincmd h<CR>', {})
    vim.keymap.set('n', '<C-j>', ':wincmd j<CR>', {})
    vim.keymap.set('n', '<C-k>', ':wincmd k<CR>', {})
    vim.keymap.set('n', '<C-l>', ':wincmd l<CR>', {})

    -- [[ telescope ]] --
    local tb = require('telescope.builtin')
    vim.keymap.set('n', '<leader>ff', tb.find_files, {})
    vim.keymap.set('n', '<leader>fg', tb.live_grep, {})
    vim.keymap.set('n', '<leader>fs', tb.grep_string, {})
    vim.keymap.set('n', '<leader>fb', tb.buffers, {})
    vim.keymap.set('n', '<leader>fh', tb.help_tags, {})
    vim.keymap.set('n', '<leader>g', tb.current_buffer_fuzzy_find, {})
    vim.keymap.set('n', '<leader>fF', function()
        tb.find_files({
            no_ignore = true,
            hidden = true,
        })
    end, {})
    vim.keymap.set('n', '<leader>fG', function()
        tb.live_grep({
            additional_args = function()
                return { '--no-ignore' }
            end,
        })
    end, {})

    -- [[ NvimTree ]] --
    vim.keymap.set('n', '<C-b>', vim.cmd.NvimTreeToggle, {})
    -- [[ mbbill/undotree ]] --
    vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle, {})

    local opts = { noremap = true, silent = true }

    vim.keymap.set('n', '<C-x>',  '<Cmd>q<CR>', opts)
    -- [[ tab-page ]] --
    vim.keymap.set('n', '<C-t>',  '<Cmd>tabnew<CR>', opts)

    -- [[ lsp ]] --
    vim.keymap.set('n', 'K',  vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
    vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
    vim.keymap.set('n', '<leader>d',  vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<leader>e',  vim.diagnostic.open_float, opts)
    vim.keymap.set('n', '<leader>q',  vim.diagnostic.setloclist, opts)
    vim.keymap.set('n', '<leader>f',  vim.lsp.buf.format, opts)
    vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set('n', '<leader>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)

    -- [[ ibl - indent-blankline ]] --
    vim.keymap.set('n', '<leader>i', '<cmd>IBLToggle<cr>', opts)
    -- [[ builtin visuals ]] --
    vim.keymap.set('n', '<leader>n', '<cmd>set invnumber<cr>', opts)

    -- [[ git ]] --
    vim.keymap.set('n', '<Tab><Tab>s', function() vim.cmd('Git show ' .. vim.fn.expand('<cword>')) end, opts)
    vim.keymap.set('n', '<Tab><Tab>l', function() vim.cmd('Git log ' .. vim.fn.expand('<cword>')) end, opts)
    vim.keymap.set('n', '<Tab><Tab>b', '<cmd>Git blame<CR>', opts)
    -- the below is actually also handled by <leader>hs
    vim.keymap.set('n', '<leader>gs', '<cmd>GitGutterStageHunk<CR>', opts)
    vim.keymap.set('n', '<leader>gu', function() vim.cmd('!git restore --staged %') end, opts)
    vim.keymap.set('n', '<leader>gr', function() vim.cmd('!git restore %') end, opts)
    vim.keymap.set('n', '<leader>gc', function() vim.cmd('GitGutterLineHighlightsToggle') end, opts)
  '';

  filetypeLua = ''
    vim.filetype.add({
      extension = {
        ovsschema = "xml",
      },
    })
  '';

  plugLua = ''
    require('telescope').setup{}
    -- ensure_installed dropped: grammars come from Nix (withPlugins below)
    require('nvim-treesitter.configs').setup {
        highlight = { enable = false },
    }
  '';

  autocommandsLua = ''
    vim.api.nvim_create_autocmd({ "BufWritePre" }, {
      pattern = { "*" },
      command = [[%s/\s\+$//e]],
    })
  '';

  ##########################################################################
  # after/plugin/ — sourced after all start plugins are on 'runtimepath'
  ##########################################################################
  initAfter = ''
    -- Replaces the tail of the upstream init.lua. Lives in after/plugin so
    -- that require('telescope.builtin') in keys.lua resolves: start plugins
    -- are only added to 'runtimepath' after the user config is sourced.
    require('opts')
    require('keys')
    require('filetype')
    require('plug')
    require('autocommands')
  '';

  cmpLua = ''
    -- Completion Plugin Setup
    local cmp = require'cmp'
    cmp.setup({
      -- Enable LSP snippets
      snippet = {
        expand = function(args)
            vim.fn["vsnip#anonymous"](args.body)
        end,
      },
      mapping = {
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-n>'] = cmp.mapping.select_next_item(),
        -- Add tab support
        ['<S-Tab>'] = cmp.mapping.select_prev_item(),
        ['<Tab>'] = cmp.mapping.select_next_item(),
        ['<C-S-f>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.close(),
        ['<CR>'] = cmp.mapping.confirm({
          behavior = cmp.ConfirmBehavior.Insert,
          select = true,
        })
      },
      -- Installed sources:
      sources = {
        { name = 'path' },                              -- file paths
        { name = 'nvim_lsp', keyword_length = 3 },      -- from language server
        { name = 'nvim_lsp_signature_help'},            -- function signatures
        { name = 'nvim_lua', keyword_length = 2},       -- neovim Lua runtime API
        { name = 'buffer', keyword_length = 2 },        -- current buffer
        { name = 'vsnip', keyword_length = 2 },         -- vim-vsnip source
        { name = 'calc'},                               -- inert: see cmp-calc note in the plugin list
      },
      window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
      },
      formatting = {
          fields = {'menu', 'abbr', 'kind'},
          format = function(entry, item)
              local menu_icon ={
                  nvim_lsp = 'λ',
                  vsnip = '⋗',
                  buffer = 'Ω',
                  path = '🖫',
              }
              item.menu = menu_icon[entry.source.name]
              return item
          end,
      },
    })
  '';

  deviconsLua = ''
    require('nvim-web-devicons').setup {
        default = true;
    }
  '';

  floatermLua = ''
    -- FloaTerm configuration
    vim.keymap.set('n', "<leader>ft", ":FloatermNew --name=myfloat --height=0.8 --width=0.7 --autoclose=2 fish <CR> ", {})
    vim.keymap.set('n', "t", ":FloatermToggle myfloat<CR>", {})
    vim.keymap.set('t', "<Esc>", "<C-\\><C-n>:q<CR>", {})
  '';

  iblLua = ''
    -- https://github.com/lukas-reineke/indent-blankline.nvim
    local highlight = {
        "RainbowRed",
        "RainbowYellow",
        "RainbowBlue",
        "RainbowOrange",
        "RainbowGreen",
        "RainbowViolet",
        "RainbowCyan",
    }

    local hooks = require "ibl.hooks"
    -- create the highlight groups in the highlight setup hook, so they are reset
    -- every time the colorscheme changes
    hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
        vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
        vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
        vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
        vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
        vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
        vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
    end)

    require("ibl").setup { indent = { highlight = highlight } }
  '';

  lualineLua = ''
    require('lualine').setup {
        options = {
            theme = 'gruvbox',
            -- upstream used two adjacent single quotes; "" is identical in Lua
            -- and avoids clashing with the Nix indented-string terminator.
            section_separators = {"", ""},
            component_separators = {"", ""},
            icons_enabled = true,
            globalstatus = false,
        },
        sections = {
            lualine_a = {'mode'},
            lualine_b = {'branch'},
            lualine_c = {'filename'},
            lualine_x = {'encoding', 'fileformat', 'filetype'},
            lualine_y = {'progress'},
            lualine_z = {'location'}
        },
        inactive_sections = {
            lualine_a = {},
            lualine_b = {},
            lualine_c = {'filename'},
            lualine_x = {'location'},
            lualine_y = {},
            lualine_z = {}
        },
        tabline = {},
        extensions = {},
    }
  '';

  # Upstream after/plugin/mason.lua, minus Mason. The original already
  # detected NixOS via /etc/os-release and skipped Mason on it — on NixOS
  # Mason's downloaded binaries can't run anyway. Servers come from
  # environment.systemPackages below.
  lspLua = ''
    -- No require('lspconfig'): that framework is deprecated in Neovim 0.11
    -- (removed in nvim-lspconfig 3.0). The nvim-lspconfig plugin is still
    -- installed — it now ships per-server defaults under lsp/ that
    -- vim.lsp.config picks up automatically; we only add overrides.

    -- Keybindings for LSP features (buffer-local, on attach)
    local on_attach_fn = function(client, bufnr)
        local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end

        vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'

        local opts = { noremap = true, silent = true }

        -- See `:help vim.lsp.*` for documentation on any of the below functions
        buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
        buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
        buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
        buf_set_keymap('n', 'gi', '<Cmd>lua vim.lsp.buf.implementation()<CR>', opts)
        buf_set_keymap('n', '<C-k>', '<Cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
        buf_set_keymap('n', '<leader>wa', '<Cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
        buf_set_keymap('n', '<leader>wr', '<Cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
        buf_set_keymap('n', '<leader>wl', '<Cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
        buf_set_keymap('n', '<leader>D', '<Cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
        buf_set_keymap('n', '<leader>rn', '<Cmd>lua vim.lsp.buf.rename()<CR>', opts)
        buf_set_keymap('n', 'gr', '<Cmd>lua vim.lsp.buf.references()<CR>', opts)
        buf_set_keymap('n', '<leader>e', '<Cmd>lua vim.diagnostic.open_float()<CR>', opts)
        buf_set_keymap('n', '[d', '<Cmd>lua vim.diagnostic.jump({ count = -1, float = true })<CR>', opts)
        buf_set_keymap('n', ']d', '<Cmd>lua vim.diagnostic.jump({ count = 1, float = true })<CR>', opts)
        buf_set_keymap('n', '<leader>q', '<Cmd>lua vim.diagnostic.setloclist()<CR>', opts)
        buf_set_keymap('n', '<leader>f', '<Cmd>lua vim.lsp.buf.format()<CR>', opts)
    end

    -- rust-analyzer is NOT set up here: rustaceanvim owns it (see rust.lua).
    -- Registering it twice would start two servers per Rust buffer.

    -- Configure clangd (root_dir/root_pattern -> root_markers in the new API)
    vim.lsp.config('clangd', {
        on_attach = on_attach_fn,
        flags = {
            debounce_text_changes = 150,
        },
        filetypes = { "c", "cpp", "objc", "objcpp", "h", "hpp" },
        root_markers = { "compile_commands.json", "compile_flags.txt", ".git" },
        settings = {
            clangd = {
                fallbackFlags = { "-std=c11" }
            }
        }
    })
    vim.lsp.enable('clangd')
  '';

  nvimtreeLua = ''
    require("nvim-tree").setup({
      sort = {
        sorter = "case_sensitive",
      },
      view = {
        width = 44,
      },
      renderer = {
        group_empty = true,
      },
      filters = {
        dotfiles = true,
      },
    })
  '';

  # Was after/plugin/rust-tools.lua. rust-tools.nvim is abandoned upstream and
  # nixpkgs now ships it only as an alias (which the neovim plugin submodule
  # refuses), so this is the rustaceanvim equivalent. Same two keymaps.
  #
  # rustaceanvim configures rust-analyzer itself and must NOT be paired with
  # lspconfig.rust_analyzer.setup — hence its removal from lsp.lua.
  rustLua = ''
    vim.g.rustaceanvim = {
      server = {
        default_settings = {
          ["rust-analyzer"] = {
            cargo = {
              allFeatures = true,
            },
            procMacro = {
              enable = true,
            },
            -- Run clippy instead of plain `cargo check` on save: same latency,
            -- strictly more lints. The clippy binary comes from modules/rust.nix.
            check = {
              command = "clippy",
              extraArgs = { "--all-targets" },
            },
            -- Don't index build output or direnv caches.
            files = {
              excludeDirs = { ".direnv", ".git", "target" },
            },
          },
        },
        on_attach = function(_, bufnr)
          local bufopts = { buffer = bufnr, silent = true }

          -- Hover actions (was rt.hover_actions.hover_actions)
          vim.keymap.set("n", "<C-space>", function()
            vim.cmd.RustLsp({ 'hover', 'actions' })
          end, bufopts)
          -- Code action groups (was rt.code_action_group.code_action_group)
          vim.keymap.set("n", "<Leader>a", function()
            vim.cmd.RustLsp('codeAction')
          end, bufopts)

          -- Rust-specific, all under <leader>r. <leader>rn stays LSP rename
          -- (set globally in keys.lua) — not shadowed here.
          vim.keymap.set("n", "<leader>rr", function()
            vim.cmd.RustLsp('runnables')      -- pick a bin/test/example to run
          end, bufopts)
          vim.keymap.set("n", "<leader>rt", function()
            vim.cmd.RustLsp('testables')      -- run the test under the cursor
          end, bufopts)
          vim.keymap.set("n", "<leader>rm", function()
            vim.cmd.RustLsp('expandMacro')    -- expand macro recursively
          end, bufopts)
          vim.keymap.set("n", "<leader>rc", function()
            vim.cmd.RustLsp('openCargo')      -- jump to Cargo.toml
          end, bufopts)
          vim.keymap.set("n", "<leader>rp", function()
            vim.cmd.RustLsp('parentModule')
          end, bufopts)

          -- Inlay hints (types, parameter names) off by default, toggled —
          -- always-on hints shift text around while you type.
          vim.keymap.set("n", "<leader>rh", function()
            vim.lsp.inlay_hint.enable(
              not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }),
              { bufnr = bufnr }
            )
          end, bufopts)
        end,
      },
    }

    -- Cargo.toml / *.toml: taplo LSP (schema-aware completion for crate
    -- fields, plus formatting). nvim-lspconfig ships the defaults; the binary
    -- comes from modules/rust.nix, so enabling it is all that's needed.
    vim.lsp.enable('taplo')
  '';

  themeLua = ''
    vim.cmd 'colorscheme gruvbox'
  '';

  treesitterLua = ''
    -- Override or extend Treesitter settings
    require'nvim-treesitter.configs'.setup {
        incremental_selection = {
            enable = true,
            keymaps = {
                init_selection = "gnn",
                node_incremental = "grn",
                scope_incremental = "grc",
                node_decremental = "grm",
            },
        },
    }
  '';

  whichkeyLua = ''
    local status_ok, which_key = pcall(require, "which-key")
    if not status_ok then
        return
    end

    local setup = {
        plugins = {
            marks = true,     -- shows a list of your marks on ' and `
            registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
            spelling = {
                enabled = true,
                suggestions = 20,
            },
            presets = {
                operators = false,
                motions = true,
                text_objects = true,
                windows = true,
                nav = true,
                z = true,
                g = true,
            },
        },
        replace = {
            ["<space>"] = "SPC",
            ["<cr>"] = "RET",
            ["<tab>"] = "TAB",
        },
        icons = {
            breadcrumb = "»",
            separator = "➜",
            group = "+",
        },
        keys = {
            scroll_down = "<c-d>",
            scroll_up = "<c-u>",
        },
        win = {
            border = "rounded",
            position = "bottom",
            margin = { 1, 0, 1, 0 },
            padding = { 2, 2, 2, 2 },
            winblend = 0,
        },
        layout = {
            height = { min = 4, max = 25 },
            width = { min = 20, max = 50 },
            spacing = 3,
            align = "left",
        },
        filter = function(mapping)
            return true
        end,
        show_help = true,
        triggers = {
            { "<auto>", mode = "nixsotc" },
        },
        spec = {},
    }

    local wk = require("which-key")
    wk.add({
      { "<leader>f1", hidden = true }, -- hide this keymap
      { "<leader>b", group = "buffers", expand = function()
          return require("which-key.extras").expand.buf()
        end
      },
      {
        mode = { "n", "v" },
        { "<leader>q", "<cmd>q<cr>", desc = "Quit" },
        { "<leader>w", "<cmd>w<cr>", desc = "Write" },
      }
    })

    which_key.setup(setup)
  '';

  ##########################################################################
  # Assemble the config tree in the Nix store
  ##########################################################################
  nvimConfig = pkgs.symlinkJoin {
    name = "dkopka-nvim-config";
    paths = [
      (pkgs.writeTextDir "lua/opts.lua" optsLua)
      (pkgs.writeTextDir "lua/keys.lua" keysLua)
      (pkgs.writeTextDir "lua/filetype.lua" filetypeLua)
      (pkgs.writeTextDir "lua/plug.lua" plugLua)
      (pkgs.writeTextDir "lua/autocommands.lua" autocommandsLua)

      # 00- prefix: after/plugin is sourced alphabetically, and the lua/
      # modules must run before the per-plugin files, matching upstream order.
      (pkgs.writeTextDir "after/plugin/00-init.lua" initAfter)
      (pkgs.writeTextDir "after/plugin/cmp.lua" cmpLua)
      (pkgs.writeTextDir "after/plugin/devicons.lua" deviconsLua)
      (pkgs.writeTextDir "after/plugin/floaterm.lua" floatermLua)
      (pkgs.writeTextDir "after/plugin/ibl.lua" iblLua)
      (pkgs.writeTextDir "after/plugin/lsp.lua" lspLua)
      (pkgs.writeTextDir "after/plugin/lualine.lua" lualineLua)
      (pkgs.writeTextDir "after/plugin/nvimtree.lua" nvimtreeLua)
      (pkgs.writeTextDir "after/plugin/rust.lua" rustLua)
      (pkgs.writeTextDir "after/plugin/theme.lua" themeLua)
      (pkgs.writeTextDir "after/plugin/treesitter.lua" treesitterLua)
      (pkgs.writeTextDir "after/plugin/whichkey.lua" whichkeyLua)
    ];
  };
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    configure = {
      customRC = ''
        " Put the store-resident config tree on the runtimepath. The 'after'
        " entry must be appended separately — Neovim only derives it
        " automatically for the real ~/.config/nvim.
        set runtimepath^=${nvimConfig}
        set runtimepath+=${nvimConfig}/after
      '';

      packages.myPlugins = with pkgs.vimPlugins; {
        start = [
          # Grammars are built by Nix; nvim-treesitter never downloads at runtime.
          #
          # -legacy, NOT plain nvim-treesitter: as of 26.05 the latter is the
          # rewritten `main` branch, which dropped the `nvim-treesitter.configs`
          # module (and incremental_selection with it). plug.lua and
          # treesitter.lua both use configs.setup, so the classic plugin is the
          # one that matches this config. Same grammar API.
          (nvim-treesitter-legacy.withPlugins (p: [ p.rust p.lua p.python p.toml ]))

          vim-fugitive
          undotree
          nvim-lspconfig

          telescope-nvim
          plenary-nvim          # telescope dependency, explicit upstream

          # Rust
          rust-vim
          rustaceanvim          # successor to the abandoned rust-tools.nvim

          # Completion
          nvim-cmp
          cmp-nvim-lsp
          cmp-nvim-lua
          cmp-nvim-lsp-signature-help
          cmp-vsnip
          cmp-path
          cmp-buffer
          vim-vsnip
          # cmp-calc deliberately absent: nixpkgs marks it meta.license = unfree
          # (the upstream repo ships no LICENSE file, so the generator defaults
          # to unfree). cmp.lua's 'calc' source entry is therefore inert —
          # exactly as it was under Packer, which never installed it either.

          vim-floaterm
          nvim-tree-lua

          # Aesthetics
          lualine-nvim
          nvim-web-devicons
          gruvbox-community

          vim-gitgutter         # git diff signs
          vim-tmux-navigator    # <C-hjkl> across tmux panes

          trouble-nvim
          which-key-nvim
          mini-icons            # icons for which-key
          indent-blankline-nvim
        ];
        opt = [ ];
      };
    };
  };

  # Runtime dependencies the config shells out to. The NixOS programs.neovim
  # module has no `extraPackages` (that option is home-manager's), so these go
  # on the system PATH — where clangd and rust-analyzer are useful anyway.
  environment.systemPackages = with pkgs; [
    ripgrep      # telescope live_grep / grep_string
    fd           # telescope find_files
    fish         # <leader>ft opens floaterm running fish
    rust-analyzer
    clang-tools  # clangd
  ];

  ##########################################################################
  # Deviations from github.com/dkopka/neovim-config — all deliberate
  ##########################################################################
  # 1. Packer removed entirely (plugins are Nix inputs). ':PackerSync' is gone;
  #    to add a plugin, edit the `start` list and `nixos-rebuild switch`.
  # 2. Mason / mason-lspconfig / mason-tool-installer dropped. The upstream
  #    config already branched on ID=nixos and skipped them; servers now come
  #    from environment.systemPackages.
  # 3. Removed APIs updated for the Neovim in 26.05:
  #      vim.lsp.diagnostic.show_line_diagnostics -> vim.diagnostic.open_float
  #      vim.lsp.diagnostic.set_loclist           -> vim.diagnostic.setloclist
  #      vim.lsp.buf.formatting                   -> vim.lsp.buf.format
  #      vim.diagnostic.goto_prev/next            -> vim.diagnostic.jump
  #      nvim_set_option / nvim_buf_set_option    -> vim.opt / vim.bo
  #      require('lspconfig').<srv>.setup{}       -> vim.lsp.config + vim.lsp.enable
  #      lspconfig.util.root_pattern              -> root_markers
  # 3b. nvim-treesitter -> nvim-treesitter-legacy. In 26.05 the plain attribute
  #    became the rewritten `main` branch, which has no nvim-treesitter.configs
  #    module and no incremental_selection; the legacy attribute is the classic
  #    plugin this config targets, with the identical withPlugins grammar API.
  # 3a. cmp-calc is NOT added despite cmp.lua listing the 'calc' source:
  #    nixpkgs flags it unfree (no upstream LICENSE file). To enable it you
  #    would need, in hosts/thinkpad/default.nix:
  #      nixpkgs.config.allowUnfreePredicate =
  #        p: builtins.elem (lib.getName p) [ "vimplugin-cmp-calc" ];
  # 4. after/plugin/indent-blackline.lsp was never sourced (.lsp is not a
  #    runtime extension) — dropped; ibl.lua already configures the plugin.
  # 5. after/plugin/lsp.lua was empty upstream; it now holds the former
  #    mason.lua LSP setup.
  # 6. rust-tools.nvim -> rustaceanvim. nixpkgs keeps rust-tools-nvim only as a
  #    deprecation alias, and the neovim plugin submodule rejects aliases
  #    ("Alias rust-tools-nvim is still in vim-plugins"). The upstream file also
  #    referenced an undefined `rt`, so those keymaps never worked; they are
  #    reimplemented on rustaceanvim's :RustLsp commands in after/plugin/rust.lua.
  # 7. lua/vars.lua was never required by init.lua (opts.lua supersedes it) —
  #    dropped. Note it set relativenumber = true, while opts.lua sets false;
  #    opts.lua wins, matching current behaviour.
}
