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
              owner = "gudnuf";
              repo = pname;
              rev = "fix-for-flake";
              hash = "sha256-lbL/EGZ8TPVvmXn+lyBj3wEh7lOCLs7hpRiC9wv2g0Q=";
            };

            npmDepsHash = "sha256-lZEpP14sN62LOv85VsGEIWAHXQuRt6lfhbp/iGpffX4=";

            npmPackFlags = [ "--ignore-scripts" ];

            dontNpmBuild = true;
            nodejs = pkgs.nodejs_22;

            postInstall = ''
              substituteInPlace $out/lib/node_modules/holesail/manager.js \
                --replace "path.resolve(__dirname, './index.js')" \
                          "'$out/lib/node_modules/holesail/index.js'"
            '';

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
