{ ... }:
{
  # Ensure always using the same DP numeration
  boot.kernelParams = [
    "video=DP-1:e"
    "video=DP-2:e"
    # "video=DP-3:e"
  ];
}
