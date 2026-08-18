{
  description = "die stille";

  #|-------|
  #| input |
  #|-------|
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix.url = "github:danth/stylix";
  };

  #|--------|
  #| output |
  #|--------|
  outputs = { self, nixpkgs, home-manager, stylix, ... }@inputs: {
    nixosConfigurations.stille = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        stylix.nixosModules.stylix
        home-manager.nixosModules.home-manager
        ./configuration.nix
      ];
    };
  };
}
