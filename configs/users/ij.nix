{ pkgs, lib, user, ... }:

{
  imports = [
    (import ./common.nix {})
    (import ../fish {})
    (import ../tmux {})
    (import ../git {})
    (import ../bash {})
    (import ../direnv {})
    (import ../lazygit {})
    (import ../starship {})
    (import ../htop {})
    (import ../zoxide {})
    (import ../delta {})
    (import ../procs {})
  ];

  home = {
    stateVersion = "22.05";
    username = user.username;
    homeDirectory = "/home/${user.username}";
  };

  home.activation.importGpgKey = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    gpg --import "${../../secrets/ij-public-key.gpg}" 2>/dev/null || true
  '';

  home.activation.tldrUpdate = lib.hm.dag.entryAfter [ "importGpgKey" ] ''
    ${pkgs.tealdeer}/bin/tldr --update 2>/dev/null || true
  '';

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };

  programs.password-store.enable = true;

  programs.fish.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      nvim-cmp
      cmp-nvim-lsp
      cmp-nvim-lsp-signature-help
      cmp-buffer
      cmp-path
      cmp-cmdline
      cmp-vsnip
      vim-vsnip
      nvim-lspconfig
      fidget-nvim
      catppuccin-nvim
      (nvim-treesitter.withPlugins (p: [
        p.nix p.lua p.vim p.vimdoc p.bash p.json p.toml p.markdown p.python p.yaml
      ]))
      nvim-treesitter-textobjects
      gitsigns-nvim
      telescope-nvim
      plenary-nvim
      grug-far-nvim
      fzf-vim
      fzfWrapper
    ];

    extraLuaConfig = ''
      vim.opt.relativenumber = true
      vim.opt.number = true
      vim.opt.mouse = "a"
      vim.opt.clipboard = "unnamedplus"
      vim.opt.splitbelow = true
      vim.opt.splitright = true
      vim.opt.termguicolors = true
      vim.opt.hidden = true
      vim.opt.completeopt = "menuone,noselect"
      vim.opt.background = "dark"
      vim.opt.scrolloff = 8
      vim.opt.updatetime = 300
      vim.opt.wildmenu = true
      vim.opt.ignorecase = true
      vim.opt.smartcase = true
      vim.opt.incsearch = true

      require("catppuccin").setup({
        flavour = "mocha",
      })
      vim.cmd.colorscheme "catppuccin"

      require("gitsigns").setup({
        current_line_blame = true,
      })

      require("telescope").setup()
      require("grug-far").setup()

      require("fidget").setup({
        progress = {
          suppress_on_insert = true,
          ignore_done_already = true,
          poll_rate = 1,
        },
      })

      vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
      vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Show references" })
      vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Show hover" })
      vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Show diagnostic" })
      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
      vim.keymap.set("n", "<leader>ff", require("telescope.builtin").find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", require("telescope.builtin").live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", require("telescope.builtin").buffers, { desc = "Find buffers" })
      vim.keymap.set("n", "<leader>gs", require("telescope.builtin").git_status, { desc = "Git status" })
      vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "Close buffer" })
      vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })

      local cmp_lsp = require("cmp_nvim_lsp")
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = cmp_lsp.default_capabilities(capabilities)

      local lspconfig = require("lspconfig")
      lspconfig.nixd.setup({ capabilities = capabilities })
      lspconfig.lua_ls.setup({ capabilities = capabilities })
      lspconfig.marksman.setup({ capabilities = capabilities })

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
    '';
  };
}
