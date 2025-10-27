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
      gemini = {
        ignore_system_version = false;
      };
    };
    show_edit_predictions = false;
    # Languages
    languages = {
      Python = {
        language_servers = [
          "ruff"
          "basedpyright"
          "!pyright"
        ];
        format_on_save = "on";
        formatter = [
          { code_action = "source.fixAll.ruff"; }
          { code_action = "source.organizeImports.ruff"; }
          { language_server.name = "ruff"; }
        ];
      };
      Nix = {
        language_servers = [
          "nixd"
          "!nil"
        ];
        format_on_save = "on";
      };
      "Shell Script" = {
        format_on_save = "on";
        formatter = {
          external = {
            command = "shfmt";
            arguments = [
              "--filename"
              "{buffer_path}"
              "--indent"
              "2"
            ];
          };
        };
      };
    };
    # Language-servers
    lsp = {
      basedpyright = {
        settings = {
          "basedpyright.analysis" = {
            diagnosticSeverityOverrides = {
              reportAny = false;
              reportExplicitAny = false;
            };
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
        ruff
        nixd
        caddy
        shfmt
        nixfmt
        gemini-cli
        shellcheck
        basedpyright
        cfg.font.package
      ];
      extensions = [
        "ini"
        "nix"
        "toml"
        "fish"
        "latex"
        "codebook"
        "caddyfile"
        "git-firefly"
      ];
    };

    home.sessionVariables = {
      SOPS_EDITOR = "zeditor --wait";
    };
  };
}
