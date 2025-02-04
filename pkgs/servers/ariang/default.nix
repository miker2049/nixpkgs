{ lib ? pkgs.lib
, stdenv
, pkgs
, fetchFromGitHub
, nodejs ? pkgs.nodejs_18
}:

stdenv.mkDerivation rec {
  pname = "ariang";
  version = "1.3.4";

  src = fetchFromGitHub {
    owner = "mayswind";
    repo = "AriaNg";
    rev = version;
    hash = "sha256-jprx1JIh+Q0Cv2NkLj9dMnGr+nR/0T08N02gXGknC1Q=";
  };

  buildPhase =
    let
      nodePackages = import ./node-composition.nix {
        inherit pkgs nodejs;
        inherit (stdenv.hostPlatform) system;
      };
      nodeDependencies = (nodePackages.shell.override (old: {
        # access to path '/nix/store/...-source' is forbidden in restricted mode
        src = src;
        # Error: Cannot find module '/nix/store/...-node-dependencies
        dontNpmInstall = true;
      })).nodeDependencies;
    in
    ''
      runHook preBuild

      ln -s ${nodeDependencies}/lib/node_modules ./node_modules
      ${nodeDependencies}/bin/gulp clean build

      runHook postBuild
    '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share
    cp -r dist $out/share/ariang

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "a modern web frontend making aria2 easier to use";
    homepage = "http://ariang.mayswind.net/";
    license = licenses.mit;
    maintainers = with maintainers; [ stunkymonkey ];
    platforms = platforms.unix;
  };
}
