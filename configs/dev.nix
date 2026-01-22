{ pkgs, lib, inputs, ... }:
let
  commonDevPackages = with pkgs; [
    nixd
    lua-language-server
    bat
    bottom
    dust
    eza
    fd
    fzf
    gping
    htop
    httpie
  ];

  darwinDevPackages = lib.optionals pkgs.stdenv.isDarwin [
    pkgs.rust-bin.stable.latest.default
    pkgs.rust-bin.stable.latest.rust-analyzer
  ];

  linuxDevPackages = lib.optionals pkgs.stdenv.isLinux [
    pkgs.rust-bin.stable.latest.default
    pkgs.rust-bin.stable.latest.rust-analyzer
  ];
in
{
  home.packages = commonDevPackages ++ darwinDevPackages ++ linuxDevPackages;

  programs = {
    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
    };

    fish = {
      enable = true;
      shellInit = ''
        set -p fish_function_path ${inputs.fish-eza}/functions $fish_function_path
      '';
      shellAliases = {
        du = "${pkgs.dust}/bin/dust";
        top = "${pkgs.htop}/bin/htop";
        la = "eza -la";
        lx = "eza -la --sort=size";
        llm = "eza -l --icons=always";
        tree = "eza --tree";
        lt = "eza --tree -L 2";
      };
      interactiveShellInit = ''
        ${pkgs.direnv}/bin/direnv hook fish | source
      '';
    };

    nixvim = {
      enable = true;
      defaultEditor = true;

      extraPlugins = with pkgs.vimPlugins; [
        nvim-cmp
        cmp-nvim-lsp
        cmp-nvim-lsp-signature-help
        cmp-buffer
        cmp-path
        cmp-cmdline
        cmp-vsnip
        vim-vsnip
        nvim-lspconfig
        catppuccin-nvim
        crates-nvim
        fidget-nvim
        nvim-treesitter
        nvim-treesitter-textobjects
        gitsigns-nvim
        telescope-nvim
        grug-far-nvim
        fzf-vim
        fzfWrapper
      ];

      keymaps = [
        { mode = "n"; key = "gd"; action = ":lua vim.lsp.buf.definition()<CR>"; options = { desc = "Go to definition"; }; }
        { mode = "n"; key = "gr"; action = ":lua vim.lsp.buf.references()<CR>"; options = { desc = "Show references"; }; }
        { mode = "n"; key = "K"; action = ":lua vim.lsp.buf.hover()<CR>"; options = { desc = "Show hover"; }; }
        { mode = "n"; key = "<leader>ca"; action = ":lua vim.lsp.buf.code_action()<CR>"; options = { desc = "Code action"; }; }
        { mode = "n"; key = "<leader>ff"; action = ":lua require('telescope.builtin').find_files()<CR>"; options = { desc = "Find files"; }; }
        { mode = "n"; key = "<leader>fg"; action = ":lua require('telescope.builtin').live_grep()<CR>"; options = { desc = "Live grep"; }; }
        { mode = "n"; key = "<leader>fb"; action = ":lua require('telescope.builtin').buffers()<CR>"; options = { desc = "Find buffers"; }; }
        { mode = "n"; key = "<leader>gs"; action = ":lua require('telescope.builtin').git_status()<CR>"; options = { desc = "Git status"; }; }
        { mode = "n"; key = "<leader>q"; action = ":q<CR>"; options = { desc = "Close buffer"; }; }
        { mode = "n"; key = "<leader>w"; action = ":w<CR>"; options = { desc = "Save file"; }; }
        { mode = "i"; key = "<C-Space>"; action = ":lua require('cmp').complete()<CR>"; options = { desc = "Trigger completion"; }; }
        { mode = "i"; key = "<C-e>"; action = ":lua require('cmp').abort()<CR>"; options = { desc = "Abort completion"; }; }
        { mode = "i"; key = "<CR>"; action = ":lua require('cmp').confirm({ select = true })<CR>"; options = { desc = "Confirm selection"; }; }
        { mode = "i"; key = "<C-n>"; action = ":lua require('cmp').select_next_item()<CR>"; options = { desc = "Next item"; }; }
        { mode = "i"; key = "<C-p>"; action = ":lua require('cmp').select_prev_item()<CR>"; options = { desc = "Previous item"; }; }
      ];

      settings = {
        relativenumber = true;
        number = true;
        mouse = "a";
        clipboard = "unnamedplus";
        splitbelow = true;
        splitright = true;
        termguicolors = true;
        hidden = true;
        completeopt = "menuone,noselect";
        background = "dark";
        scrolloff = 8;
        updatetime = 300;
        wildmenu = true;
        ignorecase = true;
        smartcase = true;
        incsearch = true;
       };

       colorschemes.catppuccin = {
         enable = true;
       };

       lsp = {
         enable = true;
       };

       treesitter = {
        enable = true;
        nix = {
          enable = true;
          package = pkgs.tree-sitter-nix;
        };
        rust = {
          enable = true;
          package = pkgs.tree-sitter-rust;
        };
        lua = {
          enable = true;
          package = pkgs.tree-sitter-lua;
        };
        ensureInstalled = [ "nix" "rust" "lua" "vim" "vimdoc" "bash" "json" "toml" ];
        indent = true;
      };

      gitsigns = {
        enable = true;
        settings = {
          current_line_blame = true;
          trouble = true;
        };
      };

      telescope = {
        enable = true;
      };

      grugFar = {
        enable = true;
      };

      plugins.fidget = {
        enable = true;
        settings.progress = {
          suppress_on_insert = true;
          ignore_done_already = true;
          poll_rate = 1;
        };
      };

      extraConfigLua = ''
        vim.api.nvim_create_autocmd("VimEnter", {
          pattern = "*",
          once = true,
          callback = function()
            vim.defer_fn(function()
              local cmp_lsp = require("cmp_nvim_lsp")
              local capabilities = vim.lsp.protocol.make_client_capabilities()
              capabilities = cmp_lsp.default_capabilities(capabilities)

              vim.lsp.config("nixd", { capabilities = capabilities })
              vim.lsp.config("rust_analyzer", { capabilities = capabilities })
              vim.lsp.config("lua_ls", { capabilities = capabilities })
              vim.lsp.enable("nixd")
              vim.lsp.enable("rust_analyzer")
              vim.lsp.enable("lua_ls")

              require("crates").setup()

              local cmp = require("cmp")

              cmp.setup({
                snippet = {
                  expand = function(args)
                    vim.fn["vsnip#anonymous"](args.body)
                  end,
                },
                window = {
                  completion = cmp.config.window.bordered(),
                  documentation = cmp.config.window.bordered(),
                },
                mapping = cmp.mapping.preset.insert({
                  ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                  ["<C-f>"] = cmp.mapping.scroll_docs(4),
                  ["<C-Space>"] = cmp.mapping.complete(),
                  ["<C-e>"] = cmp.mapping.abort(),
                  ["<CR>"] = cmp.mapping.confirm({ select = true }),
                  ["<Tab>"] = cmp.mapping.select_next_item(),
                  ["<S-Tab>"] = cmp.mapping.select_prev_item(),
                }),
                sources = cmp.config.sources({
                  { name = "nvim_lsp" },
                  { name = "nvim_lsp_signature_help" },
                  { name = "vsnip" },
                }, {
                  { name = "buffer" },
                  { name = "path" },
                }),
                autocomplete = true,
              })

              cmp.setup.cmdline({ "/", "?" }, {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                  { name = "buffer" }
                }
              })

              cmp.setup.cmdline(":", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                  { name = "path" }
                }, {
                  { name = "cmdline" }
                }),
                matching = { disallow_symbol_nonprefix_matching = false }
              })
            end, 500)
          end,
        })
      '';

      cmp = {
        enable = true;
      };
    };
  };

  systemd.user.services.lorri = lib.mkIf pkgs.stdenv.isLinux {
    description = "Lorri Nix shell env daemon";
    wantedBy = [ "default.target" ];
    after = [ "nix-daemon.socket" ];
    serviceConfig = {
      ExecStart = "${pkgs.lorri}/bin/lorri daemon";
      Restart = "on-failure";
    };
  };
}
