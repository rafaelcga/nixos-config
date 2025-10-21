inputs:
inputs.nixpkgs.lib.extend (
  self: _: {
    local = import ./. {
      inherit inputs;
      lib = self;
    };
  }
)
