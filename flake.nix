{
  description = "NixOS configuration for host field";

#|-------|
#| input |
#|-------|
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

#|--------|
#| output |
#|--------|
  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.field = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
      ];
    };
  };
}
