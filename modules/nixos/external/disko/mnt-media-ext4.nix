args@{ ... }:
let
  mountpoint = if args.mountpoint == null then "/mnt/media" else args.mountpoint;
in
{
  inherit (args) device destroy;
  type = "disk";
  content = {
    type = "gpt";
    partitions = {
      media = {
        size = "100%";
        content = {
          type = "filesystem";
          format = "ext4";
          inherit mountpoint;
        };
      };
    };
  };
}
