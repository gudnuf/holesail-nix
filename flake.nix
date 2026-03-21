{
  description = "Holesail P2P tunneling for Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      eachSystem = nixpkgs.lib.genAttrs systems;
    in {
      packages = eachSystem (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        holesail = import ./package.nix { inherit pkgs; };
        default = self.packages.${system}.holesail;
      });

      devShells = eachSystem (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          packages = [ self.packages.${system}.holesail ];
        };
      });
    };
}
