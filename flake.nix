{
  description = "A P2P based node package to expose your local ports on the Holepunch protocol";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages = rec {
          holesail = pkgs.buildNpmPackage rec {
            pname = "holesail";
            version = "1.7.3";

            src = pkgs.fetchFromGitHub {
              owner = "holesail";
              repo = pname;
              rev = "8b96ee980324b2bd04956a76767987924f7daa95";
              hash = "sha256-7YTBwjU0xzoDqlRqfdQZrJRvSXTtT8rpA1zRdLSdFoU=";
            };

            npmDepsHash = "sha256-aos1WOsVsgZG6h0g242/mz5yiN/7V+G8to8IyaKldFI=";

            npmPackFlags = [ "--ignore-scripts" ];

            dontNpmBuild = true;
            nodejs = pkgs.nodejs_22;

            meta = with pkgs.lib; {
              description = "Holesail let's you instantly share any application running on a specific port from your local computer.";
              homepage = "https://holesail.io";
              license = licenses.mit;
              maintainers = with maintainers; [ supersuryaansh ];
            };
          };

          default = holesail;
        };

        devShell = pkgs.mkShell {
          buildInputs = [
            self.packages.${system}.default
          ];
        };
      }
    );
}
