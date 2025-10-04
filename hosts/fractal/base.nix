{ ... }:
{
  imports = [
    ../../modules/base
    ./configs/base
  ];

  base = {
    boot = {
      enable = true;
      loader = "limine";
      kernel = "latest";
    };
  };
}
