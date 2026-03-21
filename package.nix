{ pkgs }:

pkgs.buildNpmPackage rec {
  pname = "holesail";
  version = "2.4.1";

  src = pkgs.fetchFromGitHub {
    owner = "holesail";
    repo = "holesail";
    rev = "refs/tags/${version}";
    hash = "sha256-xIs49HoPV8j0yDPn29WhgS/mkIAEJLRiNNEmKChq0X4=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  nodejs = pkgs.nodejs_22;
  npmDepsHash = "sha256-xJdks1xLFKXYyAze7CH+cNvvpdPuCuoQ1YsEEkEuSi8=";
  npmPackFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;

  meta = {
    description = "P2P tunneling with holesail";
    homepage = "https://holesail.io";
    license = pkgs.lib.licenses.agpl3Only;
    mainProgram = "holesail";
    platforms = pkgs.lib.platforms.linux ++ pkgs.lib.platforms.darwin;
  };
}
