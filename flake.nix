{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: 
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    # Custom packages
    packages.${system} = {
      endpoint-verification = pkgs.callPackage ./packages/endpoint-verification.nix {};
    };

    nixosConfigurations.skippy = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs self;};
      modules = [
        ./hosts/Skippy/config.nix
        inputs.home-manager.nixosModules.default
        inputs.sops-nix.nixosModules.sops 
      ];
    };
  };
}
