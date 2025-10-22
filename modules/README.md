Module template:

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.modules.group.name;
in
{
  imports = [ ];

  options.modules.group.name = {
    enable = lib.mkEnableOption "Toggle module";
    optionName = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "A bool option";
    };
  };

  config = lib.mkIf cfg.enable { };
}
```
