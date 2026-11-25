{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home-manager.zed-editor;

  userSettings = {
    # UI settings
    ui_font_family = cfg.font.family;
    ui_font_size = 18;
    buffer_font_family = cfg.font.family;
    buffer_font_size = 16;
    preferred_line_length = 80;
    wrap_guides = [ 80 ];
    terminal.dock = "right";
    # AI
    agent_servers = {
      # Claude Agent (Claude Code over ACP), installed from the ACP registry
      claude-acp = {
        type = "registry";
      };
    };
    show_edit_predictions = false;
    # Languages
    languages = {
      Python = {
        language_servers = [
          "ty"
          "ruff"
          "!basedpyright"
        ];
        code_actions_on_format = {
          "source.organizeImports.ruff" = true;
          "source.fixAll.ruff" = true;
        };
        formatter = {
          language_server = {
            name = "ruff";
          };
        };
      };
      Nix = {
        language_servers = [
          "nixd"
          "!nil"
        ];
      };
      "Shell Script" = {
        formatter = {
          external = {
            command = "shfmt";
            # Google style shell formatting
            arguments = [
              "--filename"
              "{buffer_path}"
              "--indent"
              "2"
              "--case-indent"
              "--binary-next-line"
            ];
          };
        };
      };
      Caddyfile = {
        formatter = {
          external = {
            command = "caddy";
            arguments = [
              "fmt"
              "-c"
              "-"
            ];
          };
        };
      };
    };
    # Language-servers
    lsp = {
      nixd = {
        settings = {
          diagnostic = {
            suppress = [ "sema-primop-overridden" ];
          };
        };
      };
      texlab = {
        settings = {
          texlab = {
            build = {
              onSave = true;
              forwardSearchAfter = true;
            };
          };
        };
      };
    };
    # Other settings
    file_types = {
      ini = [
        "container"
        "pod"
        "build"
        "volume"
        "service"
        "timer"
        "network"
      ];
    };
  };
in
{
  options.modules.home-manager.zed-editor = {
    enable = lib.mkEnableOption "Enable Zed Editor";

    font = {
      family = lib.mkOption {
        type = lib.types.str;
        default = "JetBrainsMono Nerd Font";
        description = "Desktop environment font";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.nerd-fonts.jetbrains-mono;
        description = "Desktop environment font's package";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zed-editor = {
      inherit userSettings;
      enable = true;
      package = pkgs.zed-editor-fhs; # Use FHS for dynamic libraries

      ## EXTENSIONS AND PACKAGES
      extraPackages = with pkgs; [
        ty
        ruff
        nixd
        caddy
        shfmt
        nixfmt
        shellcheck
        cfg.font.package
      ];
      extensions = [
        "ini"
        "nix"
        "toml"
        "fish"
        "latex"
        "caddyfile"
        "git-firefly"
      ];
    };

    home = {
      sessionVariables = {
        SOPS_EDITOR = "zeditor --wait";
      };

      # User-level instructions for the Claude Agent (`claude-acp` above). Zed
      # has no setting for them, but Claude Code loads this file in every session.
      file.".claude/CLAUDE.md".text = ''
        # Environment

        - There is no system `python`/`python3`. Use `uv` instead:
          - scripts: `uv run script.py` (add deps with `uv run --with <pkg> ...`)
          - inline snippets: `uv run python -c '...'`
          - Python CLI tools: `uvx <tool>`
        - This is NixOS: run other missing tools with
          `nix shell nixpkgs#<pkg> -c <cmd>` or `nix run nixpkgs#<pkg>`.
      '';
    };
  };
}
