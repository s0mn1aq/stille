{
  description = "field";

  #|-------|
  #| input |
  #|-------|
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  #|--------|
  #| output |
  #|--------|
  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.field = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        home-manager.nixosModules.home-manager
        ./configuration.nix
      ];
    };
  };
}
