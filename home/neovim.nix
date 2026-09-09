{ pkgs, ... }:

let
  ##########################################################################
  # lua/ — core settings, required directly from programs.neovim.initLua
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
  # after/plugin/ — per-plugin setup, sourced by Neovim itself after startup
  ##########################################################################
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
        -- 'calc' deliberately absent: see Deviations note below.
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

  fidgetLua = ''
    -- LSP progress in the bottom-right corner. Added chiefly so cargo
    -- clippy's flycheck runs are VISIBLE: without it, :w kicks off a check
    -- that can take seconds (minutes on a cold target/) with zero feedback,
    -- which reads as "compile errors never show up". When the spinner
    -- finishes, the diagnostics are in.
    require('fidget').setup({})
  '';

  floatermLua = ''
    -- FloaTerm configuration
    vim.keymap.set('n', "<leader>ft", ":FloatermNew --name=myfloat --height=0.8 --width=0.7 --autoclose=2 fish <CR> ", {})
    vim.keymap.set('n', "t", ":FloatermToggle myfloat<CR>", {})

    -- Esc hides the floating terminal.
    --
    -- The upstream mapping was the typed-key chain <C-\><C-n>:q<CR>. That
    -- replays keystrokes, and under which-key's terminal-mode hook the
    -- mode-switch half ran but the ':q<CR>' tail was eaten — the float lost
    -- focus (dimmed) yet stayed on screen. <Cmd> executes the command
    -- atomically inside the mapping: nothing is replayed, nothing can
    -- intercept it.
    --
    -- Scoped to floaterm buffers (buffer-local, via FileType): in ordinary
    -- :terminal windows Esc now reaches the running program (fzf, lazygit)
    -- instead of yanking the window away — the old global :q closed those
    -- by accident.
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'floaterm',
      callback = function(ev)
        vim.keymap.set('t', '<Esc>', '<Cmd>FloatermHide<CR>',
          { buffer = ev.buf, silent = true })
      end,
    })
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

  # Upstream after/plugin/mason.lua, minus Mason (upstream already detected
  # NixOS via /etc/os-release and skipped Mason there — its downloaded
  # binaries can't run on NixOS anyway). Servers come from extraPackages below.
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
      cmd = {
        'clangd',
        '--background-index',
        '--header-insertion=never',
        '--clang-tidy=false',
        '--completion-style=detailed',
        '--pch-storage=memory',
        '-j=8',
      },
      root_markers = { 'compile_commands.json', '.clangd' },
      filetypes = { 'c', 'cpp' },
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
  # lspconfig.rust_analyzer.setup — hence its absence from lsp.lua.
  #
  # NOTE: clippy/taplo binaries and RUST_SRC_PATH are NOT provided by this
  # file — see the "rust toolchain" note in the module comment at the bottom.
  # Without them, checkOnSave below silently no-ops and `vim.lsp.enable('taplo')`
  # never attaches.
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
            check = {
              command = "clippy",
              extraArgs = { "--all-targets" },
            },
            checkOnSave = true,
            files = {
              excludeDirs = { ".direnv", ".git", "target" },
            },
          },
        },
        on_attach = function(_, bufnr)
          local bufopts = { buffer = bufnr, silent = true }

          vim.keymap.set("n", "<C-space>", function()
            vim.cmd.RustLsp({ 'hover', 'actions' })
          end, bufopts)
          vim.keymap.set("n", "<Leader>a", function()
            vim.cmd.RustLsp('codeAction')
          end, bufopts)

          vim.keymap.set("n", "<leader>rr", function()
            vim.cmd.RustLsp('runnables')
          end, bufopts)
          vim.keymap.set("n", "<leader>rt", function()
            vim.cmd.RustLsp('testables')
          end, bufopts)
          vim.keymap.set("n", "<leader>rm", function()
            vim.cmd.RustLsp('expandMacro')
          end, bufopts)
          vim.keymap.set("n", "<leader>rc", function()
            vim.cmd.RustLsp('openCargo')
          end, bufopts)
          vim.keymap.set("n", "<leader>rp", function()
            vim.cmd.RustLsp('parentModule')
          end, bufopts)

          vim.keymap.set("n", "<leader>rh", function()
            vim.lsp.inlay_hint.enable(
              not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }),
              { bufnr = bufnr }
            )
          end, bufopts)
        end,
      },
    }

    -- Cargo.toml / *.toml: taplo LSP (schema-aware completion, formatting).
    vim.lsp.enable('taplo')
  '';

  themeLua = ''
    vim.cmd 'colorscheme gruvbox'
  '';

  treesitterLua = ''
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
            marks = true,
            registers = true,
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
            -- 't' (terminal mode) deliberately absent — which-key hooking
            -- terminal mode intercepts replayed keys there, which is what
            -- broke the floaterm Esc mapping (float dimmed but never closed).
            { "<auto>", mode = "nixsoc" },
        },
        spec = {},
    }

    local wk = require("which-key")
    wk.add({
      { "<leader>f1", hidden = true },
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
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # No extraConfig/runtimepath hack needed here (unlike the NixOS-module
    # version this was ported from): home-manager writes a real
    # ~/.config/nvim/init.lua and a real ~/.local/share/nvim/site/pack/hm/
    # start/, so plugins are on 'runtimepath' before initLua's body runs —
    # verified empirically (require() on a packpath plugin succeeds at the
    # very top of init.lua). require()ing the lua/ modules below directly
    # matches upstream's own init.lua tail; no after/plugin/00-init deferral
    # is required.
    initLua = ''
      require('opts')
      require('keys')
      require('filetype')
      require('plug')
      require('autocommands')
    '';

    plugins = with pkgs.vimPlugins; [
      # Grammars are built by Nix; nvim-treesitter never downloads at runtime.
      #
      # -legacy, NOT plain nvim-treesitter: as of 26.05 the latter is the
      # rewritten `main` branch, which dropped the `nvim-treesitter.configs`
      # module (and incremental_selection with it). plug.lua and
      # treesitter.lua both use configs.setup, so the classic plugin is the
      # one that matches this config. Same grammar API.
      # NOTE: nixpkgs currently warns this alias "will become an error in
      # 26.11" — a known future migration point, not an issue on 26.05.
      (nvim-treesitter-legacy.withPlugins (p: [ p.rust p.lua p.python p.toml ]))

      vim-fugitive
      undotree
      nvim-lspconfig

      telescope-nvim
      plenary-nvim          # telescope dependency, explicit upstream

      # Rust
      rust-vim
      rustaceanvim           # successor to the abandoned rust-tools.nvim

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
      # (upstream ships no LICENSE file, so the generator defaults to
      # unfree). cmp.lua's 'calc' source entry from the original repo is
      # therefore dropped rather than carried over as dead config.

      vim-floaterm
      nvim-tree-lua

      # Aesthetics
      lualine-nvim
      nvim-web-devicons
      gruvbox-community
      fidget-nvim            # LSP progress UI — makes clippy flycheck visible

      vim-gitgutter           # git diff signs
      vim-tmux-navigator      # <C-hjkl> across tmux panes

      trouble-nvim
      which-key-nvim
      mini-icons              # icons for which-key
      indent-blankline-nvim
    ];

    # Runtime dependencies the config shells out to. home-manager's
    # programs.neovim *does* have extraPackages (unlike the plain NixOS
    # module), so these are scoped to nvim's own wrapped PATH rather than
    # the whole system's.
    extraPackages = with pkgs; [
      ripgrep      # telescope live_grep / grep_string
      fd           # telescope find_files
      fish         # <leader>ft opens floaterm running fish
      rust-analyzer
      clang-tools  # clangd
    ];
  };

  xdg.configFile = {
    "nvim/lua/opts.lua".text = optsLua;
    "nvim/lua/keys.lua".text = keysLua;
    "nvim/lua/filetype.lua".text = filetypeLua;
    "nvim/lua/plug.lua".text = plugLua;
    "nvim/lua/autocommands.lua".text = autocommandsLua;

    "nvim/after/plugin/cmp.lua".text = cmpLua;
    "nvim/after/plugin/devicons.lua".text = deviconsLua;
    "nvim/after/plugin/fidget.lua".text = fidgetLua;
    "nvim/after/plugin/floaterm.lua".text = floatermLua;
    "nvim/after/plugin/ibl.lua".text = iblLua;
    "nvim/after/plugin/lsp.lua".text = lspLua;
    "nvim/after/plugin/lualine.lua".text = lualineLua;
    "nvim/after/plugin/nvimtree.lua".text = nvimtreeLua;
    "nvim/after/plugin/rust.lua".text = rustLua;
    "nvim/after/plugin/theme.lua".text = themeLua;
    "nvim/after/plugin/treesitter.lua".text = treesitterLua;
    "nvim/after/plugin/whichkey.lua".text = whichkeyLua;
  };
}
