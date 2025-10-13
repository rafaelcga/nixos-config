{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home-manager.zed-editor;
in
{
  options.modules.home-manager.zed-editor = {
    enable = lib.mkEnableOption "Zed Editor configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;

      ## EXTENSIONS AND PACKAGES
      extraPackages = with pkgs; [
        ruff
        basedpyright
        nil
        nixfmt
        shfmt
        shellcheck
        nerd-fonts.jetbrains-mono
      ];
      extensions = [
        "ini"
        "nix"
        "ruff"
        "toml"
        "fish"
        "latex"
        "codebook"
        "caddyfile"
        "git-firefly"
        "basedpyright"
      ];

      ## SETTINGS JSON
      userSettings = {
        disable_ai = true;
        # UI settings
        ui_font_family = "JetBrainsMono Nerd Font";
        ui_font_size = 18;
        buffer_font_family = "JetBrainsMono Nerd Font";
        buffer_font_size = 16;
        preferred_line_length = 80;
        wrap_guides = [ 80 ];
        terminal.dock = "right";
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
              {
                code_actions = {
                  "source.organizeImports.ruff" = true;
                  "source.fixAll.ruff" = true;
                };
              }
              {
                language_server.name = "ruff";
              }
            ];
          };
          Nix = {
            language_servers = [
              "nil"
              "!nixd"
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
          nil = {
            settings = {
              formatting = {
                command = [ "nixfmt" ];
              };
              diagnostics = {
                ignored = [ "unused_rec" ];
                excludedFiles = [ ];
              };
              nix = {
                binary = "nix";
                maxMemoryMB = 2560;
                flake = {
                  autoArchive = true;
                  autoEvalInputs = true;
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
    };
  };
}
