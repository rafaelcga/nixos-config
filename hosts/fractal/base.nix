{...}:
{
  imports = [
    ../../modules/base
  ]

  base = {
    boot = {
      enable = true;
      loader = "limine";
      kernel = "latest";
    };
  };
}
