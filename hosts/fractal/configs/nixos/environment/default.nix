{ ... }:
{
  environment.sessionVariables = {
    GSK_RENDERER = "gl"; # fixes graphical flatpak bug under Wayland
    GDK_SCALE = "1.25"; # sets XWayland render scale
    __GL_SHADER_DISK_CACHE_SIZE = "12000000000"; # NVIDIA GPU cache
    MESA_SHADER_CACHE_MAX_SIZE = "12G"; # AMD GPU cache
  };
}
