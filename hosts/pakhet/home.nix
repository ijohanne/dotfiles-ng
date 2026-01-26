{ config, pkgs, lib, user, inputs, ... }:

{

  home = {
    stateVersion = "22.05";
    username = user.username;
    homeDirectory = "/home/${user.username}";

    packages = with pkgs; [
      zip
      unzip
      tmux
      sqlite
      ripgrep
      openssl
      fzf
      difftastic
      nushell
      atuin
      python3
      jq
      yq
      wget
      shellcheck
      gnupg
      starship
      tealdeer
      procs
      doggo
      # Dev packages
      nixd
      lua-language-server
      marksman
      bat
      bottom
      dust
      eza
      fd
      gping
      httpie
    ];
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

  programs = {
    bash = {
      enable = true;
      initExtra = ''
        export EDITOR=nvim
        export VISUAL=nvim
        export PAGER=less
      '';
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    fish = {
      enable = true;
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
        export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket 2>/dev/null || echo "$HOME/.gnupg/S.gpg-agent.ssh")"
        abbr -a tldr tealdeer
        abbr -a ps procs
        function dog
            ${pkgs.doggo}/bin/doggo $argv
        end
        function dig
            dog $argv
        end
        function deploy-pakhet
            sudo nix-shell -I nixpkgs=channel:nixos-unstable -p nix --run 'nixos-rebuild switch --flake github:ijohanne/dotfiles-ng#pakhet --option sandbox relaxed --refresh'
        end
        ${pkgs.direnv}/bin/direnv hook fish | source
      '';
    };

    starship = {
      enable = true;
      enableFishIntegration = false;
      settings = {};
    };

    htop = {
      enable = true;
      settings.color_scheme = 6;
    };

    home-manager = {
      enable = true;
    };

    password-store = {
      enable = true;
    };

    zoxide = {
      enable = true;
      options = [ "--cmd cd" ];
    };

    lazygit = {
      enable = true;
      settings = {
        gui.theme = {
          activeBorderColor = [ "#89b4fa" "bold" ];
          inactiveBorderColor = [ "#a6adc8" ];
          optionsTextColor = [ "#89b4fa" ];
          selectedLineBgColor = [ "#313244" ];
          cherryPickedCommitBgColor = [ "#45475a" ];
          cherryPickedCommitFgColor = [ "#89b4fa" ];
          unstagedChangesColor = [ "#f38ba8" ];
          defaultFgColor = [ "#cdd6f4" ];
          searchingActiveBorderColor = [ "#f9e2af" ];
        };
        gui.authorColors = {
          "dependabot[bot]" = "#a6adc8";
        };
        gui.nerdFontsVersion = "3";
        gui.showFileIcons = true;
      };
    };

    git = {
      enable = true;
      userName = user.name;
      userEmail = user.email;
      delta.enable = true;
      extraConfig = {
        init.defaultBranch = "master";
        pull.rebase = true;
        pull.ff = "only";
        status.submodule = "summary";
        commit.gpgsign = true;
        merge.conflictstyle = "diff3";
        diff.color = "auto";
        diff.mnemonicPrefix = true;
        diff.relativeDate = true;
      };
      lfs.enable = true;
    };

    tmux = {
      enable = true;
      keyMode = "vi";
      shell = "${pkgs.fish}/bin/fish";
      mouse = true;
      baseIndex = 1;
      escapeTime = 10;

      plugins = with pkgs.tmuxPlugins; [
        catppuccin
        sensible
        vim-tmux-navigator
        yank
        resurrect
        battery
        cpu
        prefix-highlight
      ];

      extraConfig = ''
        unbind C-b
        set -g prefix C-a
        bind C-a send-prefix

        bind r source-file ~/.tmux.conf \; display "Config reloaded"

        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        bind e previous-window
        bind f next-window
        bind E swap-window -t -1
        bind F swap-window -t +1

        bind = split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        unbind '"'
        unbind %

        bind a last-window

        set -g status-interval 5
        set -g status-left-length 100
        set -g status-right-length 100
        set -g status-left ""
        set -g status-right "#{E:@catppuccin_status_application}"
        set -agF status-right "#{E:@catppuccin_status_cpu}"
        set -ag status-right "#{E:@catppuccin_status_session}"
        set -ag status-right "#{E:@catppuccin_status_uptime}"
        set -agF status-right "#{E:@catppuccin_status_battery}"

        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -selection clipboard"
        bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xclip -selection clipboard"

        set -g set-titles on
        set -g set-titles-string "#S:#I:#W - #T"

        setw -g monitor-activity on
        set -g visual-activity on

        set -g @catppuccin_flavor "mocha"
        set -g @catppuccin_window_status_style "rounded"
        set -g @catppuccin_pane_border_status "off"
        set -g @catppuccin_pane_active_border_style "fg=#{thm_peach}"
        set -g @catppuccin_pane_border_style "fg=#{thm_surface2}"

        set -g @resurrect-dir "~/.tmux/resurrect"
        set -g @resurrect-restore-environment "on"

        set -g @prefix_highlight_show_copy_mode "on"
        set -g @prefix_highlight_copy_mode_attr "fg=white,bg=blue"

        set -g pane-base-index 1
      '';
    };

    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      plugins = with pkgs.vimPlugins; [
        # Completion
        nvim-cmp
        cmp-nvim-lsp
        cmp-nvim-lsp-signature-help
        cmp-buffer
        cmp-path
        cmp-cmdline
        cmp-vsnip
        vim-vsnip

        # LSP
        nvim-lspconfig
        fidget-nvim

        # Theme
        catppuccin-nvim

        # Treesitter
        (nvim-treesitter.withPlugins (p: [
          p.nix p.lua p.vim p.vimdoc p.bash p.json p.toml p.markdown p.python p.yaml
        ]))
        nvim-treesitter-textobjects

        # Git
        gitsigns-nvim

        # Telescope
        telescope-nvim
        plenary-nvim

        # Search/replace
        grug-far-nvim

        # FZF
        fzf-vim
        fzfWrapper
      ];

      extraLuaConfig = ''
        -- Basic settings
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

        -- Catppuccin theme
        require("catppuccin").setup({
          flavour = "mocha",
        })
        vim.cmd.colorscheme "catppuccin"

        -- Gitsigns
        require("gitsigns").setup({
          current_line_blame = true,
        })

        -- Telescope
        require("telescope").setup()

        -- Grug-far
        require("grug-far").setup()

        -- Fidget (LSP progress)
        require("fidget").setup({
          progress = {
            suppress_on_insert = true,
            ignore_done_already = true,
            poll_rate = 1,
          },
        })

        -- Keymaps
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

        -- LSP setup
        local cmp_lsp = require("cmp_nvim_lsp")
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities = cmp_lsp.default_capabilities(capabilities)

        local lspconfig = require("lspconfig")
        lspconfig.nixd.setup({ capabilities = capabilities })
        lspconfig.lua_ls.setup({ capabilities = capabilities })
        lspconfig.marksman.setup({ capabilities = capabilities })

        -- nvim-cmp setup
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
  };
}
